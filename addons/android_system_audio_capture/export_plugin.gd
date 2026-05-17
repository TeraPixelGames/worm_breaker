@tool
extends EditorPlugin

var export_plugin: AndroidSystemAudioExportPlugin

func _enter_tree() -> void:
	export_plugin = AndroidSystemAudioExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	if export_plugin != null:
		remove_export_plugin(export_plugin)
		export_plugin = null

class AndroidSystemAudioExportPlugin extends EditorExportPlugin:
	const PLUGIN_NAME := "AndroidSystemAudioCapture"
	const AAR_PATH := "android_system_audio_capture/android_system_audio_capture.aar"

	func _get_name() -> String:
		return PLUGIN_NAME

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([AAR_PATH])

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return "\n\t\t<meta-data android:name=\"org.godotengine.plugin.v2.AndroidSystemAudioCapture\" android:value=\"com.terapixel.wormbreaker.audio.AndroidSystemAudioCapturePlugin\" />\n"
