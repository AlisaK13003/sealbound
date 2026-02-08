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

var is_dead: bool

func calculate_damage():
	var damage = (player_stats.strength + (current_equipped_weapon.weapon_attack))
	var variance = randf_range(0.9, 1.1)
	var final_damage = int(damage * variance)
	
	print("Planning to deal " + str(final_damage))
	
	return final_damage
	
func take_damage(damage_to_take):
	var damage = damage_to_take - (player_stats.defense + current_equipped_armor.equipment_stats.defense)
	player_stats.health -= damage
	if player_stats.health <= 0:
		is_dead = true 
		
func heal_member(amount_to_heal):
	player_stats.health += amount_to_heal
	is_dead = false
