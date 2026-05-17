param(
	[ValidateSet("Debug", "Release")]
	[string]$Config = "Release"
)

$ErrorActionPreference = "Stop"
$AddonRoot = $PSScriptRoot
$ProjectRoot = (Resolve-Path (Join-Path $AddonRoot "..\..")).Path
$BuildRoot = Join-Path $ProjectRoot "tmp\system_audio_pulse"
$BuildDir = Join-Path $BuildRoot ("build-" + $Config.ToLowerInvariant())
$CMake = "cmake"
$BundledCMake = "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
if (-not (Get-Command $CMake -ErrorAction SilentlyContinue) -and (Test-Path $BundledCMake)) {
	$CMake = $BundledCMake
}

& $CMake -S $AddonRoot -B $BuildDir -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=$Config
& $CMake --build $BuildDir --config $Config
