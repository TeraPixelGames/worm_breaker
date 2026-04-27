extends Control

const MANDELBROT_SHADER: Shader = preload("res://src/shaders/fractals/mandelbrot_set.gdshader")

@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var summary_label: Label = $Center/VBox/SummaryLabel
@onready var target_label: Label = $Center/VBox/TargetLabel
@onready var restart_button: Button = $Center/VBox/RestartButton
@onready var menu_button: Button = $Center/VBox/MenuButton

var _time := 0.0
var _rings: Array[Panel] = []
var _fractal_material: ShaderMaterial

func _ready() -> void:
	_build_results_backdrop()
	_build_fractal_backdrop()
	_apply_results_style()
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
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.32))
	summary_label.add_theme_font_size_override("font_size", 24)
	summary_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.98))
	target_label.add_theme_font_size_override("font_size", 20)
	target_label.add_theme_color_override("font_color", Color(1.0, 0.52, 0.96))
	_style_button(restart_button, Color(0.02, 0.96, 0.82, 0.96), Color(0.02, 0.08, 0.12, 1.0))
	_style_button(menu_button, Color(0.075, 0.035, 0.13, 0.94), Color(0.92, 0.96, 1.0, 0.95))

func _style_button(button: Button, fill: Color, font: Color) -> void:
	button.custom_minimum_size = Vector2(320, 62)
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

static func results_title_text(is_win: bool) -> String:
	return "SPIRAL CLEAR" if is_win else "SIGNAL LOST"
