extends Control

@onready var item_name = $HBoxContainer/Container/HBoxContainer/Item_Name
@onready var item_texture = $HBoxContainer/Container/HBoxContainer/Item_Texture
@onready var selection_arrow = $HBoxContainer/AnimatedSprite2D
@onready var item_count = $HBoxContainer/Container/HBoxContainer/Item_Count

var trying_to_be_used: bool = false
var index_number: int
var held_item : Items
var p_ref
var can_be_selected
var can_be_unselected = true

var disabled: bool = false

func _setup(item_passed: Items, i_num, parent_ref, should_be_disabled: bool = false):
	p_ref = parent_ref
	await get_tree().process_frame
	item_name.text = item_passed.item_name
	item_texture.texture = item_passed.item_sprite
	index_number = i_num
	held_item = item_passed
	item_count = "x" + str(item_passed.stack)
	disabled = should_be_disabled
	
func highlight(should_highlight):
	if should_highlight:
		if not can_be_selected:
			return
		can_be_selected = true
		p_ref.update_description(held_item.item_description)
		selection_arrow.visible = true
		selection_arrow.play("default")
		p_ref.update_selected_child(index_number)
	else:
		can_be_selected = false
		selection_arrow.visible = false
		selection_arrow.stop()
	
func was_hovered():
	return
	
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
	if disabled: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selection_confirmed()
			p_ref.p_ref.gui.update_action_hints()

func _notification(what: int) -> void:
	if disabled: return
	match what:
		NOTIFICATION_MOUSE_ENTER:
			p_ref.unselect_all()
			select()
			can_be_unselected = false
			
		NOTIFICATION_MOUSE_EXIT:
			can_be_unselected = true
