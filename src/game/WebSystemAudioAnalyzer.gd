extends RefCounted

const WEB_AUDIO_SCRIPT_PATH := "res://src/web/web_system_audio_analyzer.js"

var _loaded := false

func start() -> bool:
	if not _ensure_loaded():
		return false
	JavaScriptBridge.eval("window.WormBreakerWebAudio.start();", false)
	return true

func stop() -> void:
	if not _ensure_loaded():
		return
	JavaScriptBridge.eval("window.WormBreakerWebAudio.stop();", false)

func is_available() -> bool:
	if not _ensure_loaded():
		return false
	return bool(JavaScriptBridge.eval("window.WormBreakerWebAudio.isAvailable();", true))

func get_energy() -> float:
	if not _ensure_loaded():
		return 0.0
	return maxf(float(JavaScriptBridge.eval("window.WormBreakerWebAudio.getEnergy();", true)), 0.0)

func get_pulse() -> float:
	if not _ensure_loaded():
		return 0.0
	return clampf(float(JavaScriptBridge.eval("window.WormBreakerWebAudio.getPulse();", true)), 0.0, 1.0)

func get_bass() -> float:
	if not _ensure_loaded():
		return 0.0
	return clampf(float(JavaScriptBridge.eval("window.WormBreakerWebAudio.getBass();", true)), 0.0, 1.0)

func get_mid() -> float:
	if not _ensure_loaded():
		return 0.0
	return clampf(float(JavaScriptBridge.eval("window.WormBreakerWebAudio.getMid();", true)), 0.0, 1.0)

func get_treble() -> float:
	if not _ensure_loaded():
		return 0.0
	return clampf(float(JavaScriptBridge.eval("window.WormBreakerWebAudio.getTreble();", true)), 0.0, 1.0)

func get_status() -> String:
	if not _ensure_loaded():
		return "unsupported"
	return str(JavaScriptBridge.eval("window.WormBreakerWebAudio.getStatus();", true))

func is_supported() -> bool:
	if not _ensure_loaded():
		return false
	return bool(JavaScriptBridge.eval("window.WormBreakerWebAudio.isSupported();", true))

func _ensure_loaded() -> bool:
	if _loaded:
		return true
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return false
	var file := FileAccess.open(WEB_AUDIO_SCRIPT_PATH, FileAccess.READ)
	if file == null:
		return false
	var source := file.get_as_text()
	if source.strip_edges().is_empty():
		return false
	JavaScriptBridge.eval(source, true)
	_loaded = bool(JavaScriptBridge.eval("Boolean(window.WormBreakerWebAudio);", true))
	return _loaded
