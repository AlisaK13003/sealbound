extends Control

@export var custom_tab_path: String
@onready var menu_tabs = $MenuTabs
@onready var card_container = $Card_Container

@onready var equip_swap_label = $Label

@onready var list_container = $Control

var equipment_card_path: String = "res://assets/Resources/Pause Menu/Equipm Menu/Equipment_Card.tscn"

var container_start_position: Vector2

@export var equip_sounds_equipment: Array[AudioStream]
@export var equip_sounds_weapon: Array[AudioStream]

func _ready():
	visibility_changed.connect(_reset)
	menu_tabs._setup(GlobalCombatInformation.all_party_slots, custom_tab_path)
	
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.all_party_slots[child], child)
		
		var new_page = load(equipment_card_path)
		var new_page_instance = new_page.instantiate()
		new_page_instance._setup(GlobalCombatInformation.all_party_slots[child])
		
		new_page_instance.equip_slot_pressed.connect(show_equip_menu)
		
		card_container.add_child(new_page_instance)
	
	for child in list_container.get_children():
		child.get_child(0)._setup()
		child.get_child(0).equipment_swapped.connect(_setup_equip_button)
	
	menu_tabs.selection_changed.connect(tab_changed)
	menu_tabs.cycle_input(null, 0)
	
	for child in list_container.get_children():
		child._setup()
		child.visible = false

	
func _reset(should_continue_cycling: bool = true):
	if should_continue_cycling:
		menu_tabs.cycle_input(null, -1000)
	for child in card_container.get_children():
		child._reset()
	
	for child in list_container.get_children():
		child.visible = false
	
	$TextureRect/TextureRect.visible = false
	$TextureRect/Label.visible = false
	$TextureRect/Label2.visible = false
	$Panel.visible = false
	$Label.text = ""
	visible_menu = -1

	for child in list_container.get_children():
		for child_ in child.get_child(0).get_children():
			if child_.get_index() == 0:
				child_.highlight(true)
			else:
				child_.highlight(false)

var visible_menu

var equip_button_disabled: bool = true
var limbo_equipment

func _setup_equip_button(selected_equipment):
	var is_weapon = false if selected_equipment is equipment else true

	$TextureRect/TextureRect.visible = true
	$TextureRect/Label.visible = true
	$TextureRect/Label2.visible = true
	$Panel.visible = true

	if is_weapon:
		$TextureRect/TextureRect.texture = selected_equipment.weapon_texture
		$TextureRect/Label.text = selected_equipment.weapon_name
		$TextureRect/Label2.text = selected_equipment.weapon_description
	else:
		$TextureRect/TextureRect.texture = selected_equipment.equipment_sprite
		$TextureRect/Label.text = selected_equipment.equipment_name
		$TextureRect/Label2.text = selected_equipment.equipment_description
		
	card_container.get_child(menu_tabs.current_selection).update_prediction_stats(selected_equipment, is_weapon)
		
	limbo_equipment = selected_equipment
	equip_button_disabled = false

func _equip_button_pressed(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not equip_button_disabled:
				equip_button_disabled = true
				equipment_equipped(limbo_equipment)
				
				$TextureRect/TextureRect.visible = false
				$TextureRect/Label.visible = false
				$TextureRect/Label2.visible = false
				$Panel.visible = false
				card_container.get_child(menu_tabs.current_selection).update_prediction_stats(null, false)
					
func equipment_equipped(equipped_equipment):
	var is_weapon = false if equipped_equipment is equipment else true
	var unequipped = GlobalCombatInformation.add_equipment(menu_tabs.current_selection, equipped_equipment, is_weapon)
	#$Card_Container.get_child(menu_tabs.current_selection).update_boxes(equipped_equipment, is_weapon)
	if is_weapon:
		AudioManager.play_ui_sound(equip_sounds_weapon.pick_random())

		list_container.get_child(0).get_child(0).update_contents(unequipped)
		list_container.get_child(0).update_selected_item()
	else:
		AudioManager.play_ui_sound(equip_sounds_equipment.pick_random())

		match equipped_equipment.equipment_type:
			# Helmet
			0:
				list_container.get_child(1).get_child(0).update_contents(unequipped)
				list_container.get_child(1).update_selected_item()
			# Chestplate
			1:
				list_container.get_child(4).get_child(0).update_contents(unequipped)
				list_container.get_child(4).update_selected_item()
			# Boots
			2:
				list_container.get_child(2).get_child(0).update_contents(unequipped)
				list_container.get_child(2).update_selected_item()
			# Charm
			3:
				list_container.get_child(3).get_child(0).update_contents(unequipped)
				list_container.get_child(3).update_selected_item()
	
func show_equip_menu(which_menu):
	$TextureRect/TextureRect.visible = false
	$TextureRect/Label.visible = false
	$TextureRect/Label2.visible = false
	$Panel.visible = false
	_reset(false)
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

	for child in list_container.get_children():
		if child.get_index() == visible_menu:
			child.visible = true
			child.update_scroll_bar()
		else:
			child.visible = false
		child.update_selection()

func tab_changed(which_tab):
	_reset(false)
	for child in range(card_container.get_child_count()):
		if which_tab == child:
			card_container.get_child(child).visible = true
		else:
			card_container.get_child(child).visible = false

func disable():
	for child in list_container.get_children():
		child.disable()

func enable():
	for child in list_container.get_children():
		child.enable()
		child.visible = false
