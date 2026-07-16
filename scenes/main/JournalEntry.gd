extends Node2D
class_name JournalEntry

@export_multiline var book_text: String = ""

var player_in_range := false

func _input(event):
	if Global.is_in_menu:
		return
	if not player_in_range:
		return
	if Global.get_input_mapping("confirm") or event.is_action_pressed("Mouse_Right_Click"):
		Global.show_mc_thought(book_text)

# Player has BOTH a body and an Area2D in this group — mirror how NPCs detect range
func _on_area_2d_body_entered(body):
	if body.is_in_group("Overworld_Player"):
		player_in_range = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("Overworld_Player"):
		player_in_range = false

func _on_area_2d_area_entered(area):
	if area.is_in_group("Overworld_Player"):
		player_in_range = true

func _on_area_2d_area_exited(area):
	if area.is_in_group("Overworld_Player"):
		player_in_range = false
