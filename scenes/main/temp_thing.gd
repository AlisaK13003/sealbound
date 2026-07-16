extends Node2D

@export var active_combatants: Array[generic_combatants]
@export var current_dungeon_run: dungeon_type
@export var item_list: Array[Items]

func _on_area_2d_body_entered(body):
	if body.is_in_group("Overworld_Player"):
		if not StateManager.check_completion(StateManager.story_beats_lookup.ACCEPTED_QUEST_FOR_LYRA_AXE, StateManager.completion_checks.STORY_CHECKS):
			Global.show_mc_thought(Global.LYRA_FIRST_OBJECTIVE_TEXT)
			return
		await Fade.fade_in(1)
		GlobalCombatInformation.in_dungeon = true
		await Fade.change_scene("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Dungeon_Select_Screen.tscn")
