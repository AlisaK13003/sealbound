extends Control

@onready var item_name = $Item_Name
@onready var item_texture = $Item_Texture
@onready var item_description_panel = $Item_Description_Panel
@onready var item_description_label = $Item_Description_Panel/Item_Description

var trying_to_be_used: bool = false
var index_number: int
var held_item : Items
var parent_reference
var can_be_selected

func setup(item_passed: Items, i_num, parent_ref):
	parent_reference = parent_ref
	item_name.text = item_passed.item_name
	item_texture.texture = item_passed.item_sprite
	item_description_label.text = item_passed.item_description
	index_number = i_num
	held_item = item_passed
	
func _on_panel_mouse_entered():
	can_be_selected = true
	item_description_panel.visible = true

func _on_panel_mouse_exited():
	can_be_selected = false
	item_description_panel.visible = false

func _on_item_selected(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_be_selected:
			if parent_reference.item_menu.visible:
				parent_reference.item_selected(index_number)
