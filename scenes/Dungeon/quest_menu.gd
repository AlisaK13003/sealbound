extends Control

#@onready var quest_node_container = $GridContainer

@onready var menu_tabs = $MenuTabs
@onready var quest_description_container = $Quest_Description_Container

var quest_menu_node = "res://assets/Resources/Pause Menu/Quest Menu/Quest_Menu_Node.tscn"
var quest_description_node = "res://assets/Resources/Pause Menu/Quest Menu/Quest_Overview.tscn"

func _ready():
	var all_active_quest_names: Array[String] = []
	
	for quest_: quest in GlobalCombatInformation.active_quests:
		all_active_quest_names.append(quest_.quest_name)
		
	menu_tabs._setup(all_active_quest_names, quest_menu_node)
	
	for child in range(GlobalCombatInformation.active_quests.size()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.active_quests[child])
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		
		quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.active_quests[child])
	
	for quest_ in GlobalCombatInformation.active_quests:
		var new_quest_node = load(quest_menu_node)
		var new_quest_node_instance = new_quest_node.instantiate()
	
		new_quest_node_instance._setup(quest_)
		#quest_node_container.add_child(new_quest_node_instance)
	GlobalCombatInformation.check_quest_progress.connect(update_quests)
	menu_tabs.selection_changed.connect(tab_changed)
	_reset()
	
	visibility_changed.connect(_reset)
	
func update_quests():
	for child in quest_description_container.get_children():
		quest_description_container.remove_child(child)
		child.queue_free()
	for child in menu_tabs.get_children():
		menu_tabs.remove_child(child)
		child.queue_free()
		
	var all_active_quest_names: Array[String] = []
	
	for quest_: quest in GlobalCombatInformation.active_quests:
		all_active_quest_names.append(quest_.quest_name)
		
	menu_tabs._setup(all_active_quest_names, quest_menu_node)
		
	for child in range(GlobalCombatInformation.active_quests.size()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.active_quests[child])
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		
		quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.active_quests[child])
	
	#for quest_ in GlobalCombatInformation.active_quests:
	#	var new_quest_node = load(quest_menu_node)
	#	var new_quest_node_instance = new_quest_node.instantiate()
	#
	#	new_quest_node_instance._setup(quest_)

	menu_tabs.cycle_input(null, 0)

func _reset():
	menu_tabs.cycle_input(null, -10)

func tab_changed(which_tab):
	for child in range(quest_description_container.get_child_count()):
		if which_tab == child:
			quest_description_container.get_child(child).visible = true
		else:
			quest_description_container.get_child(child).visible = false
		
