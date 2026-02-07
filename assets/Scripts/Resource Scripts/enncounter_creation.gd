@tool
extends Resource
class_name encounters

@export var enemy_list : Array[EnemyCombatant]: 
	set(value):
		if value.size() > 9:
			value = value.slice(0, 9)
		enemy_list = value
