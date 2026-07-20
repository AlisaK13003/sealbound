extends Control

@onready var menu_tabs = $Quest_Container/Panel/MenuTabs
@onready var quest_selection_tabs = $MenuTabs
@onready var completed_quest_tabs = $Quest_Container/Panel2/MenuTabs2
@onready var quest_description_container = $Quest_Description_Container
@onready var completed_quest_description_container = $Quest_Description_Container2
@onready var scroll_bar = $VScrollBar

@onready var quest_container = $Quest_Container

var quest_menu_node = "res://assets/Resources/Pause Menu/Quest Menu/Quest_Menu_Node.tscn"
var quest_description_node = "res://assets/Resources/Pause Menu/Quest Menu/Quest_Overview.tscn"

var container_start_position: Vector2

var active_quest_container: Node
var active_desc_container: Node

var current_item = 0
var current_slot = 0
var scroll_cooldown_timer: float = 0.0
const SCROLL_COOLDOWN_TIME: float = 0.08
var can_scroll: bool = false

func _ready():
	active_quest_container = menu_tabs
	active_desc_container = quest_description_container

	var all_active_quest_names: Array[String] = []
	var completed_quest_names: Array[String] = []
	
	container_start_position = menu_tabs.position
	
	for quest_: quest in GlobalCombatInformation.active_quests:
		all_active_quest_names.append(quest_.quest_name)

	for quest_: quest in GlobalCombatInformation.completed_quests:
		completed_quest_names.append(quest_.quest_name)
	
	completed_quest_tabs._setup(completed_quest_names, quest_menu_node)
	menu_tabs._setup(all_active_quest_names, quest_menu_node)
	quest_selection_tabs._setup(["Active Quests", "Completed Quests"])
	
	for child in range(GlobalCombatInformation.active_quests.size()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.active_quests[child])
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		
		quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.active_quests[child])
	
	for child in range(GlobalCombatInformation.completed_quests.size()):
		completed_quest_tabs.get_child(child)._setup(GlobalCombatInformation.completed_quests[child].duplicate())
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		
		completed_quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.completed_quests[child].duplicate(), true)

	GlobalCombatInformation.check_quest_progress.connect(update_quests)
	menu_tabs.selection_changed.connect(tab_changed)
	completed_quest_tabs.selection_changed.connect(tab_changed) 
	quest_selection_tabs.selection_changed.connect(quest_type_type_changed)
	visibility_changed.connect(_reset)
	
	for child in quest_container.get_children():
		child.selection_updated.connect(tab_changed)
		child._setup()
		for child_ in child.get_children():
			if child_ == null or child_.get_child_count() == 0:
				break
			if child_.get_child(0) != null:
				if child_.get_child(0).get_index() == 0:
					child_.get_child(0).highlight(true)
				else:
					child_.get_child(0).highlight(false)
		child.disable()
		
	quest_type_type_changed(0)
	_reset()

func update_quests():
	for child in quest_description_container.get_children():
		quest_description_container.remove_child(child)
		child.queue_free()
	for child in menu_tabs.get_children():
		menu_tabs.remove_child(child)
		child.queue_free()
		
	for child in completed_quest_description_container.get_children():
		completed_quest_description_container.remove_child(child)
		child.queue_free()
	for child in completed_quest_tabs.get_children():
		completed_quest_tabs.remove_child(child)
		child.queue_free()
		
	var all_active_quest_names: Array[String] = []
	var completed_quest_names: Array[String] = []

	for quest_: quest in GlobalCombatInformation.active_quests:
		all_active_quest_names.append(quest_.quest_name)
	
	for quest_: quest in GlobalCombatInformation.completed_quests:
		completed_quest_names.append(quest_.quest_name)
	
	completed_quest_tabs._setup(completed_quest_names, quest_menu_node)
	menu_tabs._setup(all_active_quest_names, quest_menu_node)
		
	for child in range(GlobalCombatInformation.active_quests.size()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.active_quests[child])
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		if child != 0:
			new_description_instance.visible = false
		quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.active_quests[child])
	
	for child in range(GlobalCombatInformation.completed_quests.size()):
		completed_quest_tabs.get_child(child)._setup(GlobalCombatInformation.completed_quests[child])
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		if child != 0:
			new_description_instance.visible = false
		completed_quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.completed_quests[child], true)

func _reset():
	set_process_input(visible)
	set_process_unhandled_input(visible)
	set_process(visible)

	if is_visible_in_tree():
		can_scroll = true
		update_quests()
		quest_container.get_child(0).enable()
		return
	else:
		can_scroll = false
		for child in quest_container.get_children():
			child.disable()
			
	menu_tabs.cycle_input(null, -1000)
	completed_quest_tabs.cycle_input(null, -1000)
	quest_selection_tabs.cycle_input(null, -10)
	quest_type_type_changed(0) 

func tab_changed(which_tab):
	if not active_desc_container:
		return
	for child in range(active_desc_container.get_child_count()):
		if which_tab == child:
			active_desc_container.get_child(child).visible = true
			quest_container.get_child(0).current_item = child
			quest_container.get_child(1).current_item = child
			#quest_container.get_child(0).update_selected_item()
			#quest_container.get_child(1).update_selected_item()
			current_item = which_tab
		else:
			active_desc_container.get_child(child).visible = false

func quest_type_type_changed(which_tab):
	current_item = 0
	current_slot = 0

	$Quest_Container/Panel.current_item = 0
	$Quest_Container/Panel2.current_item = 0

	$Quest_Container/Panel.update_selected_item()
	$Quest_Container/Panel2.update_selected_item()

	match which_tab:
		0: # Active Quests
			active_quest_container = menu_tabs
			active_desc_container = quest_description_container
			
			quest_description_container.visible = true
			completed_quest_description_container.visible = false
			quest_container.get_child(0).enable()
			quest_container.get_child(0).current_item = 0
			quest_container.get_child(0).update_selected_item()
			quest_container.get_child(1).disable()
			quest_container.get_child(0).update_scroll_bar()
		1: # Completed Quests
			active_quest_container = completed_quest_tabs
			active_desc_container = completed_quest_description_container
			
			quest_description_container.visible = false
			completed_quest_description_container.visible = true
			quest_container.get_child(1).enable()
			quest_container.get_child(1).current_item = 0
			quest_container.get_child(1).update_selected_item()
			quest_container.get_child(0).disable()
			quest_container.get_child(1).update_scroll_bar()


	menu_tabs.position.y = container_start_position.y
	completed_quest_tabs.position.y = container_start_position.y

	scroll_bar.max_value = max(0, active_quest_container.get_child_count() - 6)
	scroll_bar.value = 0
	
	#update_selected_item()


func update_selected_item():
	if not active_quest_container:
		return
	for child in active_quest_container.get_children():
		if child.get_index() == current_item:
			child.highlight(true)
			tab_changed(child.get_index())
		else:
			child.highlight(false)
