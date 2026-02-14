extends Resource

class_name EnemyCombatant

# stores information regarding enemies present in combat

@export var enemy_sprite : Texture2D
@export var enemy_name : String
@export var enemy_stats : stats
@export var enemy_moves : Array[moves]
var enemy_position : int

func take_damage(damage_to_take):
	print("Previous health: " + str(enemy_stats.health))
	enemy_stats.health -= clamp(damage_to_take, 0, enemy_stats.health)
	print("Current health: " + str(enemy_stats.health))
	
func calculate_damage():
	var damage = enemy_stats.strength
	var variance = randf_range(0.9, 1.1)
	var final_damage = int(damage * variance)
	return final_damage
