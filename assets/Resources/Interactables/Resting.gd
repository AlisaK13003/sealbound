extends Node2D

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("Mouse_Right_Click"):
		Global.player_advanced_day(false)
