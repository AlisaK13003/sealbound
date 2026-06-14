extends Resource
class_name weapon

@export var weapon_name : String
@export var weapon_description : String

@export var weapon_attack : int
@export var weapon_magic : int

@export var attack_accuracy : int

func export_to_JSON():
	return {
		"path": resource_path,
	}
