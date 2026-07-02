extends Control

@export var custom_tab_path: String
@onready var menu_tabs = $MenuTabs
@onready var card_container = $Card_Container

var equipment_card_path: String = "res://assets/Resources/Pause Menu/Equipm Menu/Equipment_Card.tscn"

func _ready():
	visibility_changed.connect(_reset)
	menu_tabs._setup(GlobalCombatInformation.active_party_slots, custom_tab_path)
	
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.active_party_slots[child])
		
		var new_page = load(equipment_card_path)
		var new_page_instance = new_page.instantiate()
		new_page_instance._setup(GlobalCombatInformation.all_party_slots[child])
		
		card_container.add_child(new_page_instance)
		
	menu_tabs.selection_changed.connect(tab_changed)
	menu_tabs.cycle_input(null, 0)

func _reset():
	menu_tabs.cycle_input(null, -10)

func tab_changed(which_tab):
	print("TAB CHANGED")
	for child in range(card_container.get_child_count()):
		if which_tab == child:
			card_container.get_child(child).visible = true
			#if child != 0:
			#	bond_page.visible = true
			#	bond_page._setup(GlobalCombatInformation.all_party_slots[child].combatant_name.to_lower())
			#else:
			#	bond_page.visible = false
		else:
			card_container.get_child(child).visible = false
		
