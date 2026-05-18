#include "windows_system_audio_analyzer.h"

#include <algorithm>
#include <chrono>
#include <cmath>

#include <godot_cpp/core/class_db.hpp>

#ifdef _WIN32
#include <audioclient.h>
#include <avrt.h>
#include <mmdeviceapi.h>
#include <mmreg.h>
#include <wrl/client.h>
#endif

namespace godot {

namespace {

constexpr double PULSE_THRESHOLD = 0.025;
constexpr double ONSET_THRESHOLD = 0.014;
constexpr double LEVEL_GAIN = 3.8;
constexpr double ONSET_GAIN = 13.0;
constexpr double ATTACK = 24.0;
constexpr double DECAY = 5.2;

double pulse_target_for_energy(double p_energy, double p_previous_energy) {
	const double safe_energy = std::max(p_energy, 0.0);
	const double safe_previous = std::max(p_previous_energy, 0.0);
	const double level_pulse = std::max(safe_energy - PULSE_THRESHOLD, 0.0) * LEVEL_GAIN;
	const double onset_pulse = std::max((safe_energy - safe_previous) - ONSET_THRESHOLD, 0.0) * ONSET_GAIN;
	return std::clamp(std::max(level_pulse, onset_pulse), 0.0, 1.0);
}

double smooth_pulse(double p_current, double p_target, double p_delta) {
	const double rate = p_target > p_current ? ATTACK : DECAY;
	const double weight = 1.0 - std::exp(-rate * std::max(p_delta, 0.0));
	return std::clamp(p_current + (std::clamp(p_target, 0.0, 1.0) - p_current) * std::clamp(weight, 0.0, 1.0), 0.0, 1.0);
}

#ifdef _WIN32

constexpr REFERENCE_TIME BUFFER_DURATION_100NS = 10000000;

bool is_float_format(const WAVEFORMATEX *p_format) {
	if (p_format == nullptr) {
		return false;
	}
	if (p_format->wFormatTag == WAVE_FORMAT_IEEE_FLOAT) {
		return true;
	}
	if (p_format->wFormatTag == WAVE_FORMAT_EXTENSIBLE) {
		const WAVEFORMATEXTENSIBLE *extensible = reinterpret_cast<const WAVEFORMATEXTENSIBLE *>(p_format);
		return extensible->SubFormat == KSDATAFORMAT_SUBTYPE_IEEE_FLOAT;
	}
	return false;
}

double sample_as_float(const BYTE *p_data, UINT32 p_sample_index, const WAVEFORMATEX *p_format) {
	if (p_data == nullptr || p_format == nullptr) {
		return 0.0;
	}

	const WORD bits = p_format->wBitsPerSample;
	if (is_float_format(p_format) && bits == 32) {
		const float *samples = reinterpret_cast<const float *>(p_data);
		return static_cast<double>(samples[p_sample_index]);
	}

	const BYTE *sample = p_data + static_cast<size_t>(p_sample_index) * bits / 8;
	if (bits == 16) {
		const int16_t value = *reinterpret_cast<const int16_t *>(sample);
		return static_cast<double>(value) / 32768.0;
	}
	if (bits == 24) {
		int32_t value = (static_cast<int32_t>(sample[0]) | (static_cast<int32_t>(sample[1]) << 8) | (static_cast<int32_t>(sample[2]) << 16));
		if (value & 0x00800000) {
			value |= 0xFF000000;
		}
		return static_cast<double>(value) / 8388608.0;
	}
	if (bits == 32) {
		const int32_t value = *reinterpret_cast<const int32_t *>(sample);
		return static_cast<double>(value) / 2147483648.0;
	}

	return 0.0;
}

double rms_energy(const BYTE *p_data, UINT32 p_frames, DWORD p_flags, const WAVEFORMATEX *p_format) {
	if ((p_flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0 || p_data == nullptr || p_format == nullptr || p_frames == 0) {
		return 0.0;
	}

	const UINT32 channels = std::max<UINT32>(p_format->nChannels, 1);
	const UINT64 sample_count = static_cast<UINT64>(p_frames) * channels;
	double sum = 0.0;
	for (UINT64 i = 0; i < sample_count; ++i) {
		const double sample = std::clamp(sample_as_float(p_data, static_cast<UINT32>(i), p_format), -1.0, 1.0);
		sum += sample * sample;
	}
	return std::sqrt(sum / static_cast<double>(sample_count));
}

void estimate_time_bands(const BYTE *p_data, UINT32 p_frames, DWORD p_flags, const WAVEFORMATEX *p_format, double &r_bass, double &r_mid, double &r_treble) {
	r_bass = 0.0;
	r_mid = 0.0;
	r_treble = 0.0;
	if ((p_flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0 || p_data == nullptr || p_format == nullptr || p_frames == 0) {
		return;
	}

	const UINT32 channels = std::max<UINT32>(p_format->nChannels, 1);
	double low_sum = 0.0;
	double mid_sum = 0.0;
	double high_sum = 0.0;
	double previous = 0.0;
	double previous_delta = 0.0;
	UINT32 count = 0;
	for (UINT32 frame = 0; frame < p_frames; ++frame) {
		double mono = 0.0;
		for (UINT32 channel = 0; channel < channels; ++channel) {
			const UINT32 sample_index = frame * channels + channel;
			mono += std::clamp(sample_as_float(p_data, sample_index, p_format), -1.0, 1.0);
		}
		mono /= static_cast<double>(channels);
		const double delta = mono - previous;
		const double second_delta = delta - previous_delta;
		low_sum += mono * mono;
		mid_sum += delta * delta;
		high_sum += second_delta * second_delta;
		previous = mono;
		previous_delta = delta;
		++count;
	}

	const double safe_count = static_cast<double>(std::max<UINT32>(count, 1));
	r_bass = std::clamp(std::sqrt(low_sum / safe_count) * 2.4, 0.0, 1.0);
	r_mid = std::clamp(std::sqrt(mid_sum / safe_count) * 7.0, 0.0, 1.0);
	r_treble = std::clamp(std::sqrt(high_sum / safe_count) * 10.0, 0.0, 1.0);
}
#endif

} // namespace

WindowsSystemAudioAnalyzer::WindowsSystemAudioAnalyzer() :
		running(false),
		available(false),
		energy(0.0),
		pulse(0.0),
		bass(0.0),
		mid(0.0),
		treble(0.0) {
}

WindowsSystemAudioAnalyzer::~WindowsSystemAudioAnalyzer() {
	stop();
}

void WindowsSystemAudioAnalyzer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("start"), &WindowsSystemAudioAnalyzer::start);
	ClassDB::bind_method(D_METHOD("stop"), &WindowsSystemAudioAnalyzer::stop);
	ClassDB::bind_method(D_METHOD("is_available"), &WindowsSystemAudioAnalyzer::is_available);
	ClassDB::bind_method(D_METHOD("get_energy"), &WindowsSystemAudioAnalyzer::get_energy);
	ClassDB::bind_method(D_METHOD("get_pulse"), &WindowsSystemAudioAnalyzer::get_pulse);
	ClassDB::bind_method(D_METHOD("get_bass"), &WindowsSystemAudioAnalyzer::get_bass);
	ClassDB::bind_method(D_METHOD("get_mid"), &WindowsSystemAudioAnalyzer::get_mid);
	ClassDB::bind_method(D_METHOD("get_treble"), &WindowsSystemAudioAnalyzer::get_treble);
}

bool WindowsSystemAudioAnalyzer::start() {
	if (running.load()) {
		return true;
	}

	running.store(true);
	available.store(false);
	energy.store(0.0);
	pulse.store(0.0);
	bass.store(0.0);
	mid.store(0.0);
	treble.store(0.0);
	capture_thread = std::thread(&WindowsSystemAudioAnalyzer::_capture_loop, this);
	return true;
}

void WindowsSystemAudioAnalyzer::stop() {
	running.store(false);
	if (capture_thread.joinable()) {
		capture_thread.join();
	}
	available.store(false);
	energy.store(0.0);
	pulse.store(0.0);
	bass.store(0.0);
	mid.store(0.0);
	treble.store(0.0);
}

bool WindowsSystemAudioAnalyzer::is_available() const {
	return available.load();
}

double WindowsSystemAudioAnalyzer::get_energy() const {
	return energy.load();
}

double WindowsSystemAudioAnalyzer::get_pulse() const {
	return pulse.load();
}

double WindowsSystemAudioAnalyzer::get_bass() const {
	return bass.load();
}

double WindowsSystemAudioAnalyzer::get_mid() const {
	return mid.load();
}

double WindowsSystemAudioAnalyzer::get_treble() const {
	return treble.load();
}

void WindowsSystemAudioAnalyzer::_set_unavailable() {
	available.store(false);
	energy.store(0.0);
	pulse.store(0.0);
	bass.store(0.0);
	mid.store(0.0);
	treble.store(0.0);
}

void WindowsSystemAudioAnalyzer::_capture_loop() {
#ifndef _WIN32
	_set_unavailable();
	running.store(false);
#else
	HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
	const bool co_initialized = SUCCEEDED(hr);
	if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
		_set_unavailable();
		running.store(false);
		return;
	}

	DWORD task_index = 0;
	HANDLE mmcss_handle = AvSetMmThreadCharacteristicsW(L"Audio", &task_index);

	Microsoft::WRL::ComPtr<IMMDeviceEnumerator> enumerator;
	Microsoft::WRL::ComPtr<IMMDevice> endpoint;
	Microsoft::WRL::ComPtr<IAudioClient> audio_client;
	Microsoft::WRL::ComPtr<IAudioCaptureClient> capture_client;
	WAVEFORMATEX *mix_format = nullptr;

	hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, IID_PPV_ARGS(&enumerator));
	if (SUCCEEDED(hr)) {
		hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &endpoint);
	}
	if (SUCCEEDED(hr)) {
		hr = endpoint->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, reinterpret_cast<void **>(audio_client.GetAddressOf()));
	}
	if (SUCCEEDED(hr)) {
		hr = audio_client->GetMixFormat(&mix_format);
	}
	if (SUCCEEDED(hr)) {
		hr = audio_client->Initialize(AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_LOOPBACK, BUFFER_DURATION_100NS, 0, mix_format, nullptr);
	}
	if (SUCCEEDED(hr)) {
		hr = audio_client->GetService(IID_PPV_ARGS(&capture_client));
	}
	if (SUCCEEDED(hr)) {
		hr = audio_client->Start();
	}
	if (FAILED(hr)) {
		if (mix_format != nullptr) {
			CoTaskMemFree(mix_format);
		}
		if (mmcss_handle != nullptr) {
			AvRevertMmThreadCharacteristics(mmcss_handle);
		}
		if (co_initialized) {
			CoUninitialize();
		}
		_set_unavailable();
		running.store(false);
		return;
	}

	available.store(true);
	double previous_energy = 0.0;
	double current_pulse = 0.0;
	auto previous_time = std::chrono::steady_clock::now();

	while (running.load()) {
		UINT32 packet_frames = 0;
		hr = capture_client->GetNextPacketSize(&packet_frames);
		if (FAILED(hr)) {
			break;
		}

		double latest_energy = 0.0;
		double latest_bass = 0.0;
		double latest_mid = 0.0;
		double latest_treble = 0.0;
		bool saw_packet = false;
		while (packet_frames > 0) {
			BYTE *data = nullptr;
			UINT32 frames = 0;
			DWORD flags = 0;
			hr = capture_client->GetBuffer(&data, &frames, &flags, nullptr, nullptr);
			if (FAILED(hr)) {
				break;
			}
			latest_energy = rms_energy(data, frames, flags, mix_format);
			estimate_time_bands(data, frames, flags, mix_format, latest_bass, latest_mid, latest_treble);
			saw_packet = true;
			capture_client->ReleaseBuffer(frames);
			hr = capture_client->GetNextPacketSize(&packet_frames);
			if (FAILED(hr)) {
				break;
			}
		}
		if (FAILED(hr)) {
			break;
		}

		const auto now = std::chrono::steady_clock::now();
		const std::chrono::duration<double> elapsed = now - previous_time;
		previous_time = now;

		if (!saw_packet) {
			latest_energy = 0.0;
			latest_bass = 0.0;
			latest_mid = 0.0;
			latest_treble = 0.0;
		}
		const double target = pulse_target_for_energy(latest_energy, previous_energy);
		current_pulse = smooth_pulse(current_pulse, target, elapsed.count());
		previous_energy = latest_energy;
		energy.store(latest_energy);
		pulse.store(current_pulse);
		bass.store(latest_bass);
		mid.store(latest_mid);
		treble.store(latest_treble);

		std::this_thread::sleep_for(std::chrono::milliseconds(10));
	}

	audio_client->Stop();
	if (mix_format != nullptr) {
		CoTaskMemFree(mix_format);
	}
	if (mmcss_handle != nullptr) {
		AvRevertMmThreadCharacteristics(mmcss_handle);
	}
	if (co_initialized) {
		CoUninitialize();
	}
	_set_unavailable();
#endif
}

} // namespace godot
