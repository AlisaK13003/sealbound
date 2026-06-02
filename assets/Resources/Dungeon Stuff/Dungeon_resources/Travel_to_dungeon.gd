extends Control

@export var dungeon_scenes: Array[String]
var current_selected_dungeon: int = 0

@onready var dungeon_select_buttons = $CanvasLayer/VBoxContainer
@onready var container_thing = $CanvasLayer/Control

func _ready():
	for child in dungeon_select_buttons.get_children():
		child.pressed.connect(change_selected_dungeon.bind(child.get_index()))
		print("bound to: ", child.get_index())
		
func change_selected_dungeon(dungeon_select):
	print("HII")
	hide_all_info()
	current_selected_dungeon = dungeon_select
	container_thing.get_child(dungeon_select).visible = true

	print(current_selected_dungeon)

func hide_all_info():
	for child in container_thing.get_children():
		child.visible = false

func _on_label_5_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			await Fade.fade_in()		
			GlobalCombatInformation.transition_to_dungeon(current_selected_dungeon)

func _on_label_6_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			await Fade.fade_in()		
			Fade.change_scene("res://scenes/main/Hearthwynn.tscn")
