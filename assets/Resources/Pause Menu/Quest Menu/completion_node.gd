extends Control

func _setup(goal, completion_requirements):
	var texture_re = $HBoxContainer/TextureRect
	var label = $HBoxContainer/Label
	var label_2 = $HBoxContainer/Label2
	
	if goal is generic_combatants:
		texture_re.texture = goal.quest_item_drop.item_sprite
		label.text = goal.quest_item_drop.item_name + ": "
		var item_in_inventory = GlobalCombatInformation.search_for_item_count(goal.quest_item_drop.item_name)
		label_2.text = str(item_in_inventory if item_in_inventory != null else "0") + " / " + str(completion_requirements[goal])

	elif goal is Items:
		texture_re = goal.item_sprite
		label.text = goal.item_name + ": "
		
		var item_in_inventory = GlobalCombatInformation.search_for_item_count(goal.item_name)
		
		label_2.text = str(item_in_inventory if item_in_inventory != null else "0" ) + " / " + str(completion_requirements[goal])
