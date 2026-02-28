extends Control

@onready var item_container = $VBoxContainer
@onready var party_cards = $Party_Cards
var item_scene = preload("res://assets/Resources/Pause Menu/Item Menu/Display_item.tscn")
var start_range = 0
var end_range = 7

var selected_item = 0

@export var menu_parent : Control

func _ready():
	Global.save_loaded.connect(_on_game_start)

func _on_game_start():
	Global.item_list_updated.connect(update_item_menu)
	for item in Global.item_list:
		var new_item = item_scene.instantiate()
		new_item.setup(item)
		new_item.item_clicked.connect(display_item_clicked)
		item_container.add_child(new_item)
		
	setup_party_card(Global.party_slot_1, 0)
	setup_party_card(Global.party_slot_2, 1)
	setup_party_card(Global.party_slot_3, 2)


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
	
	if menu_parent.current_menu == "Inventory":
		if event.is_action_pressed("Mouse Scroll Down"):
			update_display(1)
			
		if event.is_action_pressed("Mouse Scroll Up"):
			update_display(-1)

func update_display(change_range_by: int):
	if selected_item == end_range - 2 and change_range_by == 1:
		start_range = clamp(start_range + change_range_by, 0, Global.item_list.size() - 7)
		end_range = clamp(end_range + change_range_by, start_range + 7, Global.item_list.size())
	elif selected_item == start_range + 1 and change_range_by == -1:
		start_range = clamp(start_range + change_range_by, 0, Global.item_list.size() - 7)
		end_range = clamp(end_range + change_range_by, start_range + 7, Global.item_list.size())
	selected_item = clamp(selected_item + change_range_by, 0, Global.item_list.size() - 1)

	for i in range(Global.item_list.size()):
		if item_container.get_child(i) == null:
			return
		if i == selected_item:
			item_container.get_child(i).change_color(Color.AQUAMARINE)
		else:
			item_container.get_child(i).change_color(Color.YELLOW)
		
		if i >= start_range and i < end_range:
			item_container.get_child(i).visible = true
		else:
			item_container.get_child(i).visible = false
	if Global.item_list.size() > 0:
		$ColorRect2.get_child(0).text = Global.item_list.get(selected_item).item_description

func display_item_clicked(clicked_item: Items):
	var current_menu = self.get_node("ColorRect2")
	current_menu.get_child(0).text = clicked_item.item_description
	current_menu.visible = true

func update_item_menu(item_index, item):
	if item_index == -1:
		var new_item = item_scene.instantiate()
		new_item.setup(item)
		new_item.item_clicked.connect(display_item_clicked)
		item_container.add_child(new_item)
	else:
		item_container.remove_child_at(item_index)
