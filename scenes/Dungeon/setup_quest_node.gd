extends Control

var held_quest

var quest_requirement_area

func _setup(quest_to_setup_with: quest):
	var quest_name = $VBoxContainer/Quest_Name
	var quest_description = $VBoxContainer/MarginContainer/Quest_Description
	quest_requirement_area = $VBoxContainer/MarginContainer/Quest_Completion/VBoxContainer
	var quest_container = $VBoxContainer/MarginContainer

	held_quest = quest_to_setup_with
	
	quest_name.text = quest_to_setup_with.quest_name
	quest_description.text = quest_to_setup_with.quest_description
	if quest_to_setup_with.should_spawn_dungeon_room:
		quest_container.add_theme_constant_override("margin_top", -8)
	else:
		quest_container.add_theme_constant_override("margin_top", -14)
	if not quest_to_setup_with.completion_requirements.keys().is_empty():
		update_quest_progress()
	GlobalCombatInformation.check_quest_progress.connect(update_quest_progress)
	
func update_quest_progress():
	for child in quest_requirement_area.get_children():
		child.queue_free()

	if held_quest.completion_requirements.keys().is_empty():
		pass
	else:
		for thing in held_quest.completion_requirements.keys():
			if thing is Items:
				var new_label = Label.new()
				
				var item_count = 0
				for item: Items in GlobalCombatInformation.all_held_items:
					if item.item_name == thing.item_name:
						item_count += 1
				
				new_label.text = thing.item_name + ": " + str(item_count) + " / " + held_quest.completion_requirements[thing]
			elif thing is generic_combatants:
				var new_label = Label.new()
				
				var item_count = 0
				for item: Items in GlobalCombatInformation.all_held_items:
					if item.item_name == thing.quest_item_drop.item_name:
						item_count += 1
				
				new_label.text = thing.quest_item_drop.item_name + ": " + str(item_count) + " / " + str(held_quest.completion_requirements[thing])
				quest_requirement_area.add_child(new_label)
