extends Resource
class_name moves

@export var move_name: String
@export var attack_power: int
@export var priority: int
@export var magic_cost: int
@export var does_aoe_damage: bool

# Determines whether the move heals, and whether by a percentage or int
@export var does_heal_party: bool
@export var amount_healed: int
@export var percentage_health: float
