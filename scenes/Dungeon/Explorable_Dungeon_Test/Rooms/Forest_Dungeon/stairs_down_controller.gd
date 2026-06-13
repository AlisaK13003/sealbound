extends Node3D

signal go_down_floor

func _on_area_3d_body_entered(body):
	if body.is_in_group("3D_Player"):
		go_down_floor.emit()
		print("ENTERED")
