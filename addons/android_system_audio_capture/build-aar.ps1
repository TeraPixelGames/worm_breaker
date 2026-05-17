param(
	[string]$AndroidJar = "C:\Users\john_\AppData\Local\Android\Sdk\platforms\android-36\android.jar",
	[string]$GodotAar = "$env:APPDATA\Godot\export_templates\4.5.1.stable\android_source.zip"
)

$ErrorActionPreference = "Stop"
$AddonRoot = $PSScriptRoot
$ProjectRoot = (Resolve-Path (Join-Path $AddonRoot "..\..")).Path
$BuildRoot = Join-Path $ProjectRoot "tmp\android_system_audio_capture"
$GodotAarPath = Join-Path $BuildRoot "godot-lib.template_debug.aar"
$GodotClassesDir = Join-Path $BuildRoot "godot-aar"
$ClassesDir = Join-Path $BuildRoot "classes"
$ClassesJar = Join-Path $BuildRoot "classes.jar"
$AarPath = Join-Path $AddonRoot "android_system_audio_capture.aar"
$RootAarPath = Join-Path (Split-Path -Parent $AddonRoot) "android_system_audio_capture.aar"

if (-not (Test-Path $AndroidJar)) {
	throw "android.jar not found: $AndroidJar"
}
if (-not (Test-Path $GodotAar)) {
	throw "Godot Android source template not found: $GodotAar"
}

Remove-Item -LiteralPath $BuildRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $BuildRoot, $GodotClassesDir, $ClassesDir | Out-Null
tar -xf $GodotAar -C $BuildRoot libs/debug/godot-lib.template_debug.aar
Move-Item -LiteralPath (Join-Path $BuildRoot "libs\debug\godot-lib.template_debug.aar") -Destination $GodotAarPath
tar -xf $GodotAarPath -C $GodotClassesDir classes.jar

$Source = Join-Path $AddonRoot "src\main\java\com\terapixel\wormbreaker\audio\AndroidSystemAudioCapturePlugin.java"
javac -source 17 -target 17 -classpath "$AndroidJar;$GodotClassesDir\classes.jar" -d $ClassesDir $Source
jar cf $ClassesJar -C $ClassesDir .

Remove-Item -LiteralPath $AarPath -Force -ErrorAction SilentlyContinue
$AarZip = Join-Path $BuildRoot "android_system_audio_capture.zip"
Compress-Archive -Path $ClassesJar,(Join-Path $AddonRoot "src\main\AndroidManifest.xml") -DestinationPath $AarZip
Move-Item -LiteralPath $AarZip -Destination $AarPath
Copy-Item -LiteralPath $AarPath -Destination $RootAarPath -Force
