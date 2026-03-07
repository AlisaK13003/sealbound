extends Control

@export var quest_name_label: Label

var what_quest_am_i

signal on_click(quest_)

func setup(quest_: quest):
	quest_name_label.text = quest_.quest_name
	what_quest_am_i = quest_

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: 
		on_click.emit(what_quest_am_i)
