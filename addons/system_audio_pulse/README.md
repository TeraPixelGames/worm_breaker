# System Audio Pulse GDExtension

Native analyzer class for Worm Breaker's tunnel pulse.

The Windows build uses WASAPI loopback for system-output energy. Android and iOS builds register the same `WindowsSystemAudioAnalyzer` class but report unavailable because those platforms do not allow silent arbitrary device-output capture for normal third-party games.

## Requirements

- Godot 4.5.x desktop export/runtime.
- Windows 10 or newer.
- Visual Studio 2022 Build Tools with the C++ desktop workload.
- CMake 3.22 or newer.
- Git, so CMake can fetch `godot-cpp`.

## Windows Build

From this directory:

```powershell
.\build-windows.ps1 -Config Release
```

The DLL is written to:

```text
addons/system_audio_pulse/bin/system_audio_pulse.windows.template_release.x86_64.dll
```

The build also creates `system_audio_pulse.gdextension` from `system_audio_pulse.gdextension.in`. CMake intermediate files are written under the project `tmp/` folder so Godot does not import native object files from `res://addons`.

For editor/debug use:

```powershell
.\build-windows.ps1 -Config Debug
```

The game treats this extension as optional. If the DLL is missing, unsupported, disabled, or cannot open the default render endpoint, Worm Breaker loads normally and the tunnel system-audio pulse remains at zero.

When the Windows DLL and `.gdextension` file are present, the analyzer starts by default on Windows. To disable it for emergency testing, launch Godot with:

```powershell
$env:WORM_BREAKER_DISABLE_SYSTEM_AUDIO_PULSE = "1"
godot --path C:\code\TeraPixel\games\worm_breaker
```

## Android Build

From this directory:

```powershell
.\build-android.ps1 -Config Debug
.\build-android.ps1 -Config Release
```

The script uses Ninja Multi-Config when Visual Studio's bundled Ninja is available and forwards parallelism through CMake. Override the worker count with `-Jobs`:

```powershell
.\build-android.ps1 -Config Debug -Jobs 24
```

The Android shared libraries are written to:

```text
addons/system_audio_pulse/bin/libsystem_audio_pulse.android.template_debug.arm64.so
addons/system_audio_pulse/bin/libsystem_audio_pulse.android.template_release.arm64.so
```

They are native-load compatibility shims for Android exports; they do not capture device output.

## iOS Build

The CMake project has iOS output names and `.gdextension` entries, but iOS builds must be produced on macOS with Xcode and iOS export templates installed. The iOS target is also a native-load compatibility shim; iOS does not provide a normal app API for silent system-output capture.
