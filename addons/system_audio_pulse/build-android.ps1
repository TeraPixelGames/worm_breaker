param(
	[ValidateSet("Debug", "Release")]
	[string]$Config = "Release",
	[string]$Abi = "arm64-v8a",
	[string]$AndroidNdk = "C:\Program Files (x86)\Android\AndroidNDK\android-ndk-r27c",
	[int]$Jobs = [Environment]::ProcessorCount
)

$ErrorActionPreference = "Stop"
$AddonRoot = $PSScriptRoot
$ProjectRoot = (Resolve-Path (Join-Path $AddonRoot "..\..")).Path
$BuildRoot = Join-Path $ProjectRoot "tmp\system_audio_pulse"
$BuildDir = Join-Path $BuildRoot ("build-android-" + $Abi + "-" + $Config.ToLowerInvariant())
$Toolchain = Join-Path $AndroidNdk "build\cmake\android.toolchain.cmake"
$CMake = "cmake"
$BundledCMake = "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
$Ninja = "ninja"
$BundledNinja = "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"

if (-not (Test-Path $Toolchain)) {
	throw "Android NDK toolchain not found: $Toolchain"
}
if (-not (Get-Command $CMake -ErrorAction SilentlyContinue) -and (Test-Path $BundledCMake)) {
	$CMake = $BundledCMake
}
if (-not (Get-Command $Ninja -ErrorAction SilentlyContinue) -and (Test-Path $BundledNinja)) {
	$Ninja = $BundledNinja
}
$Generator = "NMake Makefiles"
if (Get-Command $Ninja -ErrorAction SilentlyContinue) {
	$Generator = "Ninja Multi-Config"
}
$ConfigureArgs = @(
	"-S", $AddonRoot,
	"-B", $BuildDir,
	"-G", $Generator,
	"-DCMAKE_TOOLCHAIN_FILE=$Toolchain",
	"-DANDROID_ABI=$Abi",
	"-DANDROID_PLATFORM=android-29",
	"-DANDROID_STL=c++_static"
)
if ($Generator -eq "NMake Makefiles") {
	$ConfigureArgs += "-DCMAKE_BUILD_TYPE=$Config"
}

& $CMake @ConfigureArgs
& $CMake --build $BuildDir --config $Config --parallel $Jobs
