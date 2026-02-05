extends Node


# Given current encounter / party arrangement assign the appropriate sprites and hide the color_rect on the combat_templates
func _ready():
	pass

# Returns a list of active combatants in descending speed order
func turn_priority():
	pass

# executes turns in order of speed
func take_turn():
	pass
	
func player_turn(cur_player: int):
	pass
	
func enemy_turn(cur_enemy: int):
	pass
	
