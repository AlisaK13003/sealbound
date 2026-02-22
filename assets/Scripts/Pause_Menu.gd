extends Control

@export var menu_options: Array[pause_menu_option]
@onready var start_menu = $Initial_Menu/VBoxContainer

@onready var sub_menus = $Sub_Menus

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

func _ready():
	for child in start_menu.get_children():
		child.option_selected.connect(menu_swap)
		child.option_hovered.connect(change_selection)
	
	change_selection(-1)
	
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

func change_selection(option):
	if not in_sub_menu:
		for child in start_menu.get_children():
			child.get_node("ColorRect").color = Color.WHITE
		
		if not option is String and option != -1:
			selected_option = option
			
		if option is String:
			start_menu.get_child(menu_choices[option]).get_node("ColorRect").color = Color.ANTIQUE_WHITE
			selected_option = menu_choices[option]
		else:
			start_menu.get_child(selected_option).get_node("ColorRect").color = Color.ANTIQUE_WHITE

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
	
# func _physics_process(_delta):
	#var space_state = get_world_2d().direct_space_state
	#var mouse_pos = get_global_mouse_position()
	#
	#var query = PhysicsPointQueryParameters2D.new()
	#query.position = mouse_pos
	#query.collide_with_areas = true
	#
	#var result = space_state.intersect_point(query)
	#
	#if result.size() > 0:
		#var top_area = result[0].collider
		#print("Hovering over: ", top_area.name)
	#else:
		#print("Hovering over nothing")
