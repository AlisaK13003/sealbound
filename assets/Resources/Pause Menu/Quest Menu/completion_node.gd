extends Control

func _setup(goal, completion_requirements):
	var texture_re = $HBoxContainer/TextureRect
	var label = $HBoxContainer/Label
	var label_2 = $HBoxContainer/Label2
	
	if goal is generic_combatants:
		texture_re.texture = goal.quest_item_drop.item_sprite
		label.text = goal.quest_item_drop.item_name + ": "
		
		label_2.text = str(GlobalCombatInformation.search_for_item(goal.quest_item_drop)) + " / " + str(completion_requirements[goal])

	elif goal is Items:
		texture_re = goal.item_sprite
		label.text = goal.item_name + ": "
		
		label_2.text = str(GlobalCombatInformation.search_for_item(goal.quest_item_drop)) + " / " + str(completion_requirements[goal])
