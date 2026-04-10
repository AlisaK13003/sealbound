extends Node2D

@onready var gui = $CanvasLayer
@export var stored_quests_: Array[quests]

var player_is_in_range: bool = false

func _ready():
	Global.save_loaded.connect(_on_game_start_)
	gui.visible = false

func _on_game_start_():
	gui.visible = false

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed: 
		if player_is_in_range and not Global.is_in_menu:
			Global.is_in_menu = true
			gui.visible = true

func _input(event):
	if event.is_action_pressed("Pause"):
		Global.is_in_menu = false
		gui.visible = false
		for quest_ in Global.accepted_quest_list:
			print(quest_.quest_name)

func _on_area_2d_2_body_entered(body):
	if body is Player:
		player_is_in_range = true

func _on_area_2d_2_body_exited(body):
	if body is Player:
		player_is_in_range = false
