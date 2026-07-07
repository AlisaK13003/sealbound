extends Control

@export var custom_tab_path: String
@onready var menu_tabs = $MenuTabs

@onready var stat_pages = $Stat_Pages
@onready var bond_page = $BondMenu

var stat_page: String = "res://assets/Resources/Pause Menu/Party Menu/Party_Menu_Stat_Card.tscn"

func _ready():
	visibility_changed.connect(_reset)
	menu_tabs._setup(GlobalCombatInformation.all_party_slots, custom_tab_path)
	
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.all_party_slots[child], child)
		
		var new_page = load(stat_page)
		var new_page_instance = new_page.instantiate()
		new_page_instance._setup(GlobalCombatInformation.all_party_slots[child])
		
		stat_pages.add_child(new_page_instance)
		
	menu_tabs.selection_changed.connect(tab_changed)
	menu_tabs.cycle_input(null, 0)
	GlobalCombatInformation.check_player_values.connect(_stats_changed)
	
var is_updating_stats: bool = false
	
func _stats_changed():
	if is_updating_stats: 
		return
	is_updating_stats = true
	var previous_selection = menu_tabs.current_selection
	
	for child in stat_pages.get_children():
		stat_pages.remove_child(child)
		child.queue_free()

	for child in menu_tabs.get_children():
		menu_tabs.remove_child(child)
		child.queue_free()

	menu_tabs._setup(GlobalCombatInformation.all_party_slots, custom_tab_path)
	
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.all_party_slots[child], child)
		
		var new_page = load(stat_page)
		var new_page_instance = new_page.instantiate()
		new_page_instance._setup(GlobalCombatInformation.all_party_slots[child])
		
		stat_pages.add_child(new_page_instance)
		
	#menu_tabs.selection_changed.connect(tab_changed)
	menu_tabs.cycle_input(null, previous_selection)
	is_updating_stats = false
#0.644
var is_resetting: bool = false
func _reset():
	if is_resetting:
		return
	is_resetting = true
	menu_tabs.cycle_input(null, -10)
	is_resetting = false
	
func tab_changed(which_tab):
	for child in range(stat_pages.get_child_count()):
		if which_tab == child:
			stat_pages.get_child(child).visible = true
			if child != 0:
				bond_page.visible = true
				bond_page._setup(GlobalCombatInformation.all_party_slots[child].combatant_name.to_lower())
			else:
				bond_page.visible = false
		else:
			stat_pages.get_child(child).visible = false
		
