extends Control

@export var menu_options: Array[pause_menu_option]
@onready var start_menu = $Initial_Menu/VBoxContainer

@onready var sub_menus = $Sub_Menus

@onready var clock = $Timer
@onready var money_label = $Money

@onready var party_cards = $Party_Cards

var selected_option : int = 0

var current_menu = " "

var in_sub_menu: bool = false

var menu_choices = {
	"Party": 0,
	"Skills": 1,
	"Equipment": 2,
	"Inventory": 3,
	"Bond": 4,
	"Enemy Intel": 5,
	"Journal": 6,
	"Save _ Load": 7,
	"System": 8
}

var time: float = 0

func _ready():
	Global.save_loaded.connect(_on_game_start)

func _on_game_start():
	for child in start_menu.get_children():
		child.option_selected.connect(menu_swap)
		child.option_hovered.connect(change_selection)
	
	money_label.text = str(Global.money)

	for card in range(party_cards.get_child_count()):
		var current_card = party_cards.get_child(card)
		var current_member = Global.party_list.get(card)
		current_card.get_node("TextureRect").texture = current_member.player_sprite
		current_card.get_node("Name").text = current_member.member_name
		current_card.get_node("Level").text = "Level: " + str(current_member.level)
		current_card.get_node("Health").text = "Health: " + str(current_member.player_stats.health)

	change_selection(-1)

func _physics_process(_delta):
	clock.text = (str(Global.play_time_hours)) + ":" + ("%02d" % Global.play_time_minutes) + ":" + ("%02d" % Global.play_time_seconds)

func _input(event):
	if not in_sub_menu:
		if event.is_action_pressed("Mouse Scroll Down"):
			selected_option = clamp(selected_option + 1, 0, start_menu.get_child_count() - 1)
			change_selection(-1)

		if event.is_action_pressed("Mouse Scroll Up"):
			selected_option = clamp(selected_option - 1, 0, start_menu.get_child_count() - 1)
			change_selection(-1)
			
	if event.is_action_pressed("Confirm"):
		menu_swap(selected_option)
		in_sub_menu = true
	
	if event.is_action_pressed("Cancel"):
		if in_sub_menu:
			menu_swap(-2)
		clock.text = str(Global.play_time_seconds)
		

func change_selection(option):
	if not in_sub_menu:
		for child in start_menu.get_children():
			child.change_color(Color.BISQUE)
		
		if not option is String and option != -1:
			selected_option = option
			
		if option is String:
			start_menu.get_child(menu_choices[option]).change_color(Color.BURLYWOOD)
			selected_option = menu_choices[option]
		else:
			start_menu.get_child(selected_option).change_color(Color.BURLYWOOD)

func menu_swap(selected_option_):
	for child in sub_menus.get_children():
		child.visible = false
	
	if not selected_option_ is String and selected_option_ == -2:
		start_menu.visible = true
		in_sub_menu = false
		return
	
	in_sub_menu = true
	start_menu.visible = false
	
	if selected_option_ is String:
		current_menu = selected_option_
		sub_menus.get_child(menu_choices[selected_option_]).visible = true	
		if selected_option_ == "Inventory":
			sub_menus.get_child(menu_choices[selected_option_]).update_display(0)
		return
		
	if selected_option_ != -2:
		sub_menus.get_child(selected_option).visible = true
		current_menu = 	menu_choices.find_key(selected_option)
		if selected_option == 3:
			sub_menus.get_child(selected_option).update_display(0)
	
