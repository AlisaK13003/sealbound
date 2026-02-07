extends Resource

class_name EnemyCombatant

# stores information regarding enemies present in combat

@export var enemy_sprite : Texture2D
@export var enemy_name : String
@export var enemy_stats : stats
@export var enemy_moves : Array[moves]
var enemy_position : int
