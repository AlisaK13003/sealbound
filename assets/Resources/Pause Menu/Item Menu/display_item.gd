extends Control

@export var item_name: Label
@export var item_sprite: TextureRect

var what_am_i: Items

signal item_clicked(current_item)

func setup(item: Items):
	item_name.text = item.item_name
	item_sprite.texture = item.item_sprite
	what_am_i = item

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.is_action_pressed("Left Mouse"):
			item_clicked.emit(what_am_i)
