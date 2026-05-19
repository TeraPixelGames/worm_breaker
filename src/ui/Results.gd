extends Control

const MANDELBROT_SHADER: Shader = preload("res://src/shaders/fractals/mandelbrot_set.gdshader")

@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var summary_label: Label = $Center/VBox/SummaryLabel
@onready var target_label: Label = $Center/VBox/TargetLabel
@onready var restart_button: Button = $Center/VBox/RestartButton
@onready var menu_button: Button = $Center/VBox/MenuButton

const CHAMBER_SAFE_MARGIN: float = 34.0
const CHAMBER_MAX_SIZE: Vector2 = Vector2(660, 500)

var _time := 0.0
var _rings: Array[Panel] = []
var _fractal_material: ShaderMaterial
var _result_chamber: Panel

func _ready() -> void:
	_build_results_backdrop()
	_build_fractal_backdrop()
	_build_result_chamber()
	_apply_results_style()
	_layout_result_chamber()
	var is_win: bool = RunManager.last_result_win
	title_label.text = results_title_text(is_win)
	var style_text := "Overdrive" if str(RunManager.run_style).to_lower() == "overdrive" else "Stability"
	summary_label.text = "SIGNAL CHARGE %d  /  BEST %d  /  %s\nDEPTH L%d" % [
		RunManager.run_score,
		SaveStore.high_score,
		style_text.to_upper(),
		RunManager.last_completed_level,
	]
	target_label.text = "RIVAL PRESSURE %d %s\nSPIRAL STREAK %d  /  BEST DEPTH L%d  /  PULSE RECORD %d" % [
		RunManager.last_rival_target,
		"BEAT" if RunManager.last_rival_beaten else "MISSED",
		SaveStore.run_win_streak,
		SaveStore.best_level_reached,
		SaveStore.rival_beat_streak
	]
	restart_button.text = "NEXT RUN" if is_win else "TRY AGAIN"
	menu_button.text = "STORY LAUNCH"

func _process(delta: float) -> void:
	_time += delta
	for i in range(_rings.size()):
		var ring := _rings[i]
		var pulse := 0.5 + 0.5 * sin(_time * (0.75 + float(i) * 0.18) + i)
		ring.rotation = -_time * (0.025 + float(i) * 0.011)
		ring.modulate.a = 0.14 + pulse * 0.18
	if _fractal_material != null:
		_fractal_material.set_shader_parameter("drift", 0.22 + 0.08 * sin(_time * 0.2))
	if _result_chamber != null:
		_result_chamber.scale = Vector2.ONE * (1.0 + sin(_time * 0.9) * 0.005)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_result_chamber()

func _on_restart_button_pressed() -> void:
	RunManager.start_new_run()

func _on_menu_button_pressed() -> void:
	RunManager.go_to_main_menu()

func _build_results_backdrop() -> void:
	var background := get_node_or_null("Background")
	if background is ColorRect:
		background.color = Color(0.018, 0.005, 0.055, 1.0)
	var palette := [
		Color(0.92, 0.04, 1.0, 0.24),
		Color(0.0, 0.92, 1.0, 0.18),
		Color(1.0, 0.78, 0.08, 0.16)
	]
	for i in range(7):
		var ring := Panel.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.anchor_left = 0.5
		ring.anchor_top = 0.5
		ring.anchor_right = 0.5
		ring.anchor_bottom = 0.5
		var size := 310.0 + float(i) * 130.0
		ring.offset_left = -size * 0.5
		ring.offset_top = -size * 0.5
		ring.offset_right = size * 0.5
		ring.offset_bottom = size * 0.5
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = palette[i % palette.size()]
		style.corner_radius_top_left = int(size * 0.5)
		style.corner_radius_top_right = int(size * 0.5)
		style.corner_radius_bottom_right = int(size * 0.5)
		style.corner_radius_bottom_left = int(size * 0.5)
		ring.add_theme_stylebox_override("panel", style)
		add_child(ring)
		move_child(ring, 1)
		_rings.append(ring)

func _build_fractal_backdrop() -> void:
	var fractal := ColorRect.new()
	fractal.name = "MandelbrotFractalBackdrop"
	fractal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fractal.set_anchors_preset(Control.PRESET_FULL_RECT)
	fractal.color = Color.WHITE
	_fractal_material = ShaderMaterial.new()
	_fractal_material.shader = MANDELBROT_SHADER
	_fractal_material.set_shader_parameter("alpha", 0.32)
	_fractal_material.set_shader_parameter("zoom", 2.6)
	_fractal_material.set_shader_parameter("recursion_limit", 86)
	fractal.material = _fractal_material
	add_child(fractal)
	move_child(fractal, 2)

func _apply_results_style() -> void:
	title_label.add_theme_font_size_override("font_size", 58)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.32))
	summary_label.add_theme_font_size_override("font_size", 23)
	summary_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.98))
	target_label.add_theme_font_size_override("font_size", 19)
	target_label.add_theme_color_override("font_color", Color(1.0, 0.52, 0.96))
	for label in [summary_label, target_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_button(restart_button, Color(0.02, 0.96, 0.82, 0.96), Color(0.02, 0.08, 0.12, 1.0))
	_style_button(menu_button, Color(0.075, 0.035, 0.13, 0.94), Color(0.92, 0.96, 1.0, 0.95))

func _build_result_chamber() -> void:
	if _result_chamber != null:
		return
	_result_chamber = Panel.new()
	_result_chamber.name = "ResultChamber"
	_result_chamber.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.0, 0.055, 0.88)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.96, 0.88, 0.64)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 24
	style.shadow_size = 24
	style.shadow_color = Color(0.78, 0.0, 1.0, 0.24)
	_result_chamber.add_theme_stylebox_override("panel", style)
	var center := get_node_or_null("Center") as Control
	if center == null:
		return
	center.add_child(_result_chamber)
	center.move_child(_result_chamber, 0)

func _layout_result_chamber() -> void:
	var center := get_node_or_null("Center") as Control
	if center == null:
		return
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 0.0
	center.offset_top = 0.0
	center.offset_right = 0.0
	center.offset_bottom = 0.0
	var viewport_size := size
	var chamber_size := Vector2(
		minf(CHAMBER_MAX_SIZE.x, maxf(320.0, viewport_size.x - CHAMBER_SAFE_MARGIN * 2.0)),
		minf(CHAMBER_MAX_SIZE.y, maxf(380.0, viewport_size.y - CHAMBER_SAFE_MARGIN * 2.0))
	)
	var chamber_pos := Vector2((viewport_size.x - chamber_size.x) * 0.5, (viewport_size.y - chamber_size.y) * 0.5)
	if _result_chamber != null:
		_apply_control_rect(_result_chamber, Rect2(chamber_pos, chamber_size))
		_result_chamber.pivot_offset = chamber_size * 0.5
	var inset := 42.0
	_apply_control_rect($Center/VBox, Rect2(chamber_pos + Vector2(inset, inset), chamber_size - Vector2(inset * 2.0, inset * 2.0)))
	($Center/VBox as VBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	($Center/VBox as VBoxContainer).add_theme_constant_override("separation", 14)

func _style_button(button: Button, fill: Color, font: Color) -> void:
	button.custom_minimum_size = Vector2(340, 60)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_color_override("font_color", font)
	button.add_theme_font_size_override("font_size", 23)
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 1.0, 1.0, 0.45)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.shadow_size = 14
	style.shadow_color = Color(fill.r, fill.g, fill.b, 0.22)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

func _apply_control_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y

static func results_title_text(is_win: bool) -> String:
	return "SPIRAL CLEAR" if is_win else "SIGNAL LOST"
