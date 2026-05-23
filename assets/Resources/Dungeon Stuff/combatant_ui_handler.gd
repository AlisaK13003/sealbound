extends Control

@onready var base_menu = $Player_Menu/Base_Menu
@onready var action_menu = $Player_Menu/Action_Menu
@onready var skill_menu = $Player_Menu/Skill_Menu
@onready var item_menu = $Player_Menu/Item_Menu

@onready var health_bar = $TextureProgressBar

var parent_reference

func _ready():
	reset_ui()

func setup(parent_ref):
	parent_reference = parent_ref
	
func reset_ui():
	base_menu.visible = true
	action_menu.visible = false
	skill_menu.visible = false
	item_menu.visible = false
	
func swap_to_action_menu(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			reset_ui()
			base_menu.visible = false
			action_menu.visible = true
	
func swap_to_skill_menu(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			reset_ui()
			base_menu.visible = false
			skill_menu.visible = true
	
func swap_to_item_menu(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			reset_ui()
			base_menu.visible = false
			item_menu.visible = true

func back_button_pressed(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			reset_ui()
			parent_reference.parent_reference.revert_to_default_UI()

func base_attack_selected(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			parent_reference.parent_reference.attack_button_pressed()

func base_defend_selected(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			parent_reference.parent_reference.defend_button_pressed()
