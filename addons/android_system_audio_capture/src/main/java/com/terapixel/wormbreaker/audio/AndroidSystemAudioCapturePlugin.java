package com.terapixel.wormbreaker.audio;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioPlaybackCaptureConfiguration;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.media.audiofx.Visualizer;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.os.Build;
import android.util.Log;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public final class AndroidSystemAudioCapturePlugin extends GodotPlugin {
	private static final String TAG = "WBSystemAudioCapture";
	private static final int REQUEST_MEDIA_PROJECTION = 43120;
	private static final int SAMPLE_RATE = 44100;
	private static final int CHANNEL_MASK = AudioFormat.CHANNEL_IN_STEREO;
	private static final int ENCODING = AudioFormat.ENCODING_PCM_FLOAT;
	private static final double PULSE_THRESHOLD = 0.003;
	private static final double ONSET_THRESHOLD = 0.002;
	private static final double LEVEL_GAIN = 14.0;
	private static final double LEVEL_MAX = 0.18;
	private static final double ONSET_GAIN = 32.0;
	private static final double ATTACK = 32.0;
	private static final double DECAY = 6.8;

	private final AtomicBoolean running = new AtomicBoolean(false);
	private volatile boolean available = false;
	private volatile boolean permissionPending = false;
	private volatile double energy = 0.0;
	private volatile double pulse = 0.0;
	private volatile double bass = 0.0;
	private volatile double mid = 0.0;
	private volatile double treble = 0.0;
	private double waveformEnergyFloor = 0.0;
	private Visualizer visualizer;
	private MediaProjection mediaProjection;
	private AudioRecord audioRecord;
	private Thread captureThread;

	public AndroidSystemAudioCapturePlugin(Godot godot) {
		super(godot);
	}

	@Override
	public String getPluginName() {
		return "AndroidSystemAudioCapture";
	}

	@Override
	public List<String> getPluginMethods() {
		return Arrays.asList("request_capture", "request_media_projection_capture", "stop", "is_available", "is_permission_pending", "get_energy", "get_pulse", "get_bass", "get_mid", "get_treble");
	}

	@UsedByGodot
	public boolean request_capture() {
		Log.i(TAG, "request_capture called; available=" + available + " running=" + running.get());
		if (available || permissionPending || running.get()) {
			return true;
		}
		if (startOutputMixVisualizer()) {
			return true;
		}
		resetState();
		return false;
	}

	@UsedByGodot
	public boolean request_media_projection_capture() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
			resetState();
			return false;
		}
		Activity activity = getActivity();
		if (activity == null) {
			return false;
		}
		MediaProjectionManager manager = (MediaProjectionManager) activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE);
		if (manager == null) {
			return false;
		}
		permissionPending = true;
		activity.startActivityForResult(manager.createScreenCaptureIntent(), REQUEST_MEDIA_PROJECTION);
		return true;
	}

	@UsedByGodot
	public void stop() {
		running.set(false);
		if (visualizer != null) {
			try {
				visualizer.setEnabled(false);
			} catch (IllegalStateException ignored) {
			}
			visualizer.release();
			visualizer = null;
		}
		if (captureThread != null) {
			try {
				captureThread.join(300);
			} catch (InterruptedException e) {
				Thread.currentThread().interrupt();
			}
			captureThread = null;
		}
		if (audioRecord != null) {
			try {
				audioRecord.stop();
			} catch (IllegalStateException ignored) {
			}
			audioRecord.release();
			audioRecord = null;
		}
		if (mediaProjection != null) {
			mediaProjection.stop();
			mediaProjection = null;
		}
		resetState();
	}

	@UsedByGodot
	public boolean is_available() {
		return available;
	}

	@UsedByGodot
	public boolean is_permission_pending() {
		return permissionPending;
	}

	@UsedByGodot
	public double get_energy() {
		return energy;
	}

	@UsedByGodot
	public double get_pulse() {
		return pulse;
	}

	@UsedByGodot
	public double get_bass() {
		return bass;
	}

	@UsedByGodot
	public double get_mid() {
		return mid;
	}

	@UsedByGodot
	public double get_treble() {
		return treble;
	}

	@Override
	public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
		if (requestCode != REQUEST_MEDIA_PROJECTION) {
			return;
		}
		permissionPending = false;
		if (resultCode != Activity.RESULT_OK || data == null) {
			resetState();
			return;
		}
		Activity activity = getActivity();
		if (activity == null) {
			resetState();
			return;
		}
		MediaProjectionManager manager = (MediaProjectionManager) activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE);
		if (manager == null) {
			resetState();
			return;
		}
		mediaProjection = manager.getMediaProjection(resultCode, data);
		startAudioRecord();
	}

	@Override
	public void onMainResume() {
		if (!running.get()) {
			request_capture();
		}
	}

	@Override
	public void onMainDestroy() {
		stop();
	}

	private void startAudioRecord() {
		if (mediaProjection == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
			resetState();
			return;
		}
		int minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_MASK, ENCODING);
		int bufferSize = Math.max(minBufferSize, SAMPLE_RATE * 2 * Float.BYTES / 5);
		AudioPlaybackCaptureConfiguration config = new AudioPlaybackCaptureConfiguration.Builder(mediaProjection)
				.addMatchingUsage(AudioAttributes.USAGE_MEDIA)
				.addMatchingUsage(AudioAttributes.USAGE_GAME)
				.addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
				.build();
		AudioFormat format = new AudioFormat.Builder()
				.setSampleRate(SAMPLE_RATE)
				.setEncoding(ENCODING)
				.setChannelMask(CHANNEL_MASK)
				.build();
		audioRecord = new AudioRecord.Builder()
				.setAudioFormat(format)
				.setBufferSizeInBytes(bufferSize)
				.setAudioPlaybackCaptureConfig(config)
				.build();
		audioRecord.startRecording();
		running.set(true);
		available = true;
		captureThread = new Thread(() -> captureLoop(bufferSize / Float.BYTES), "WormBreakerSystemAudioCapture");
		captureThread.start();
	}

	private boolean startOutputMixVisualizer() {
		try {
			Log.i(TAG, "Starting Android output-mix Visualizer capture");
			Visualizer outputMixVisualizer = new Visualizer(0);
			int[] captureSizeRange = Visualizer.getCaptureSizeRange();
			int captureSize = captureSizeRange != null && captureSizeRange.length >= 2 ? captureSizeRange[1] : 1024;
			outputMixVisualizer.setCaptureSize(captureSize);
			outputMixVisualizer.setScalingMode(Visualizer.SCALING_MODE_NORMALIZED);
			outputMixVisualizer.setDataCaptureListener(new Visualizer.OnDataCaptureListener() {
				@Override
				public void onWaveFormDataCapture(Visualizer visualizer, byte[] waveform, int samplingRate) {
					updateFromWaveform(waveform);
				}

				@Override
				public void onFftDataCapture(Visualizer visualizer, byte[] fft, int samplingRate) {
					updateFromFft(fft);
				}
			}, Visualizer.getMaxCaptureRate() / 2, true, true);
			outputMixVisualizer.setEnabled(true);
			visualizer = outputMixVisualizer;
			running.set(true);
			available = true;
			permissionPending = false;
			Log.i(TAG, "Started Android output-mix Visualizer capture");
			return true;
		} catch (RuntimeException e) {
			Log.w(TAG, "Output-mix Visualizer capture unavailable", e);
			if (visualizer != null) {
				visualizer.release();
				visualizer = null;
			}
			return false;
		}
	}

	private void updateFromWaveform(byte[] waveform) {
		if (waveform == null || waveform.length == 0) {
			return;
		}
		double previousEnergy = energy;
		double sum = 0.0;
		for (byte value : waveform) {
			double sample = (((int) value) & 0xff) - 128.0;
			double normalized = Math.max(-1.0, Math.min(1.0, sample / 128.0));
			sum += normalized * normalized;
		}
		double latestEnergy = Math.sqrt(sum / (double) waveform.length);
		waveformEnergyFloor = smoothEnergyFloor(waveformEnergyFloor, latestEnergy);
		double target = pulseTarget(latestEnergy, previousEnergy, waveformEnergyFloor);
		pulse = smoothPulse(pulse, target, 1.0 / 30.0);
		energy = latestEnergy;
		available = true;
	}

	private void updateFromFft(byte[] fft) {
		if (fft == null || fft.length < 4) {
			return;
		}
		bass = fftBandLevel(fft, 1, 6, 2.8);
		mid = fftBandLevel(fft, 7, 30, 2.0);
		treble = fftBandLevel(fft, 31, Math.min(120, (fft.length / 2) - 1), 2.5);
	}

	private void captureLoop(int sampleCapacity) {
		float[] buffer = new float[Math.max(sampleCapacity, 1024)];
		double previousEnergy = 0.0;
		double currentPulse = 0.0;
		long previousNanos = System.nanoTime();
		while (running.get() && audioRecord != null) {
			int read = audioRecord.read(buffer, 0, buffer.length, AudioRecord.READ_BLOCKING);
			if (read <= 0) {
				continue;
			}
			double sum = 0.0;
			for (int i = 0; i < read; i++) {
				double sample = Math.max(-1.0, Math.min(1.0, buffer[i]));
				sum += sample * sample;
			}
			double latestEnergy = Math.sqrt(sum / (double) read);
			updateTimeBands(buffer, read);
			long now = System.nanoTime();
			double delta = (now - previousNanos) / 1_000_000_000.0;
			previousNanos = now;
			double target = pulseTarget(latestEnergy, previousEnergy, 0.0);
			currentPulse = smoothPulse(currentPulse, target, delta);
			previousEnergy = latestEnergy;
			energy = latestEnergy;
			pulse = currentPulse;
		}
		available = false;
	}

	private static double pulseTarget(double currentEnergy, double previousEnergy, double energyFloor) {
		double levelReference = Math.max(PULSE_THRESHOLD, energyFloor + PULSE_THRESHOLD);
		double levelPulse = Math.min(Math.max(currentEnergy - levelReference, 0.0) * LEVEL_GAIN, LEVEL_MAX);
		double onsetPulse = Math.max((currentEnergy - previousEnergy) - ONSET_THRESHOLD, 0.0) * ONSET_GAIN;
		return Math.max(0.0, Math.min(1.0, Math.max(levelPulse, onsetPulse)));
	}

	private static double smoothEnergyFloor(double currentFloor, double latestEnergy) {
		double clampedEnergy = Math.max(0.0, latestEnergy);
		double rate = clampedEnergy > currentFloor ? 0.04 : 0.35;
		return Math.max(0.0, Math.min(1.0, currentFloor + (clampedEnergy - currentFloor) * rate));
	}

	private static double fftBandLevel(byte[] fft, int startBin, int endBin, double gain) {
		int maxBin = Math.max(1, (fft.length / 2) - 1);
		int start = Math.max(1, Math.min(maxBin, startBin));
		int end = Math.max(start, Math.min(maxBin, endBin));
		double sum = 0.0;
		double peak = 0.0;
		int count = 0;
		for (int bin = start; bin <= end; bin++) {
			int index = bin * 2;
			if (index + 1 >= fft.length) {
				break;
			}
			double real = (double) fft[index];
			double imag = (double) fft[index + 1];
			double magnitude = Math.min(1.0, Math.sqrt(real * real + imag * imag) / 181.0);
			sum += magnitude * magnitude;
			peak = Math.max(peak, magnitude);
			count++;
		}
		double rms = Math.sqrt(sum / Math.max(1, count));
		return Math.max(0.0, Math.min(1.0, Math.max(rms * gain, peak * gain * 0.45)));
	}

	private void updateTimeBands(float[] buffer, int read) {
		if (buffer == null || read <= 0) {
			bass = 0.0;
			mid = 0.0;
			treble = 0.0;
			return;
		}
		double lowSum = 0.0;
		double midSum = 0.0;
		double highSum = 0.0;
		double previous = 0.0;
		double previousDelta = 0.0;
		for (int i = 0; i < read; i++) {
			double sample = Math.max(-1.0, Math.min(1.0, buffer[i]));
			double delta = sample - previous;
			double secondDelta = delta - previousDelta;
			lowSum += sample * sample;
			midSum += delta * delta;
			highSum += secondDelta * secondDelta;
			previous = sample;
			previousDelta = delta;
		}
		double count = Math.max(1.0, (double) read);
		bass = Math.max(0.0, Math.min(1.0, Math.sqrt(lowSum / count) * 2.4));
		mid = Math.max(0.0, Math.min(1.0, Math.sqrt(midSum / count) * 7.0));
		treble = Math.max(0.0, Math.min(1.0, Math.sqrt(highSum / count) * 10.0));
	}

	private static double smoothPulse(double currentPulse, double targetPulse, double delta) {
		double rate = targetPulse > currentPulse ? ATTACK : DECAY;
		double weight = 1.0 - Math.exp(-rate * Math.max(delta, 0.0));
		double target = Math.max(0.0, Math.min(1.0, targetPulse));
		return Math.max(0.0, Math.min(1.0, currentPulse + (target - currentPulse) * Math.max(0.0, Math.min(1.0, weight))));
	}

	private void resetState() {
		available = false;
		permissionPending = false;
		energy = 0.0;
		pulse = 0.0;
		bass = 0.0;
		mid = 0.0;
		treble = 0.0;
		waveformEnergyFloor = 0.0;
	}
}
