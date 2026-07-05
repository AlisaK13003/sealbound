extends Resource

class_name generic_combatants

@export var combatant_name: String
@export var party_member_portrait: Texture2D
@export var combatant_stats: stats
@export var is_combatant_enemy: bool
@export var is_dead: bool = false

@export_category("Equipped Items")
@export var stored_weapon : weapon
@export var stored_equipment : equipment
@export var stored_charm: equipment
@export var stored_boots: equipment
@export var stored_chestplate: equipment


@export var should_flip_sprite: bool = false

@export var current_stored_slot: int

@export var drop_table: Dictionary[Resource, float]
@export var quest_item_drop: Items
@export var coin_drop_range: Vector2i
@export var bond_drop_range: Vector2i

@export var combatant_skills : Array[moves]

@export var sprite_frames: SpriteFrames
@export var idle_speed: float
@export var death_speed: float
@export var walk_speed: float
@export var attack_speed: Array[float]
@export var sprite_scale: float = 1.0

@export var sprite_offset: Vector2 = Vector2(0, 0)
@export var equip_sprite_offset: Vector2 = Vector2(0, 0)

@export_enum("EASY", "MEDIUM", "DIFFICLT", "REALLY_HARD") var experience_mult = 0

@export var total_experience_points: int
@export var toatl_bond_points: int = 0

@export var bond_points: int = 0
@export var bond_level: GlobalCombatInformation.bonds

func restore_health():
	combatant_stats.health = combatant_stats.max_health

func add_experience(amount_to_add):
	total_experience_points += amount_to_add
	#combatant_stats.level
	while(total_experience_points >= ceili((100 * pow(1.2, combatant_stats.level)) - 120)):
		combatant_stats.level += 1
	
	return (ceili((100 * pow(1.2, combatant_stats.level + 1)) - 120) - (total_experience_points - ceili((100 * pow(1.2, combatant_stats.level)) - 120)))

func export_to_JSON():
	return {
		"path": resource_path,
		"combatant_stats": combatant_stats.export_to_JSON(),
		"stored_equipment": stored_equipment.export_to_JSON(),
		"stored_weapon": stored_weapon.export_to_JSON(),
		"current_stored_slot": current_stored_slot,
		"total_experience_points": total_experience_points,
		"bond_points": bond_points,
		"bond_level": bond_level,
 	}

func load_save(save_info):
	bond_points = int(save_info.get("bond_points", bond_points))
	bond_level = save_info.get("bond_level", bond_level)
	current_stored_slot = save_info["current_stored_slot"]
	total_experience_points = save_info["total_experience_points"]
	if save_info["stored_weapon"] != null:
		stored_weapon = load(save_info["stored_weapon"]["path"])
	if save_info["stored_equipment"] != null:
		stored_equipment = load(save_info["stored_equipment"]["path"])
	add_experience(total_experience_points)
