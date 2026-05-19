extends "res://tests/framework/TestCase.gd"

const GameController: Script = preload("res://src/game/GameController.gd")

func test_default_tunnel_layout_lineup_rotates_by_level() -> void:
	var lineup: PackedStringArray = GameController.default_tunnel_layout_lineup()
	assert_equal(GameController.tunnel_layout_for_level(1, {}, lineup), "neon_circuit_octagon", "First level should use the neon circuit tunnel background")
	assert_equal(GameController.tunnel_layout_for_level(2, {}, lineup), "amber_crystal_lattice", "Second level should rotate to the amber crystal tunnel background")
	assert_equal(GameController.tunnel_layout_for_level(3, {}, lineup), "blue_waveform_rings", "Third level should rotate to the blue waveform tunnel background")
	assert_equal(GameController.tunnel_layout_for_level(4, {}, lineup), "violet_nebula_kaleido", "Fourth level should rotate to the violet nebula tunnel background")
	assert_equal(GameController.tunnel_layout_for_level(5, {}, lineup), "neon_circuit_octagon", "Tunnel lineup should wrap after the last preset")

func test_tunnel_layout_level_data_overrides_lineup() -> void:
	var lineup: PackedStringArray = GameController.normalized_tunnel_layout_lineup("projectm_grid,amber_mesh")
	var level_data: Dictionary = {"tunnel_layout": "signal_lattice"}
	assert_equal(GameController.tunnel_layout_for_level(1, level_data, lineup), "signal_lattice", "Level data should be able to pin a specific tunnel layout")

func test_tunnel_layout_lineup_parser_filters_unknown_entries() -> void:
	var lineup: PackedStringArray = GameController.normalized_tunnel_layout_lineup(" blue_waveform_rings,unknown,amber_crystal_lattice,blue_waveform_rings ")
	assert_equal(lineup.size(), 2, "Tunnel lineup should ignore unknown and duplicate layout ids")
	assert_equal(lineup[0], "blue_waveform_rings", "Parser should preserve the first known layout order")
	assert_equal(lineup[1], "amber_crystal_lattice", "Parser should keep later known layouts")

func test_tunnel_layout_transition_blend_is_smooth_and_bounded() -> void:
	assert_equal(GameController.tunnel_layout_transition_blend(-1.0, 1.0), 0.0, "Layout transition should clamp negative time")
	var middle: float = GameController.tunnel_layout_transition_blend(0.5, 1.0)
	assert_true(middle > 0.0, "Layout transition should start moving before halfway")
	assert_true(middle < 1.0, "Layout transition should not finish before the duration")
	assert_equal(GameController.tunnel_layout_transition_blend(2.0, 1.0), 1.0, "Layout transition should clamp after the duration")

func test_default_portal_light_lineup_rotates_by_level() -> void:
	var lineup: PackedStringArray = GameController.default_portal_light_lineup()
	assert_equal(GameController.portal_light_for_level(1, {}, lineup), "original_mandelbrot", "First level should keep the original tunnel end background")
	assert_equal(GameController.portal_light_for_level(2, {}, lineup), "flowing_wires", "Second level should rotate to the flowing wire portal")
	assert_equal(GameController.portal_light_for_level(3, {}, lineup), "hex_bloom", "Third level should rotate to the hex bloom portal")
	assert_equal(GameController.portal_light_for_level(4, {}, lineup), "original_mandelbrot", "Portal light lineup should wrap after the last preset")

func test_portal_light_level_data_overrides_lineup() -> void:
	var lineup: PackedStringArray = GameController.normalized_portal_light_lineup("radiant_core,flowing_wires")
	var level_data: Dictionary = {"portal_light": "hex_bloom"}
	assert_equal(GameController.portal_light_for_level(1, level_data, lineup), "hex_bloom", "Level data should be able to pin a portal light")

func test_portal_light_lineup_parser_filters_unknown_entries() -> void:
	var lineup: PackedStringArray = GameController.normalized_portal_light_lineup(" flowing_wires,unknown,hex_bloom,flowing_wires ")
	assert_equal(lineup.size(), 2, "Portal light lineup should ignore unknown and duplicate ids")
	assert_equal(lineup[0], "flowing_wires", "Portal parser should preserve first known light order")
	assert_equal(lineup[1], "hex_bloom", "Portal parser should keep later known lights")

func test_tunnel_light_portal_shader_loads() -> void:
	assert_true(ResourceLoader.exists("res://src/shaders/tunnel_light_portal.gdshader"), "Tunnel light portal shader should exist")
	var shader := load("res://src/shaders/tunnel_light_portal.gdshader") as Shader
	assert_true(shader != null, "Tunnel light portal shader should load")

func test_tunnel_light_portal_shader_has_layered_depth() -> void:
	var shader_source := FileAccess.get_file_as_string("res://src/shaders/tunnel_light_portal.gdshader")
	assert_true(shader_source.contains("portal_depth_volume"), "Tunnel end light shader should include layered portal depth")
	assert_true(shader_source.contains("depth_layers"), "Tunnel end light shader should expose depth layer count")
	assert_true(shader_source.contains("volumetric_glow"), "Tunnel end light shader should expose volumetric glow control")

func test_tunnel_background_textures_load() -> void:
	var paths: Array[String] = [
		"res://assets/tunnel_backgrounds/neon_circuit_octagon.png",
		"res://assets/tunnel_backgrounds/amber_crystal_lattice.png",
		"res://assets/tunnel_backgrounds/blue_waveform_rings.png",
		"res://assets/tunnel_backgrounds/violet_nebula_kaleido.png"
	]
	for path in paths:
		assert_true(ResourceLoader.exists(path), "%s should exist" % path)
		var texture := load(path) as Texture2D
		assert_true(texture != null, "%s should load as a texture" % path)

func test_tunnel_shader_audio_shifts_background_colors() -> void:
	var shader_source := FileAccess.get_file_as_string("res://src/shaders/fractals/tunnel_fractal_wrap.gdshader")
	assert_true(shader_source.contains("audio_shift_background"), "Tunnel shader should color-shift sampled backgrounds from audio")
	assert_true(shader_source.contains("audio_bass"), "Tunnel shader should use bass to change background colors")
	assert_true(shader_source.contains("audio_mid"), "Tunnel shader should use mids to change background colors")
	assert_true(shader_source.contains("audio_treble"), "Tunnel shader should use treble to change background colors")

func test_tunnel_shader_uses_real_transparency() -> void:
	var shader_source := FileAccess.get_file_as_string("res://src/shaders/fractals/tunnel_fractal_wrap.gdshader")
	assert_true(shader_source.contains("blend_mix"), "Tunnel shader should blend by alpha instead of drawing opaque haze")
	assert_true(shader_source.contains("depth_draw_never"), "Transparent tunnel should not depth-write over radiant backgrounds")
	assert_true(shader_source.contains("ALPHA = tunnel_alpha"), "Tunnel shader should expose low-intensity areas as transparent alpha")
	assert_true(not shader_source.contains("depth_draw_opaque"), "Tunnel shader should not use the opaque depth path")

func test_original_portal_shader_loads_for_first_stage() -> void:
	assert_true(ResourceLoader.exists("res://src/shaders/fractals/mandelbrot_portal.gdshader"), "Original tunnel end shader should exist")
	var shader := load("res://src/shaders/fractals/mandelbrot_portal.gdshader") as Shader
	assert_true(shader != null, "Original tunnel end shader should load")

func test_original_portal_shader_has_depth_layers() -> void:
	var shader_source := FileAccess.get_file_as_string("res://src/shaders/fractals/mandelbrot_portal.gdshader")
	assert_true(shader_source.contains("layer_index"), "Original portal shader should layer samples for depth")
	assert_true(shader_source.contains("parallax"), "Original portal shader should use parallax depth offsets")
	assert_true(shader_source.contains("volumetric_glow"), "Original portal shader should include volumetric glow")
