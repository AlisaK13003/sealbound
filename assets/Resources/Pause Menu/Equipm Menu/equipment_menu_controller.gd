extends Control

@export var custom_tab_path: String
@onready var menu_tabs = $MenuTabs
@onready var card_container = $Card_Container

@onready var equip_swap_label = $Label

var equipment_card_path: String = "res://assets/Resources/Pause Menu/Equipm Menu/Equipment_Card.tscn"

var container_start_position: Vector2

func _ready():
	container_start_position = $Container2/Container.position
	$VScrollBar.visible = false
	visibility_changed.connect(_reset)
	menu_tabs._setup(GlobalCombatInformation.all_party_slots, custom_tab_path)
	
	for child in range(menu_tabs.get_child_count()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.all_party_slots[child], child)
		
		var new_page = load(equipment_card_path)
		var new_page_instance = new_page.instantiate()
		new_page_instance._setup(GlobalCombatInformation.all_party_slots[child])
		
		new_page_instance.equip_slot_pressed.connect(show_equip_menu)
		
		card_container.add_child(new_page_instance)
	
	for child in $Container2/Container.get_children():
		child._setup()
		child.equipment_swapped.connect(_setup_equip_button)
	
	menu_tabs.selection_changed.connect(tab_changed)
	menu_tabs.cycle_input(null, 0)
	
func _reset():
	menu_tabs.cycle_input(null, -10)

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
				$VScrollBar.max_value = container.get_child(visible_menu).get_child_count() - 5
				if container.get_child(visible_menu).get_child_count() > 5:
					$VScrollBar.visible 
					
@onready var container = $Container2/Container
func equipment_equipped(equipped_equipment):
	var is_weapon = false if equipped_equipment is equipment else true
	var unequipped = GlobalCombatInformation.add_equipment(menu_tabs.current_selection, equipped_equipment, is_weapon)
	#$Card_Container.get_child(menu_tabs.current_selection).update_boxes(equipped_equipment, is_weapon)

	if is_weapon:
		container.get_child(0).update_contents(unequipped)
	else:
		match equipped_equipment.equipment_type:
			# Helmet
			0:
				container.get_child(1).update_contents(unequipped)
			# Chestplate
			1:
				container.get_child(4).update_contents(unequipped)
			# Boots
			2:
				container.get_child(2).update_contents(unequipped)
			# Charm
			3:
				container.get_child(3).update_contents(unequipped)
	
func show_equip_menu(which_menu):
	if which_menu == visible_menu:
		visible_menu = -1
		equip_swap_label.text = ""
		$VScrollBar.visible = false
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

	for child in $Container2/Container.get_children():
		if child.get_index() == visible_menu:
			child.visible = true
			$VScrollBar.max_value = child.get_child_count() - 6
			$VScrollBar.value = 0
			if child.get_child_count() > 5:
				$VScrollBar.visible = true
		else:
			child.visible = false

func tab_changed(which_tab):
	for child in range(card_container.get_child_count()):
		if which_tab == child:
			card_container.get_child(child).visible = true
			$VScrollBar.max_value = card_container.get_child(child).get_child_count() - 6
			$VScrollBar.value = 0
			if card_container.get_child(child).get_child_count() > 5:
				$VScrollBar.visible 
		else:
			card_container.get_child(child).visible = false
var current_slot = 0
@onready var scroll_bar = $VScrollBar

var scroll_cooldown_timer: float = 0.0
const SCROLL_COOLDOWN_TIME: float = 0.08

func _process(delta: float):
	if not Global.is_paused:
		return
	if scroll_cooldown_timer > 0.0:
		scroll_cooldown_timer -= delta

func _on_v_scroll_bar_value_changed(value):
	if $Container2/Container.get_child_count() == 0:
		return
	if $Container2/Container.get_child(visible_menu).get_child_count() == 0:
		return
	print(value)
	$Container2/Container.position.y = container_start_position.y - (value * $Container2/Container.get_child(0).get_theme_constant("v_separation"))

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if not can_scroll:
			return
			
		if scroll_cooldown_timer > 0.0:
			return
			
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_slot = clamp(current_slot - 1, 0, scroll_bar.max_value + 1)
			scroll_bar.value = current_slot
			scroll_cooldown_timer = SCROLL_COOLDOWN_TIME
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_slot = clamp(current_slot + 1, 0, scroll_bar.max_value + 1)
			scroll_bar.value = current_slot
			scroll_cooldown_timer = SCROLL_COOLDOWN_TIME
			get_viewport().set_input_as_handled()
			
var can_scroll: bool = false
func _on_area_2d_mouse_entered():
	can_scroll = true

func _on_area_2d_mouse_exited():
	can_scroll = false
