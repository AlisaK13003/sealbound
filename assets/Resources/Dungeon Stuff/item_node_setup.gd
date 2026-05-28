extends Control

@onready var item_name = $HBoxContainer/Control/Item_Name
@onready var item_texture = $HBoxContainer/Control/Item_Texture
@onready var selection_arrow = $HBoxContainer/AnimatedSprite2D

var trying_to_be_used: bool = false
var index_number: int
var held_item : Items
var p_ref
var can_be_selected

func _setup(item_passed: Items, i_num, parent_ref):
	p_ref = parent_ref
	item_name.text = item_passed.item_name
	item_texture.texture = item_passed.item_sprite
	print("Index of stored item: ", i_num)
	index_number = i_num
	held_item = item_passed
	
func _on_panel_mouse_entered():
	p_ref.unselect_all()
	can_be_selected = true
	p_ref.update_description(held_item.item_description)
	selection_arrow.visible = true
	selection_arrow.play("default")

func unselect():
	can_be_selected = false
	selection_arrow.visible = false
	selection_arrow.stop()

func _on_item_selected(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			p_ref.p_ref.item_selected(held_item, index_number)
