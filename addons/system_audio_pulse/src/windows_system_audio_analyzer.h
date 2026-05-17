#pragma once

#include <atomic>
#include <thread>

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class WindowsSystemAudioAnalyzer : public RefCounted {
	GDCLASS(WindowsSystemAudioAnalyzer, RefCounted)

public:
	WindowsSystemAudioAnalyzer();
	~WindowsSystemAudioAnalyzer();

	bool start();
	void stop();
	bool is_available() const;
	double get_energy() const;
	double get_pulse() const;

protected:
	static void _bind_methods();

private:
	void _capture_loop();
	void _set_unavailable();

	std::thread capture_thread;
	std::atomic<bool> running;
	std::atomic<bool> available;
	std::atomic<double> energy;
	std::atomic<double> pulse;
};

} // namespace godot
