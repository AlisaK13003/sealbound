extends Node2D

@export var active_combatants: Array[generic_combatants]
@export var current_dungeon_run: dungeon_type
@export var item_list: Array[Items]

func _on_area_2d_body_entered(body):
	if body.is_in_group("Overworld_Player"):
		await Fade.fade_in(1)
		await Fade.change_scene("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Dungeon_Select_Screen.tscn")
