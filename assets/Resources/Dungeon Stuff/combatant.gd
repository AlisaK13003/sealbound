extends Resource

class_name generic_combatants

@export var combatant_name: String
@export var party_member_portrait: Texture2D
@export var combatant_stats: stats
var actual_stats: stats
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

@export var combatant_skills_: Dictionary[moves, bool]

@export var resonance_skills_: Dictionary[String, Array]

@export var sprite_frames: SpriteFrames
@export var idle_speed: float
@export var death_speed: float
@export var walk_speed: float
@export var attack_speed: Array[float]
@export var sprite_scale: float = 1.0

@export var sprite_offset: Vector2 = Vector2(0, 0)
@export var equip_sprite_offset: Vector2 = Vector2(0, 0)
@export var equip_flip: bool = false

@export_enum("EASY", "MEDIUM", "DIFFICLT", "REALLY_HARD") var experience_mult = 0

@export var total_experience_points: int
@export var toatl_bond_points: int = 0

@export var bond_points: int = 0
@export var bond_level: GlobalCombatInformation.bonds

@export var is_MC: bool = false

var resonated_with: bool = false

func update_moves(moves_list):
	combatant_skills_.clear()
	for move in moves_list:
		combatant_skills_[move] = true

func restore_health():
	combatant_stats.health = combatant_stats.max_health
	actual_stats.health = actual_stats.max_health

func add_experience(amount_to_add: int) -> int:
	total_experience_points += amount_to_add
	
	while total_experience_points >= get_level_threshold(combatant_stats.level):
		combatant_stats.level += 1
		if not is_combatant_enemy:
			actual_stats.level += 1
		handle_level_up_growths() 
	
	var next_level_requirement = get_level_threshold(combatant_stats.level)
	
	return next_level_requirement - total_experience_points

func _calculate_enemy_exp(enemy) -> int:
	var enemy_level: int = enemy.combatant_stats.level
	
	var base_exp: float = 0.0
	match enemy.experience_mult:
		0: base_exp = 24.0   
		1: base_exp = 30.0   
		2: base_exp = 36.0   
		3: base_exp = 150.0  
		
	var level_scaled_exp = base_exp * pow(1.2, enemy_level - 1)
	
	var final_exp = level_scaled_exp * randf_range(0.9, 1.1)
	
	return max(1, ceili(final_exp))



func raise_level_by_x(amount_to_raise_by, differential: int = 0):
	var dif = []
	for i in range(differential + 1):
		dif.append(i)
		if i * -1 != i:
			dif.append(i * -1)
	var level_target = clamp(amount_to_raise_by + (dif.pick_random()), 0, 99)
	for i in range(level_target):
		var amount_of_exp_to_add = get_level_threshold(combatant_stats.level) - total_experience_points
		add_experience(max(0, amount_of_exp_to_add))

func get_level_threshold(current_level: int) -> int:
	return ceili(100.0 * pow(float(current_level), 1.5))

func heal(skill_used: moves, person_who_used_skill: generic_combatants):
	if skill_used.get_skill_boost() != 999:
		actual_stats.health = clamp(actual_stats.health + (person_who_used_skill.actual_stats.magic + skill_used.get_skill_boost()), 0, actual_stats.max_health)
	else:
		actual_stats.health = actual_stats.max_health
	GlobalCombatInformation.check_player_values.emit()

func take_damage(amount):
	actual_stats.health += int(amount)

func export_to_JSON():
	return {
		"path": resource_path,
		"name": combatant_name,
		"combatant_stats": combatant_stats.export_to_JSON(),
		"actual_combatant_stats": actual_stats.export_to_JSON(),
		"stored_equipment": stored_equipment.export_to_JSON(),
		"stored_weapon": stored_weapon.export_to_JSON(),
		"current_stored_slot": current_stored_slot,
		"total_experience_points": total_experience_points,
		"bond_points": bond_points,
		"bond_level": bond_level,
		"is_mc": is_MC,
 	}

func load_save(save_info):
	bond_points = int(save_info.get("bond_points", bond_points))
	combatant_name = save_info.get("name", combatant_name)
	bond_level = save_info.get("bond_level", bond_level)
	current_stored_slot = save_info["current_stored_slot"]
	total_experience_points = save_info["total_experience_points"]
	if save_info["stored_weapon"] != null:
		stored_weapon = load(save_info["stored_weapon"]["path"])
	if save_info["stored_equipment"] != null:
		stored_equipment = load(save_info["stored_equipment"]["path"])
	is_MC = save_info.get("is_mc", is_MC)
	combatant_stats.load_information(save_info["combatant_stats"])
	gather_actual_stats()
	
func gather_actual_stats():
	actual_stats = add_up_stats()

func custom_duplicate():
	var copy = self.duplicate(true)
	copy.actual_stats = actual_stats.duplicate(true)
	return copy

func add_up_stats() -> stats:
	if is_combatant_enemy:
		return combatant_stats
		
	if combatant_stats == null:
		push_error("combatant_stats is null in add_up_stats()")
		return null

	var health = combatant_stats.health
	if actual_stats != null:
		health = actual_stats.health

	var final_stats: stats = combatant_stats.duplicate(true)
	
	if stored_equipment != null and stored_equipment.equipment_stats != null:
		final_stats = add_stats(final_stats, stored_equipment.equipment_stats)
		
	if stored_boots != null and stored_boots.equipment_stats != null:
		final_stats = add_stats(final_stats, stored_boots.equipment_stats)
		
	if stored_chestplate != null and stored_chestplate.equipment_stats != null:
		final_stats = add_stats(final_stats, stored_chestplate.equipment_stats)
		
	if stored_charm != null and stored_charm.equipment_stats != null:
		final_stats = add_stats(final_stats, stored_charm.equipment_stats)

	if stored_weapon != null:
		final_stats.attack += stored_weapon.weapon_attack
		final_stats.magic += stored_weapon.weapon_magic
		final_stats.crit_chance += stored_weapon.weapon_crit_chance
		final_stats.crit_damage += stored_weapon.weapon_crit_damage

	final_stats.health = clamp(health, 0, final_stats.max_health)
	
	return final_stats

func add_stats(stat_1: stats, stat_2: stats):
	var new_stats = stats.new()
	new_stats.max_health = stat_1.max_health +  stat_2.max_health
	new_stats.health = stat_1.health +  stat_2.health
	new_stats.attack = stat_1.attack +  stat_2.attack
	new_stats.magic = stat_1.magic + stat_2.magic
	new_stats.defense = stat_1.defense +  stat_2.defense
	new_stats.resistance = stat_1.resistance +  stat_2.resistance
	new_stats.crit_chance = stat_1.crit_chance +  stat_2.crit_chance
	new_stats.crit_damage = stat_1.crit_damage +  stat_2.crit_damage
	new_stats.speed = stat_1.speed +  stat_2.speed
	new_stats.luck = stat_1.luck +  stat_2.luck
	new_stats.evasion = stat_1.evasion +  stat_2.evasion
	new_stats.level = max(stat_1.level, stat_2.level)
	return new_stats
	
func _increase_stat(stat_name: String, amount: int) -> void:
	if combatant_stats == null:
		return
		
	var current_value = combatant_stats.get(stat_name)
	combatant_stats.set(stat_name, current_value + amount)
	
	if not is_combatant_enemy and actual_stats != null:
		actual_stats.set(stat_name, actual_stats.get(stat_name) + amount)
		
	if stat_name == "max_health":
		combatant_stats.health += amount
		if not is_combatant_enemy and actual_stats != null:
			actual_stats.health += amount


func handle_level_up_growths() -> void:
	if combatant_stats == null:
		return
		
	if is_combatant_enemy:
		for stat_name in combatant_stats.growth_rates.keys():
			var growth_rate = combatant_stats.growth_rates[stat_name]
			
			var prev_accumulated = floor(float(combatant_stats.level - 1) * growth_rate / 100.0)
			var current_accumulated = floor(float(combatant_stats.level) * growth_rate / 100.0)
			
			if current_accumulated > prev_accumulated:
				_increase_stat(stat_name, 1)
		return

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var stats_gained_count = 0
	var stats_not_gained = []
	
	for stat_name in combatant_stats.growth_rates.keys():
		var roll = rng.randi_range(1, 100)
		if roll <= combatant_stats.growth_rates[stat_name]:
			_increase_stat(stat_name, 1)
			stats_gained_count += 1
		else:
			stats_not_gained.append(stat_name)
			
	var minimum_stats_per_level = 2
	while stats_gained_count < minimum_stats_per_level and not stats_not_gained.is_empty():
		var rand_idx = rng.randi_range(0, stats_not_gained.size() - 1)
		var chosen_stat = stats_not_gained[rand_idx]
		
		_increase_stat(chosen_stat, 1)
		stats_not_gained.remove_at(rand_idx)
		stats_gained_count += 1
	
