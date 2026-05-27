extends Node2D

@export var active_combatants: Array[generic_combatants]
@export var current_dungeon_run: dungeon_type
@export var item_list: Array[Items]

func _on_area_2d_body_entered(body):
	if body.is_in_group("Overworld_Player"):
		GlobalCombatInformation.transition_to_dungeon.call_deferred(
			active_combatants, 
			current_dungeon_run, 
			item_list
		)
