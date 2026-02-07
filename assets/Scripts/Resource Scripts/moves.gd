extends Resource
class_name moves

@export var move_name: String
@export var move_description : String
@export var attack_power: int
@export var priority: int
@export var magic_cost: int
@export var does_aoe_damage: bool

@export var elemental_affinity : Elements 
@export_enum("Sleep", "Shock", "Poision", "Burn", "Freeze") var status_conditions
@export_range(0,1) var chance_of_status_condition : float

# Determines whether the move heals, and whether by a percentage or int
@export var does_heal_party: bool
@export var amount_healed: int
@export var percentage_health: float
