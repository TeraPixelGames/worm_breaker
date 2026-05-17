#pragma once

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_system_audio_pulse_module(ModuleInitializationLevel p_level);
void uninitialize_system_audio_pulse_module(ModuleInitializationLevel p_level);
