extends Node3D
## Third-person orbit camera. Mouse motion drives yaw/pitch on this pivot;
## the SpringArm3D child handles collision so the camera never clips through
## walls. Also owns trauma-based screenshake and punch-zoom impact feedback,
## applied to the Camera3D itself rather than this pivot's own rotation —
## that keeps shake/zoom from ever fighting the mouse-look math below, which
## overwrites this node's `rotation` unconditionally every frame.

@export var mouse_sensitivity: float = 0.0035
@export var pitch_min_degrees: float = -60.0
@export var pitch_max_degrees: float = 15.0

@export_group("Screenshake")
## Trauma (0-1) decays at this rate regardless of how much was added; actual
## shake magnitude scales with trauma^2, so it punches hard on a big hit and
## recovers fast rather than lingering.
@export var trauma_decay_per_second: float = 1.8
@export var max_shake_rotation_degrees: float = 4.0
@export var max_shake_offset: float = 0.15
@export var shake_noise_speed: float = 18.0

var yaw: float = 0.0
var pitch: float = deg_to_rad(-10.0)

@onready var camera: Camera3D = $SpringArm3D/Camera3D

var _trauma: float = 0.0
var _base_fov: float = 65.0
var _noise := FastNoiseLite.new()
var _noise_t: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_base_fov = camera.fov
	_noise.seed = randi()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(pitch_min_degrees), deg_to_rad(pitch_max_degrees))
	elif event.is_action_pressed("toggle_mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	rotation = Vector3(pitch, yaw, 0.0)
	_process_shake(delta)

## Adds screen-shake trauma (clamped to 1.0, so spammed hits can't stack it
## past the max shake and blur the screen indefinitely).
func add_trauma(amount: float) -> void:
	_trauma = clamp(_trauma + amount, 0.0, 1.0)

## Brief FOV punch: kicks the FOV by fov_delta then eases back to base over
## duration. Negative = dramatic zoom-in (ultimate cast); positive = zoom-out
## "punch" (a heavy landed hit).
func punch_zoom(fov_delta: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(camera, "fov", _base_fov + fov_delta, duration * 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "fov", _base_fov, duration * 0.7)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _process_shake(delta: float) -> void:
	_trauma = max(_trauma - trauma_decay_per_second * delta, 0.0)
	var shake: float = _trauma * _trauma
	_noise_t += delta * shake_noise_speed
	camera.h_offset = _noise.get_noise_2d(_noise_t, 0.0) * max_shake_offset * shake
	camera.v_offset = _noise.get_noise_2d(_noise_t, 100.0) * max_shake_offset * shake
	camera.rotation.z = deg_to_rad(_noise.get_noise_2d(_noise_t, 200.0) * max_shake_rotation_degrees * shake)
