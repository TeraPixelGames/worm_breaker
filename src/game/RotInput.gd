extends Node

# Adapted from touch+keyboard lane rotation handling in wormhole_raiders:
# scripts/systems/InputSystem.gd
@export var max_ang_speed: float = 3.2
@export var ang_accel: float = 14.0
@export var ang_damping: float = 10.0
@export var touch_axis_sensitivity: float = 2.4
@export var input_deadzone: float = 0.04
@export var invert_touch_axis: bool = true
@export var invert_keyboard_axis: bool = true

var _touch_start: Vector2 = Vector2.ZERO
var _active_touch_index: int = -1
var _touch_axis: float = 0.0
var _left_pressed: bool = false
var _right_pressed: bool = false
var _angular_velocity: float = 0.0
var _drive_axis: float = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.echo:
			return
		if key_event.keycode == KEY_LEFT or key_event.keycode == KEY_A:
			_left_pressed = key_event.pressed
		elif key_event.keycode == KEY_RIGHT or key_event.keycode == KEY_D:
			_right_pressed = key_event.pressed

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed and _active_touch_index == -1:
			_active_touch_index = touch_event.index
			_touch_start = touch_event.position
			_touch_axis = 0.0
		elif not touch_event.pressed and touch_event.index == _active_touch_index:
			_active_touch_index = -1
			_touch_axis = 0.0

	if event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
		if drag_event.index != _active_touch_index:
			return
		var viewport_width: float = float(get_viewport().get_visible_rect().size.x)
		var normalized_dx: float = (drag_event.position.x - _touch_start.x) / max(viewport_width * 0.35, 1.0)
		_touch_axis = clampf(normalized_dx * touch_axis_sensitivity, -1.0, 1.0)
		if invert_touch_axis:
			_touch_axis *= -1.0

func _physics_process(delta: float) -> void:
	var keyboard_axis: float = float(int(_right_pressed) - int(_left_pressed))
	if invert_keyboard_axis:
		keyboard_axis *= -1.0
	_drive_axis = _touch_axis if _active_touch_index != -1 else keyboard_axis
	if absf(_drive_axis) < input_deadzone:
		_drive_axis = 0.0

	var target_vel: float = _drive_axis * max_ang_speed
	var accel: float = ang_accel if _drive_axis != 0.0 else ang_damping
	_angular_velocity = move_toward(_angular_velocity, target_vel, accel * delta)
	_angular_velocity = clampf(_angular_velocity, -max_ang_speed, max_ang_speed)

func reset() -> void:
	_active_touch_index = -1
	_touch_axis = 0.0
	_left_pressed = false
	_right_pressed = false
	_drive_axis = 0.0
	_angular_velocity = 0.0

func get_angular_velocity() -> float:
	return _angular_velocity

func get_drive_axis() -> float:
	return _drive_axis
