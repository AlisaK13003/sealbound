extends Node2D

@export var stored_quests : Array[quest]
@onready var quest_node = preload("res://assets/Resources/Quests/quest_node.tscn")
@onready var gui = $CanvasLayer
@onready var quest_area = $CanvasLayer/Control2/Quest_Area

@onready var quest_information_area = $CanvasLayer/Panel2
@onready var quest_description_label = $CanvasLayer/Panel2/quest_description
@onready var client_name_label = $CanvasLayer/Panel2/client_name
# @onready var quest_goal_label = $CanvasLayer/Panel2/quest_goal
@onready var quest_location_label = $CanvasLayer/Panel2/quest_location
@onready var quest_difficulty_label = $CanvasLayer/Panel2/quest_difficulty
@onready var quest_reward_label = $CanvasLayer/Panel2/quest_reward

var player_is_in_range: bool = false

func _ready():
	Global.save_loaded.connect(_on_game_start_)

func _on_game_start_():
	gui.visible = false
	for quest_ in stored_quests:
		if Global.can_take_quest(quest_):
			var new_quest = quest_node.instantiate()
			new_quest.setup(quest_)
			new_quest.on_click.connect(quest_clicked)
			quest_area.add_child(new_quest)

func quest_clicked(clicked_quest: quest):
	quest_description_label.text = "Description: \n" + clicked_quest.quest_description
	client_name_label.text = "Requestor: " + clicked_quest.quest_giver
	# quest_goal_label.text = "Goal: " + clicked_quest.quest_description
	quest_location_label.text = "Location: " + str(clicked_quest.quest_location)
	quest_difficulty_label.text = "Difficulty: " + str(clicked_quest.difficult_level)
	
	# Need to account for all the other possible rewards
	quest_reward_label.text = "Reward: " + str(clicked_quest.reward_money)
	

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed: 
		if player_is_in_range and not Global.is_in_menu:
			Global.is_in_menu = true
			gui.visible = true

func _input(event):
	if event.is_action_pressed("Pause"):
		Global.is_in_menu = false
		gui.visible = false

func _on_area_2d_2_body_entered(body):
	if body is Player:
		player_is_in_range = true

func _on_area_2d_2_body_exited(body):
	if body is Player:
		player_is_in_range = false
