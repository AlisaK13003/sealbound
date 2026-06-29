extends Control


func _setup(quest_to_setup_with: quest):
	var quest_name = $VBoxContainer/Quest_Name
	var quest_description = $VBoxContainer/MarginContainer/Quest_Description
	var quest_requirement_area = $VBoxContainer/MarginContainer/Quest_Completion/VBoxContainer
	
	quest_name.text = quest_to_setup_with.quest_name
	quest_description.text = quest_to_setup_with.quest_description
	if quest_to_setup_with.should_spawn_dungeon_room:
		pass
	else:
		for thing in quest_to_setup_with.completion_requirements.keys():
			if thing is Items:
				var new_label = Label.new()
				new_label.text = thing.item_name + ": " + quest_to_setup_with.completion_requirements[thing]
			elif thing is generic_combatants:
				var new_label = Label.new()
				new_label.text = thing.quest_item_drop.item_name + ": " + str(quest_to_setup_with.completion_requirements[thing])
				quest_requirement_area.add_child(new_label)
