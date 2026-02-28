extends Resource
class_name PartyMember

@export var member_name : String

@export var level : int

@export var player_sprite : Texture2D

@export var move_list : Array[moves]

@export var player_stats : stats

@export var elemental_affinity : Elements 
@export var elemental_weakness : Elements

@export var current_equipped_weapon : weapon
@export var current_equipped_armor : equipment

@export_enum("Front", "Middle", "Back") var current_battle_position

var is_dead: bool

func get_save_stats():
	return {
		"path": resource_path,
		"level": level,
		"current_health": player_stats.health,
		"current_equipped_weapon": current_equipped_weapon.resource_path,
		"current_equipped_armor": current_equipped_armor.resource_path
	}

func load_save_data(data):
	level = data["level"]
	player_stats.health = data["current_health"]
	current_equipped_armor = load(data["current_equipped_armor"])
	current_equipped_weapon = load(data["current_equipped_weapon"])

func use_move(move):
	var damage = player_stats.strength * move.attack_power
	var variance = randf_range(0.9, 1.1)
	var final_damage = int(damage * variance)
	
	return final_damage

func use_item(item):
	var heal_amount = item.amount_to_heal_or_deal
	heal_member(heal_amount)

func calculate_damage():
	var damage = (player_stats.strength + (current_equipped_weapon.weapon_attack))
	var variance = randf_range(0.9, 1.1)
	var final_damage = int(damage * variance)
	
	return final_damage
	
func take_damage(damage_to_take):
	var damage = damage_to_take - (player_stats.defense + current_equipped_armor.equipment_stats.defense)
	player_stats.health -= damage
	if player_stats.health <= 0:
		is_dead = true 
		
func heal_member(amount_to_heal):
	player_stats.health += clamp(amount_to_heal, 0, player_stats.max_health)
	is_dead = false
