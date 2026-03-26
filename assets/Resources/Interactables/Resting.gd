extends Node2D

# Basic resting, advances day without passing out
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("Mouse_Right_Click"):
		Global.player_advanced_day(false)
		get_tree().reload_current_scene()
