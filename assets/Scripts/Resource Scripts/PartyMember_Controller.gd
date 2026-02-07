extends Resource
class_name PartyMember

@export var member_name : String

@export var player_sprite : Texture2D

@export var move_list : Array[moves]

@export var player_stats : stats

@export var elemental_affinity : Elements 
@export var elemental_weakness : Elements

@export var current_equipped_weapon : weapon
@export var current_equipped_armor : equipment

@export_enum("Front", "Middle", "Back") var current_battle_position

# Damage = base_strength * (weapon_attack / 10)
# var variance = randf_range(0.9, 1.1) # 90% to 110% damage
# final_damage = int(final_damage * variance)
