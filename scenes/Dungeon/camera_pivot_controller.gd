extends Node3D

@export var mouse_sensitivity: float = 0.15
@export var lerp_speed: float = 10.0 # Higher is faster, lower is smoother

@export var follow_speed: float = 1.0
@export var pivot_height_offset: float = 1.5

@export var player: CharacterBody3D
@onready var camera: Camera3D = $Camera3D

# Target rotations (where the mouse wants the camera to look)
var target_yaw: float = 0.0
var target_pitch: float = 0.0

# Actual smoothed camera angles
var current_yaw: float = 0.0
var current_pitch: float = 0.0

func _ready() -> void:
	# Lock the mouse in the center of the screen
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Initialize starting values
	target_yaw = rotation_degrees.y
	target_pitch = camera.rotation_degrees.x
	current_yaw = target_yaw
	current_pitch = target_pitch

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

		target_yaw -= event.relative.x * mouse_sensitivity
		target_pitch -= event.relative.y * mouse_sensitivity
		
		target_pitch = clamp(target_pitch, -85.0, 85.0)

func _process(delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		current_yaw = lerp(current_yaw, target_yaw, lerp_speed * delta)
		#current_pitch = lerp(current_pitch, target_pitch, lerp_speed * delta)
		
		rotation_degrees.y = wrapf(current_yaw, 0, 360)
		#camera.rotation_degrees.x = current_pitch
		
func _physics_process(delta):
	return
	if not player: return

	# 1. Instantly follow the player's position
	global_position = player.global_position + Vector3(0, pivot_height_offset, 0)
	
	# 2. Smoothly rotate the pivot's Y-axis toward the target_yaw
	global_rotation.y = lerp_angle(global_rotation.y, deg_to_rad(target_yaw), delta * follow_speed)
