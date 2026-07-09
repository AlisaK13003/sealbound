extends Control

var held_quest

var quest_requirement_area

func _ready():
	GlobalCombatInformation.check_quest_progress.connect(update_quest_progress)

func _setup(quest_to_setup_with: quest):
	var quest_name = $Quest_Name
	held_quest = quest_to_setup_with
	
	$AnimatedSprite2D.play("default")
	quest_name.text = quest_to_setup_with.quest_name
	
func update_highlight(highlight):
	if highlight:
		$AnimatedSprite2D.visible = true
	else:
		$AnimatedSprite2D.visible = false
	
func update_quest_progress():
	return
	print("HII")
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
