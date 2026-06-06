extends Resource

class_name generic_combatants

@export var combatant_name: String
@export var party_member_portrait: Texture2D
@export var combatant_sprite: Texture2D
@export var combatant_stats: stats
@export var is_combatant_enemy: bool
@export var is_dead: bool = false
@export var stored_weapon : weapon
@export var stored_equipment : equipment

@export var drop_table: drop_tables

@export var combatant_skills : Array[moves]

@export var voxel_frames: Dictionary[String, voxel_animation]
@export var sprite_frames: SpriteFrames
@export var idle_speed: float
@export var death_speed: float
@export var walk_speed: float
@export var attack_speed: Array[float]

@export_enum("EASY", "MEDIUM", "DIFFICLT", "REALLY_HARD") var experience_mult = 0

@export var total_experience_points: int

@export var bond_level: GlobalCombatInformation.bonds

func add_experience(amount_to_add):
	total_experience_points += amount_to_add
	combatant_stats.level
	while(total_experience_points >= ceili((100 * pow(1.2, combatant_stats.level)) - 120)):
		combatant_stats.level += 1
	
	return (ceili((100 * pow(1.2, combatant_stats.level + 1)) - 120) - (total_experience_points - ceili((100 * pow(1.2, combatant_stats.level)) - 120)))
