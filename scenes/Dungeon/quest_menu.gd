extends Control

@onready var quest_node_container = $VBoxContainer

var quest_menu_node = "res://scenes/Dungeon/Quest_Menu_Node.tscn"

func _setup(p_ref):
	for quest_ in GlobalCombatInformation.active_quests:
		if quest_.dungeon_location != GlobalCombatInformation.selected_dungeon_:
			continue
		
		var new_quest_node = load(quest_menu_node)
		var new_quest_node_instance = new_quest_node.instantiate()
	
		new_quest_node_instance._setup(quest_)
		quest_node_container.add_child(new_quest_node_instance)
	GlobalCombatInformation.check_quest_progress.connect(update_quests)
	
func update_quests():
	for item: Items in GlobalCombatInformation.all_held_items:
		for quest_ in quest_node_container.get_children():
			quest_.update_quest_progress()
