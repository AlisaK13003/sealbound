extends Control

var quest_name: Label
var completion_requirements: GridContainer
var quest_description: Label
var requestor_sprite: Sprite2D

var complation_status: Label

func _setup(quest_: quest, is_completed: bool = false):
	quest_name = $Quest_Name
	completion_requirements = $GridContainer
	quest_description = $Label
	requestor_sprite = $Sprite2D
	complation_status = $Label3
	
	quest_name.text = quest_.quest_name
	
	quest_description.text = quest_.quest_giver + ": " + quest_.quest_description

	requestor_sprite.texture = quest_.quest_giver_sprite
	
	var all_things_satisfied: bool = true
	if quest_.item_to_drop == null:
		for goal in quest_.completion_requirements.keys():
			var completion_node = load("res://assets/Resources/Pause Menu/Quest Menu/Completion_Node.tscn")
			
			var completion_instance = completion_node.instantiate()
			
			completion_requirements.add_child(completion_instance)
			
			completion_instance._setup(goal, quest_.completion_requirements)
			
			var count = GlobalCombatInformation.search_for_item_count(goal.quest_item_drop.item_name)
			if count < quest_.completion_requirements[goal]:
				all_things_satisfied = false
			
	else:
		var completion_node = load("res://assets/Resources/Pause Menu/Quest Menu/Completion_Node.tscn")
		var completion_instance = completion_node.instantiate()
		completion_requirements.add_child(completion_instance)
		completion_instance._setup(quest_.item_to_drop)
		
		var count = GlobalCombatInformation.search_for_item_count(quest_.item_to_drop.item_name)
		if count < 1:
			all_things_satisfied = false
	if not is_completed:
		if all_things_satisfied:
			complation_status.text = quest_.ready_to_turn_in_string
		else:
			complation_status.text = "Missing Required Items"
	else:
		complation_status.text = "Completed"

		
