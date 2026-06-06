extends Control

@onready var item_name = $HBoxContainer/Container/Item_Name
@onready var item_texture = $HBoxContainer/Container/Item_Texture
@onready var selection_arrow = $HBoxContainer/AnimatedSprite2D

var trying_to_be_used: bool = false
var index_number: int
var held_item : Items
var p_ref
var can_be_selected
var can_be_unselected = true

func _setup(item_passed: Items, i_num, parent_ref):
	p_ref = parent_ref
	item_name.text = item_passed.item_name
	item_texture.texture = item_passed.item_sprite
	index_number = i_num
	held_item = item_passed
	
func select():
	if not can_be_unselected:
		return
	can_be_selected = true
	p_ref.update_description(held_item.item_description)
	selection_arrow.visible = true
	selection_arrow.play("default")
	p_ref.update_selected_child(index_number)
	
func unselect():
	can_be_selected = false
	selection_arrow.visible = false
	selection_arrow.stop()

func selection_confirmed():
	p_ref.p_ref.item_selected(held_item, index_number)

func execute_selection():
	p_ref.p_ref.confirmation.emit(true)
	p_ref.p_ref.gui.update_action_hints()

	
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selection_confirmed()
			p_ref.p_ref.gui.update_action_hints()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			p_ref.unselect_all()
			select()
			can_be_unselected = false
			
		NOTIFICATION_MOUSE_EXIT:
			can_be_unselected = true
