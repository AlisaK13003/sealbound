extends Control

@onready var armor_container = $Armor
@onready var weapon_container = $Weapons
@onready var party_cards = $Party_Cards
@onready var current_container = $Weapons
@onready var sub_menus = $Sub_menus

var item_scene = preload("res://assets/Resources/Pause Menu/Item Menu/Display_item.tscn")
var start_range = 0
var end_range = 7

var current_tab = 0
var selected_index = 0

@export var menu_parent : Control

var menu_choices = {
	"Weapons": 0,
	"Armor": 1,
}

func _ready():
	Global.save_loaded.connect(_on_game_start)

func _on_game_start():
	Global.item_list_updated.connect(update_menu)
	
	for child in sub_menus.get_children():
		child.option_selected.connect(tab_clicked)
	
	for armor_piece in Global.equipment_list:
		var new_item = item_scene.instantiate()
		new_item.setup(armor_piece)
		new_item.item_clicked.connect(display_item_clicked)
		armor_container.add_child(new_item)
	
	for actual_weapon in Global.weapon_list:
		var new_item = item_scene.instantiate()
		new_item.setup(actual_weapon)
		new_item.item_clicked.connect(display_item_clicked)
		weapon_container.add_child(new_item)
	
	setup_party_card(Global.party_slot_1, 0)
	setup_party_card(Global.party_slot_2, 1)
	setup_party_card(Global.party_slot_3, 2)
	update_display(0)

func tab_clicked(selected_tab):
	selected_index = 0
	match selected_tab:
		"Weapons":
			weapon_container.visible = true
			armor_container.visible = false
			current_container = weapon_container
			current_tab = 0
		"Armor":
			armor_container.visible = true
			weapon_container.visible = false
			current_container = armor_container
			current_tab = 1
	update_display(0)

func setup_party_card(member: PartyMember, which_thing):
	if party_cards.get_child(which_thing) == null:
		return
	var current_card = party_cards.get_child(which_thing)
	current_card.get_node("Sprite").texture = member.player_sprite
	current_card.get_node("Name").text = member.member_name
	current_card.get_node("Health").text = str(member.player_stats.health)

func _input(event):
	if menu_parent == null:
		return
	
	if menu_parent.current_menu == "Equipment":
		if event.is_action_pressed("Mouse Scroll Down"):
			update_display(1)
			
		if event.is_action_pressed("Mouse Scroll Up"):
			update_display(-1)

func update_display(change_range_by: int):
	var loop_bounds
	match current_tab:
		# Weapon
		0:
			current_container = weapon_container
			loop_bounds = Global.weapon_list.size()
		# Armor
		1:
			current_container = armor_container
			loop_bounds = Global.equipment_list.size()
	
	if selected_index == 0:
		start_range = 0
		end_range = clamp(end_range, start_range + 7, loop_bounds)
	
	if selected_index == end_range - 2 and change_range_by == 1:
		start_range = clamp(start_range + change_range_by, 0, loop_bounds - 7)
		end_range = clamp(end_range + change_range_by, start_range + 7, loop_bounds)
	elif selected_index == start_range + 1 and change_range_by == -1:
		start_range = clamp(start_range + change_range_by, 0, loop_bounds - 7)
		end_range = clamp(end_range + change_range_by, start_range + 7, loop_bounds)
	selected_index = clamp(selected_index + change_range_by, 0, loop_bounds - 1)

	for i in range(loop_bounds):
		if current_container.get_child(i) == null:
			return
		current_container.get_child(i).get_node("Panel")
		if i == selected_index:
			current_container.get_child(i).stylebox.set("bg_color", Color.AQUAMARINE)
		else:
			current_container.get_child(i).stylebox.set("bg_color", Color.YELLOW)
		
		if i >= start_range and i < end_range:
			current_container.get_child(i).visible = true
		else:
			current_container.get_child(i).visible = false
			
	if Global.item_list.size() > 0:
		match current_tab:
			0:
				$ColorRect2.get_child(0).text = Global.weapon_list.get(selected_index).weapon_description
			1:
				$ColorRect2.get_child(0).text = Global.equipment_list.get(selected_index).equipment_description

func display_item_clicked(clicked_item):
	var current_menu = self.get_node("ColorRect2")
	
	match current_tab:
		0:
			current_menu.get_child(0).text = clicked_item.weapon_description
		1:
			current_menu.get_child(0).text = clicked_item.equipment_description
	current_menu.visible = true

func update_menu(item_index, item):
	if item_index == -1:
		var new_item = item_scene.instantiate()
		new_item.setup(item)
		new_item.item_clicked.connect(display_item_clicked)
		current_container.add_child(new_item)
	else:
		current_container.remove_child_at(item_index)
