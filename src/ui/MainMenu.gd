extends Control

const JULIA_SHADER: Shader = preload("res://src/shaders/fractals/julia_set.gdshader")

@onready var summary_label: Label = $Center/Panel/VBox/SummaryLabel
@onready var panel: Panel = $Center/Panel
@onready var vbox: VBoxContainer = $Center/Panel/VBox
@onready var title_label: Label = $Center/Panel/VBox/TitleLabel
@onready var subtitle_label: Label = $Center/Panel/VBox/SubtitleLabel
@onready var signal_label: Label = $Center/Panel/VBox/SignalLabel
@onready var start_button: Button = $Center/Panel/VBox/StartButton
@onready var overdrive_button: Button = $Center/Panel/VBox/OverdriveButton
@onready var tutorial_button: Button = $Center/Panel/VBox/TutorialButton
@onready var quit_button: Button = $Center/Panel/VBox/QuitButton

const PANEL_MAX_WIDTH: float = 740.0
const PANEL_MAX_HEIGHT: float = 620.0
const PANEL_SAFE_MARGIN: float = 48.0
const PANEL_INSET: float = 48.0

var _time := 0.0
var _rings: Array[Panel] = []
var _fractal_material: ShaderMaterial

func _ready() -> void:
	MusicManager.play_menu()
	_build_psychedelic_backdrop()
	_build_fractal_backdrop()
	_apply_launch_deck_style()
	_update_launch_deck_layout()
	var rival_target := SaveStore.refresh_rival_target()
	summary_label.text = "BEST DEPTH L%d  /  SIGNAL %d  /  STREAK %d\nRIVAL PRESSURE %d  /  PULSE RECORD %d" % [
		SaveStore.best_level_reached,
		SaveStore.high_score,
		SaveStore.run_win_streak,
		rival_target,
		SaveStore.rival_beat_streak
	]

func _process(delta: float) -> void:
	_time += delta
	for i in range(_rings.size()):
		var ring := _rings[i]
		var pulse := 0.5 + 0.5 * sin(_time * (0.85 + float(i) * 0.13) + float(i) * 0.9)
		ring.rotation = _time * (0.035 + float(i) * 0.012)
		ring.scale = Vector2.ONE * (1.0 + pulse * 0.035)
		ring.modulate.a = 0.18 + pulse * 0.16
	panel.scale = Vector2.ONE * (1.0 + sin(_time * 1.1) * 0.006)
	if _fractal_material != null:
		_fractal_material.set_shader_parameter("zoom", 1.05 + 0.06 * sin(_time * 0.33))
	_update_panel_pivot()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_launch_deck_layout()

func _on_start_button_pressed() -> void:
	RunManager.set_run_style("stability")
	RunManager.start_new_run("stability")

func _on_overdrive_button_pressed() -> void:
	RunManager.set_run_style("overdrive")
	RunManager.start_new_run("overdrive")

func _on_tutorial_button_pressed() -> void:
	RunManager.set_run_style("stability")
	RunManager.start_new_run("stability")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _build_psychedelic_backdrop() -> void:
	var background := get_node_or_null("Background")
	if background is ColorRect:
		background.color = Color(0.012, 0.005, 0.04, 1.0)
	var accent := get_node_or_null("AccentGlow")
	if accent is ColorRect:
		accent.color = Color(0.58, 0.0, 0.95, 0.18)

	var palette := [
		Color(0.95, 0.08, 0.92, 0.28),
		Color(0.06, 0.95, 1.0, 0.22),
		Color(1.0, 0.82, 0.06, 0.18),
		Color(0.25, 1.0, 0.34, 0.16)
	]
	for i in range(9):
		var ring := Panel.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.anchor_left = 0.5
		ring.anchor_top = 0.5
		ring.anchor_right = 0.5
		ring.anchor_bottom = 0.5
		var size := 250.0 + float(i) * 115.0
		ring.offset_left = -size * 0.5
		ring.offset_top = -size * 0.5
		ring.offset_right = size * 0.5
		ring.offset_bottom = size * 0.5
		ring.modulate.a = 0.16
		ring.pivot_offset = Vector2(size * 0.5, size * 0.5)
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
	fractal.name = "JuliaFractalBackdrop"
	fractal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fractal.set_anchors_preset(Control.PRESET_FULL_RECT)
	fractal.color = Color.WHITE
	_fractal_material = ShaderMaterial.new()
	_fractal_material.shader = JULIA_SHADER
	_fractal_material.set_shader_parameter("alpha", 0.28)
	_fractal_material.set_shader_parameter("zoom", 1.05)
	_fractal_material.set_shader_parameter("speed", 0.42)
	fractal.material = _fractal_material
	add_child(fractal)
	move_child(fractal, 2)

func _apply_launch_deck_style() -> void:
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.0, 0.075, 0.86), Color(0.96, 0.08, 0.9, 0.65), 34))

	title_label.text = "WORM BREAKER"
	title_label.add_theme_font_size_override("font_size", 68)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
	subtitle_label.text = "Stabilize the pulse inside a psychedelic signal tunnel."
	subtitle_label.add_theme_color_override("font_color", Color(0.68, 1.0, 0.98, 0.92))
	signal_label.text = "ROTATE STABILIZER  /  CATCH PULSE  /  BREAK FRAGMENTS"
	signal_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.92, 0.92))
	summary_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.92))

	_style_button(start_button, Color(0.02, 1.0, 0.82, 0.95), Color(0.02, 0.08, 0.12, 1.0))
	_style_button(overdrive_button, Color(1.0, 0.05, 0.75, 0.95), Color(1.0, 0.96, 0.68, 1.0))
	_style_button(tutorial_button, Color(0.98, 0.82, 0.12, 0.94), Color(0.08, 0.035, 0.0, 1.0))
	_style_button(quit_button, Color(0.055, 0.035, 0.12, 0.92), Color(0.88, 0.9, 1.0, 0.9))
	start_button.text = "STABILITY RUN"
	overdrive_button.text = "OVERDRIVE"
	tutorial_button.text = "TUTORIAL"
	quit_button.text = "EXIT"
	_update_launch_deck_layout()

func _update_launch_deck_layout() -> void:
	if panel == null:
		return
	var available_width: float = maxf(size.x - PANEL_SAFE_MARGIN * 2.0, 320.0)
	panel.custom_minimum_size.x = min(PANEL_MAX_WIDTH, available_width)
	panel.custom_minimum_size.y = min(PANEL_MAX_HEIGHT, maxf(size.y - PANEL_SAFE_MARGIN * 2.0, 560.0))
	panel.scale = Vector2.ONE
	if vbox != null:
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = PANEL_INSET
		vbox.offset_top = PANEL_INSET
		vbox.offset_right = -PANEL_INSET
		vbox.offset_bottom = -PANEL_INSET
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_update_panel_pivot()
	call_deferred("_update_panel_pivot")

func _update_panel_pivot() -> void:
	if panel == null:
		return
	panel.pivot_offset = panel.size * 0.5

func _style_button(button: Button, fill: Color, font: Color) -> void:
	button.custom_minimum_size = Vector2(340, 64)
	button.add_theme_color_override("font_color", font)
	button.add_theme_font_size_override("font_size", 24)
	var normal := _button_style(fill, Color(1.0, 1.0, 1.0, 0.45))
	var hover := _button_style(fill.lightened(0.12), Color(1.0, 1.0, 1.0, 0.85))
	var pressed := _button_style(fill.darkened(0.14), Color(1.0, 0.96, 0.3, 0.95))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

func _panel_style(fill: Color, stroke: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = stroke
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 26
	return style

func _button_style(fill: Color, stroke: Color) -> StyleBoxFlat:
	var style := _panel_style(fill, stroke, 18)
	style.shadow_size = 12
	style.shadow_color = Color(fill.r, fill.g, fill.b, 0.24)
	return style
