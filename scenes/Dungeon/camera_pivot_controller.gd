extends Node3D

@export var mouse_sensitivity: float = 0.15
@export var lerp_speed: float = 10.0 


@onready var camera: Camera3D = $Camera3D

var target_yaw: float = 0.0
var target_pitch: float = 0.0

var current_yaw: float = 0.0
var current_pitch: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	target_yaw = rotation_degrees.y
	#target_pitch = camera.rotation_degrees.x
	current_yaw = target_yaw
	#current_pitch = target_pitch

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		target_yaw -= event.relative.x * mouse_sensitivity
		#target_pitch -= event.relative.y * mouse_sensitivity
		
		#target_pitch = clamp(target_pitch, -85.0, 85.0)

func _process(delta: float) -> void:
	if camera.player.p_ref.movement_locked:
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		current_yaw = lerp(current_yaw, target_yaw, lerp_speed * delta)
		#current_pitch = lerp(current_pitch, target_pitch, lerp_speed * delta)
		
		rotation_degrees.y = wrapf(current_yaw, 0, 360)
		#camera.rotation_degrees.x = current_pitch
