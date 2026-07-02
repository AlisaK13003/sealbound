extends Resource
class_name weapon

@export var weapon_name : String
@export var weapon_description : String
@export var weapon_texture: Texture2D

@export var weapon_attack : int = 0
@export var weapon_magic : int = 0

@export var weapon_crit_chance: float = 0.0
@export var weapon_crit_damage: float = 0.0

@export var attack_accuracy : int = 0

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
