extends Resource
class_name weapon

@export var weapon_name : String
@export var weapon_description : String
@export var weapon_texture: Texture2D

@export var weapon_attack : int = 0
@export var weapon_magic : int = 0

@export var weapon_crit_chance: int = 0
@export var weapon_crit_damage: int = 0

@export var attack_accuracy : int = 0

@export var buy_price: int = 0
@export var sell_price: int = 10
@export var stack: int = 1

func export_to_JSON():
	return {
		"path": resource_path,
	}

func return_stuff():
	return {
		"name": weapon_name,
		"description": weapon_description,
		"texture": weapon_texture,
		"attack": weapon_attack,
		"magic": weapon_magic,
		"accuracy": attack_accuracy,
		"crit chance": weapon_crit_chance,
		"crit damage": weapon_crit_damage,
	}

func get_stat_string():
	return str(weapon_attack) + " Attack, " + str(weapon_crit_chance) + "% Crit C, " + str(weapon_crit_damage) + " Crit D"
