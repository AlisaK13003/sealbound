extends Area3D

@export var lock_x_camera_movement: bool = false
@export var lock_y_camera_movement: bool = true
@export var lock_z_camera_movement: bool = false

var p_ref: explorable_dungeon

func _setup(parent_reference):
	p_ref = parent_reference

func _on_body_entered(body):
	if body.is_in_group("3D_Player"):
		p_ref.zone_changed.emit(lock_x_camera_movement, lock_y_camera_movement, lock_z_camera_movement)
