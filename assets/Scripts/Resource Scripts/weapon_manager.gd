extends Resource
class_name weapon

@export var weapon_name : String
@export var weapon_description : String

@export var weapon_attack : int
@export var weapon_magic : int

@export var attack_accuracy : int

@export var elemental_affinity : Elements 

@export_enum("Sleep", "Shock", "Poision", "Burn", "Freeze") var status_conditions
@export_range(0,1) var chance_of_status_condition : float
