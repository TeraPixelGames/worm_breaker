extends Node

const WebSystemAudioAnalyzer = preload("res://src/game/WebSystemAudioAnalyzer.gd")

var _analyzer: RefCounted

func _ready() -> void:
	if OS.has_feature("web"):
		_analyzer = WebSystemAudioAnalyzer.new()

func start() -> bool:
	if not is_supported():
		return false
	return bool(_analyzer.call("start"))

func stop() -> void:
	if _analyzer != null and _analyzer.has_method("stop"):
		_analyzer.call("stop")

func is_supported() -> bool:
	return _analyzer != null and _analyzer.has_method("is_supported") and bool(_analyzer.call("is_supported"))

func is_available() -> bool:
	return _analyzer != null and _analyzer.has_method("is_available") and bool(_analyzer.call("is_available"))

func get_energy() -> float:
	if _analyzer == null or not _analyzer.has_method("get_energy"):
		return 0.0
	return maxf(float(_analyzer.call("get_energy")), 0.0)

func get_pulse() -> float:
	if _analyzer == null or not _analyzer.has_method("get_pulse"):
		return 0.0
	return clampf(float(_analyzer.call("get_pulse")), 0.0, 1.0)

func get_bass() -> float:
	if _analyzer == null or not _analyzer.has_method("get_bass"):
		return 0.0
	return clampf(float(_analyzer.call("get_bass")), 0.0, 1.0)

func get_mid() -> float:
	if _analyzer == null or not _analyzer.has_method("get_mid"):
		return 0.0
	return clampf(float(_analyzer.call("get_mid")), 0.0, 1.0)

func get_treble() -> float:
	if _analyzer == null or not _analyzer.has_method("get_treble"):
		return 0.0
	return clampf(float(_analyzer.call("get_treble")), 0.0, 1.0)

func get_status() -> String:
	if _analyzer == null or not _analyzer.has_method("get_status"):
		return "unsupported"
	return str(_analyzer.call("get_status"))
