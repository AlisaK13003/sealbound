extends Node2D

@onready var button = $GenericButton

func _ready():
	button.activated.connect(turn_in_quests)
	
func turn_in_quests():
	if player_in_range:
		GlobalCombatInformation.turn_in_all_possible_quests()
		button.visible = false
		player_in_range = false

var player_in_range: bool = false
func _on_area_2d_body_entered(body):
	if body.is_in_group("Overworld_Player"):
		button.visible = true
		player_in_range = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("Overworld_Player"):
		button.visible = false
		player_in_range = false
