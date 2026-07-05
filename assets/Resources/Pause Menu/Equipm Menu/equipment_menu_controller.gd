extends Control

@export var custom_tab_path: String
@onready var menu_tabs = $MenuTabs
@onready var card_container = $Card_Container

@onready var equip_swap_label = $Label

var equipment_card_path: String = "res://assets/Resources/Pause Menu/Equipm Menu/Equipment_Card.tscn"

func _ready():
	visibility_changed.connect(_reset)
	menu_tabs._setup(GlobalCombatInformation.active_party_slots, custom_tab_path)
	
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.active_party_slots[child])
		
		var new_page = load(equipment_card_path)
		var new_page_instance = new_page.instantiate()
		new_page_instance._setup(GlobalCombatInformation.all_party_slots[child])
		
		new_page_instance.equip_slot_pressed.connect(show_equip_menu)
		
		card_container.add_child(new_page_instance)
	
	for child in $Container.get_children():
		child._setup()
		child.equipment_swapped.connect(equipment_equipped)
	
	menu_tabs.selection_changed.connect(tab_changed)
	menu_tabs.cycle_input(null, 0)
	
func _reset():
	menu_tabs.cycle_input(null, -10)

var visible_menu

func equipment_equipped(equipped_equipment):
	var is_weapon = false if equipped_equipment is equipment else true
	var unequipped = GlobalCombatInformation.add_equipment(menu_tabs.current_selection, equipped_equipment, is_weapon)
	
	$Card_Container.get_child(menu_tabs.current_selection).update_boxes(equipped_equipment, is_weapon)

	if is_weapon:
		$Container.get_child(0).update_contents(unequipped)
	else:
		match equipped_equipment.equipment_type:
			# Helmet
			0:
				$Container.get_child(1).update_contents(unequipped)
			# Chestplate
			1:
				$Container.get_child(4).update_contents(unequipped)
			# Boots
			2:
				$Container.get_child(2).update_contents(unequipped)
			# Charm
			3:
				$Container.get_child(3).update_contents(unequipped)
	
func show_equip_menu(which_menu):
	if which_menu == visible_menu:
		visible_menu = -1
		equip_swap_label.text = ""
	else:
		match which_menu:
			# Weapon Slot
			0:
				visible_menu = 0
				equip_swap_label.text = "Weapons"
			# Helmet Slot
			1:
				visible_menu = 1
				equip_swap_label.text = "Helmets"
			# Boots slot
			2:
				visible_menu = 2
				equip_swap_label.text = "Boots"
			# Charm slot
			3:
				visible_menu = 3
				equip_swap_label.text = "Charms"
			# Chestplate slot
			4:
				visible_menu = 4
				equip_swap_label.text = "Chestplates"

	for child in $Container.get_children():
		if child.get_index() == visible_menu:
			child.visible = true
		else:
			child.visible = false

func tab_changed(which_tab):
	
	print("TAB CHANGED")
	for child in range(card_container.get_child_count()):
		if which_tab == child:
			card_container.get_child(child).visible = true

		else:
			card_container.get_child(child).visible = false
		
