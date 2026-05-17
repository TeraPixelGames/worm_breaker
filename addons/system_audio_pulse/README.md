# System Audio Pulse GDExtension

Windows-only WASAPI loopback analyzer for Worm Breaker's tunnel pulse.

## Requirements

- Godot 4.5.x desktop export/runtime.
- Windows 10 or newer.
- Visual Studio 2022 Build Tools with the C++ desktop workload.
- CMake 3.22 or newer.
- Git, so CMake can fetch `godot-cpp`.

## Build

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
