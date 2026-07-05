extends Control

var quest_name: Label

var completion_requirements: GridContainer
var dungeon_background: TextureRect
var quest_description: Label
var requestor_sprite: Sprite2D

func _setup(quest_: quest):
	quest_name = $Quest_Name
	completion_requirements = $GridContainer
	dungeon_background = $TextureRect
	quest_description = $Label
	requestor_sprite = $Sprite2D
	
	quest_name.text = quest_.quest_name
	
	dungeon_background.texture = GlobalCombatInformation.dungeon_types[quest_.dungeon_location].dungeon_background
	
	quest_description.text = quest_.quest_giver + ": " + quest_.quest_description

	requestor_sprite.texture = quest_.quest_giver_sprite
	
	for goal in quest_.completion_requirements.keys():
		var completion_node = load("res://assets/Resources/Pause Menu/Quest Menu/Completion_Node.tscn")
		
		var completion_instance = completion_node.instantiate()
		
		completion_requirements.add_child(completion_instance)
		
		completion_instance._setup(goal, quest_.completion_requirements)
	

		
