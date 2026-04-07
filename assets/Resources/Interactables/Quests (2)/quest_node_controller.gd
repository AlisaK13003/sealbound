extends Control

@onready var quest_name_label = $VBoxContainer/QuestName

var what_quest_am_i

signal on_click(quest_)

func setup_(quest_: quests):
	quest_name_label.text = quest_.quest_name
	what_quest_am_i = quest_
	print("IT'S WORKING")
	print(quest_name_label.text)

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: 
		on_click.emit(what_quest_am_i)
