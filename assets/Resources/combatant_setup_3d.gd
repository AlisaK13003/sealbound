extends Node3D

class_name combat_template

#region Variables

@onready var combatant_sprite = $Sprite3D
@onready var health_bar = $Sprite3D2/SubViewport/CombatantUi.get_node("TextureProgressBar")
@onready var attacked_label = $Label3D
@onready var combatant_ui_: combatant_ui = $Sprite3D2/SubViewport/CombatantUi
@onready var status_sprite = load("res://assets/tile sheets/Up_Arrow.png")
@onready var enemy_collision = $Sprite3D2/Enemy_Collision
@onready var selection_area_sprite = $AnimatedSprite3D
@onready var animated_sprite = $AnimatedSprite3D2
@onready var subviewport = $Sprite3D2/SubViewport
@onready var ui_sprite = $Sprite3D2
@onready var rng = RandomNumberGenerator.new()
@onready var animator = SpriteFrames.new()

var currently_selectable : bool
var stored_combatant : generic_combatants
var parent_reference
var child_number: int
var is_empty : bool
var is_defending : bool = false
var all_active_effects = 0
var active_statuses : Array[status]
var already_inflicted_with_major_status = false
var previously_visible = false
var base_location: Vector3
var displacement = Vector3(0.3, 0, 0)
var can_be_unselected: bool = true
var current_mana = 2

# Percentages that stat buff / debuffs affect combat
var attack_up_down: float = 1.25
var defense_up_down: float = 1.25
var evasion_up_down: float = 1.25
var accuracy_up_down: float = 1.25
var critchance_up_down: float = 1.25
var speed_up_down: float = 1.25

enum statuses {
	STUN = 1 << 0,
	SLEEP = 1 << 1,
	SHOCK = 1 << 2,
	POISON = 1 << 3,
	BURN = 1 << 4,
	FREEZE = 1 << 5,
	SLOW = 1 << 6,
	AGRO = 1 << 7,
	ATTACKdown = 1 << 8,
	DEFENSEdown = 1 << 9,
	EVASIONdown = 1 << 10,
	CRITCHANCEdown = 1 << 11,
	ACCURACYdown = 1 << 12,
	MOMENTUM = 1 << 13,
	REGEN = 1 << 14,
	STUNIMMUNITY = 1 << 15,
	ATTACKup = 1 << 16,
	DEFENSEup = 1 << 17,
	EVASIONup = 1 << 18,
	CRITCHANCEup = 1 << 19,
	ACCURACYup = 1 << 20,
}

var conflicts = {
	statuses.ATTACKdown: statuses.ATTACKup,
	statuses.ATTACKup: statuses.ATTACKdown,
	statuses.DEFENSEdown: statuses.DEFENSEup,
	statuses.DEFENSEup: statuses.DEFENSEdown,
	statuses.EVASIONdown: statuses.EVASIONup,
	statuses.ACCURACYdown: statuses.ACCURACYup,
	statuses.EVASIONup: statuses.EVASIONdown,
	statuses.CRITCHANCEdown: statuses.CRITCHANCEup,
	statuses.CRITCHANCEup: statuses.CRITCHANCEdown,
	statuses.ACCURACYup: statuses.ACCURACYdown
}

@onready var status_map: Dictionary = {
	statuses.STUN: _apply_stun,
	statuses.SLEEP: _apply_sleep,
	statuses.SHOCK: _apply_shock,
	statuses.POISON: _apply_poison,
	statuses.BURN: _apply_burn,
	statuses.FREEZE: _apply_freeze,
	statuses.SLOW: stat_does_nothing,
	statuses.AGRO: _apply_agro,
	statuses.ATTACKdown: stat_does_nothing,
	statuses.DEFENSEdown: stat_does_nothing,
	statuses.EVASIONdown: stat_does_nothing,
	statuses.CRITCHANCEdown: stat_does_nothing,
	statuses.ACCURACYdown: stat_does_nothing,
	statuses.MOMENTUM: _apply_momentum,
	statuses.REGEN: _apply_regen,
	statuses.STUNIMMUNITY: _apply_stun_imm,
	statuses.ATTACKup: stat_does_nothing,
	statuses.DEFENSEup: stat_does_nothing,
	statuses.EVASIONup: stat_does_nothing,
	statuses.CRITCHANCEup: stat_does_nothing,
	statuses.ACCURACYup: stat_does_nothing
}

@onready var status_color_chart: Dictionary = {
	statuses.STUN: Color.YELLOW,
	statuses.SLEEP: Color.DIM_GRAY,
	statuses.SHOCK: Color.YELLOW,
	statuses.POISON: Color.WEB_PURPLE,
	statuses.BURN: Color.ORANGE_RED,
	statuses.FREEZE: Color.LIGHT_CYAN,
	statuses.SLOW: stat_does_nothing,
	statuses.AGRO: Color.INDIAN_RED,
	statuses.ATTACKdown: Color.RED,
	statuses.DEFENSEdown: Color.BLUE,
	statuses.EVASIONdown: Color.YELLOW,
	statuses.CRITCHANCEdown: Color.GREEN,
	statuses.ACCURACYdown: Color.CADET_BLUE,
	statuses.MOMENTUM: _apply_momentum,
	statuses.REGEN: _apply_regen,
	statuses.STUNIMMUNITY: _apply_stun_imm,
	statuses.ATTACKup: Color.RED,
	statuses.DEFENSEup: Color.BLUE,
	statuses.EVASIONup: Color.YELLOW,
	statuses.CRITCHANCEup: Color.GREEN,
	statuses.ACCURACYup: Color.CADET_BLUE
}

enum stats {ATTACK, DEFENSE, ACCURACY, EVASION, CRIT_CHANCE, SPEED, MAGIC}

#endregion

func setup(combatant : generic_combatants, parent_ref, child_num):
	if combatant == null:
		is_empty = true
		return
	parent_reference = parent_ref
	child_number = child_num
	base_location = self.global_position

	all_active_effects = 0
	active_statuses.clear()
	is_defending = false
		
	stored_combatant = combatant
	health_bar.max_value = combatant.combatant_stats.max_health
	health_bar.value = combatant.combatant_stats.health
	
	if combatant.is_combatant_enemy:
		if has_node("Sprite3D2/Area3D"):
			$Sprite3D2/Area3D.queue_free()
		animated_sprite.sprite_frames = combatant.sprite_frames
		combatant_sprite.visible = false
		animated_sprite.pixel_size = 0.004
		animated_sprite.speed_scale = stored_combatant.idle_speed
		animated_sprite.frame = (rng.randi_range(0, (animated_sprite.sprite_frames.get_frame_count("Idle")) - 1))
		animated_sprite.play("Idle")
	else:
		$Sprite3D2/SubViewport/CombatantUi/TextureProgressBar.visible = false
		combatant_sprite.texture = combatant.combatant_sprite
	
func update_health(change_health_value, status_ = false, portrait: player_portraits = null):
	if not status_:
		if str(change_health_value) == "MISS":
			await update_damage_label(0, false, true)
		elif str(change_health_value[0]) == "MISS":
			await update_damage_label(0, false, true)
		else:
			if is_defending:
				portrait._update_health(change_health_value)
				await update_damage_label(change_health_value * 0.4, false, false)
			else:
				if portrait == null:
					health_bar.value -= floor(change_health_value[0])
				else:
					portrait._update_health(change_health_value[0])
				await update_damage_label(change_health_value, false, false)
			if is_defending:
				stored_combatant.combatant_stats.health -= floor(change_health_value[0] * 0.4)
			else:
				stored_combatant.combatant_stats.health -= change_health_value[0]
	else:
		if not stored_combatant.is_combatant_enemy:
			parent_reference.get_player_portrait(child_number)._update_health(change_health_value)
		else:
			health_bar.value -= floor(change_health_value)
			attacked_label.text = str(int(floor(change_health_value)))
			
	await get_tree().create_timer(0.5).timeout
	
	attacked_label.text = ""
	if stored_combatant.combatant_stats.health <= 0:
		on_death()
	parent_reference.turn_ended.emit()

func update_damage_label(damage_taken, _was_heal = false, attack_missed = false):
	if attack_missed:
		attacked_label.modulate = Color.MAGENTA
		attacked_label.text = "MISS"
	elif not damage_taken[1] is String and damage_taken[1] == 1:
		attacked_label.modulate = Color.RED
		attacked_label.text = "CRIT"
		await get_tree().create_timer(0.5).timeout
		attacked_label.text = str(int(floor(damage_taken[0])))
	elif damage_taken[1] is String and not damage_taken[1] == "":
		attacked_label.modulate = Color.LAWN_GREEN
		attacked_label.text = str(int(floor(-1 * damage_taken[0])))
	else:
		attacked_label.modulate = Color.WEB_PURPLE
		attacked_label.text = str(int(floor(damage_taken[0])))
	await get_tree().create_timer(0.5).timeout
	attacked_label.text = ""

# Combat related stuff
func calculate_evasion(entity_being_attacked: combat_template, attack_hit_chance = 90):
	if not stored_combatant.is_combatant_enemy:
		return ((obtain_stat(stats.EVASION) + 200) / (entity_being_attacked.obtain_stat(stats.EVASION) + 200)) * (attack_hit_chance * obtain_stat_alteration(stats.ACCURACY))
	else:
		return (((obtain_stat(stats.EVASION) + 200) / (entity_being_attacked.obtain_stat(stats.EVASION) + 200)) * (attack_hit_chance * obtain_stat_alteration(stats.ACCURACY))) * ((obtain_stat(stats.EVASION) + 200) / ((((stored_combatant.stored_equipment.equipment_stats.evasion * obtain_stat_alteration(stats.EVASION))) / 2) + 200))

func execute_base_attack(entity_node: combat_template):
	var chance_to_hit = calculate_evasion(entity_node)
	var chance = rng.randf_range(0, 1)

	if (chance * 100) <= chance_to_hit:
		return 5 * sqrt((obtain_stat(stats.ATTACK) / (entity_node.obtain_stat(stats.DEFENSE) + 1)) * (stored_combatant.stored_weapon.weapon_attack * obtain_stat_alteration(stats.ACCURACY))) * randf_range(0.95, 1.05)
	else:
		return "MISS"

func on_death():
	stored_combatant.is_dead = true
	enemy_collision.visible = false

	await get_tree().create_timer(0.5).timeout

	animated_sprite.play("On_Death")
	animated_sprite.speed_scale = 1.5
	animated_sprite.sprite_frames.set_animation_loop("On_Death", false)
	await animated_sprite.animation_finished
		
func execute_defend():
	is_defending = true

# Checks if you can click the entity to execute skill/attack
func do_nothing_3d(_camera, event, _event_position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and currently_selectable:
			parent_reference.confirmation.emit(child_number)

# Status Stuff
func handle_status(incoming_statuses):
	for key in conflicts.keys():
		var opposite = conflicts[key]
		if (incoming_statuses & key) and (all_active_effects & opposite):
			combatant_ui_.remove_active_status(opposite)
			_remove_active_status(opposite)
			incoming_statuses &= ~key
	for key in status_map:
		if incoming_statuses & key:
			if key <= statuses.AGRO and already_inflicted_with_major_status:
				for _status in active_statuses:
					if _status.status_type & key:
						_status.remaining_turns = 3
						break
			else:
				if (all_active_effects != 0) and (all_active_effects & key) == key:
					for _status in active_statuses:
						if _status.status_type & (incoming_statuses & key):
							_status.remaining_turns += 3
							break
				else:
					var add_status = status.new()
					add_status.status_type = key
					already_inflicted_with_major_status = true
					add_status.setup()
					if add_status.status_type < statuses.ATTACKdown:
						animated_sprite.modulate = status_color_chart[key]
					if add_status.status_type >= statuses.ATTACKdown:
						pass
					combatant_ui_.update_active_status(add_status)
					active_statuses.append(add_status)
					if all_active_effects == 0:
						all_active_effects = key
					else:
						all_active_effects |= key
	if not stored_combatant.is_combatant_enemy:
		parent_reference.get_player_portrait(child_number).update_statuses(parent_reference.get_player(child_number))

func check_if_status_is_there(statustype):
	if all_active_effects & statustype == 0:
		return false
	return true

func _remove_active_status(type_to_remove: int):
	all_active_effects &= ~type_to_remove 
	for i in range(active_statuses.size() - 1, -1, -1):
		if active_statuses[i].status_type == type_to_remove:
			active_statuses.remove_at(i)
			break

func take_turn(player_portrait: player_portraits = null):
	is_defending = false
	if all_active_effects != null:
		for key in status_map:
			if all_active_effects & key:
				status_map[key].call()
	if active_statuses != null:
		for _status in range(active_statuses.size()):
			active_statuses[_status].remaining_turns -= 1
			combatant_ui_.update_active_status(active_statuses[_status])
			if active_statuses[_status].remaining_turns == 0:
				if active_statuses[_status].status_type <= statuses.AGRO:
					already_inflicted_with_major_status = false
				combatant_ui_.remove_active_status(active_statuses[_status].status_type)
				_remove_active_status(active_statuses[_status].status_type)
				
	if not stored_combatant.is_combatant_enemy:
		player_portrait.update_statuses(self)

# Functions that run if status is active

func _apply_stun(): print("STUN")
func _apply_sleep(): print("SLEEP")
func _apply_shock(): print("SHOCK")
func _apply_poison(): 
	update_health(20, true)
	animated_sprite.modulate = Color.PURPLE

func _apply_burn(): 
	update_health(20, true)
	
func _apply_freeze(): print("FREEZE")
func _apply_agro(): print("AGRO")
func _apply_momentum(): print("momentum")
func _apply_regen():  print("regen")
func _apply_stun_imm():  print("stun imun")
func stat_does_nothing(): return

# Helper Functions
func obtain_stat(what_stat):
	match what_stat:
		# Attack
		0:
			var ret_stat = obtain_stat_alteration(stats.ATTACK)
			return stored_combatant.combatant_stats.attack * ret_stat if (ret_stat != 0) else 1
		# Defense
		1:
			var ret_stat = obtain_stat_alteration(stats.DEFENSE)
			return stored_combatant.combatant_stats.defense * ret_stat if (ret_stat != 0) else 1
		# Evasion
		3:
			var ret_stat = obtain_stat_alteration(stats.EVASION)
			return stored_combatant.combatant_stats.evasion * ret_stat if (ret_stat != 0) else 1
		# Crit Chance
		4:
			var ret_stat = obtain_stat_alteration(stats.CRIT_CHANCE)
			return ret_stat if (ret_stat != 0) else 1
		5: 
			var ret_stat = obtain_stat_alteration(stats.SPEED)
			return stored_combatant.combatant_stats.speed * ret_stat if (ret_stat != 0) else 1
		6:
			var ret_stat = obtain_stat_alteration(stats.ATTACK)
			return stored_combatant.combatant_stats.magic * ret_stat if (ret_stat != 0) else 1

func obtain_stat_alteration(what_stat):
	match what_stat:
		# Attack
		0:
			if all_active_effects & statuses.ATTACKup:
				return attack_up_down
			elif all_active_effects & statuses.ATTACKdown:
				return attack_up_down - 0.5
		# Defense
		1:
			if all_active_effects & statuses.DEFENSEup:
				return defense_up_down
			elif all_active_effects & statuses.DEFENSEdown:
				return defense_up_down - 0.5
		# Accuracy
		2:
			if all_active_effects & statuses.ACCURACYdown:
				return accuracy_up_down 
			elif all_active_effects & statuses.ACCURACYdown:
				return accuracy_up_down - 0.5
		# Evasion
		3:
			if all_active_effects & statuses.ATTACKup:
				return evasion_up_down
			elif all_active_effects & statuses.ATTACKdown:
				return evasion_up_down - 0.5
		# Crit Chance
		4:
			if all_active_effects & statuses.ATTACKup:
				return critchance_up_down
			elif all_active_effects & statuses.ATTACKdown:
				return critchance_up_down - 0.5
		# Speed / Slow
		5: 
			if all_active_effects & statuses.SLOW:
				return -20
	return 1

func could_be_selected():
	can_be_unselected = true
	currently_selectable = true
	if stored_combatant.is_combatant_enemy:
		enemy_collision.visible = true

func selected(can_be_unselected_):
	selection_area_sprite.visible = true
	currently_selectable = true
	selection_area_sprite.play("selectable")
	can_be_unselected = can_be_unselected_

func unselect():
	selection_area_sprite.visible = false
	selection_area_sprite.stop()

func can_no_longer_be_selected():
	unselect()
	currently_selectable = false
	can_be_unselected = true

#region States

func walk_towards_entity(node_to_walk_to):
	if node_to_walk_to != base_location:
		node_to_walk_to += displacement
	else:
		animated_sprite.flip_h = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "global_position", node_to_walk_to, 3)
	
	await tween.finished

func idle_animation():
	animated_sprite.flip_h = false
	animated_sprite.speed_scale = stored_combatant.idle_speed
	animated_sprite.play("Idle")
	animated_sprite.sprite_frames.set_animation_loop("Idle", true)

func walk_animation():
	animated_sprite.speed_scale = stored_combatant.walk_speed
	animated_sprite.play("Walk")
	animated_sprite.sprite_frames.set_animation_loop("Walk", true)

func attack_animation(what_attack_anim):
	var what_attack
	match what_attack_anim:
		0:
			what_attack = "On_Attack_1"
		1:
			what_attack = "On_Attack_2"
	animated_sprite.speed_scale = stored_combatant.attack_speed[what_attack_anim]
	animated_sprite.play(what_attack)
	animated_sprite.sprite_frames.set_animation_loop(what_attack, false)
	

#endregion

func _on_enemy_collision_mouse_entered():
	if currently_selectable and not stored_combatant.is_dead:
		selection_area_sprite.visible = true
		selection_area_sprite.play("selectable")
		if can_be_unselected:
			parent_reference.unselect_all(false if stored_combatant.is_combatant_enemy else true)
			parent_reference.select_individual(false if stored_combatant.is_combatant_enemy else true, child_number)

func _mouse_confirmation_given(_camera, event, _event_position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and currently_selectable:
			parent_reference.confirmation.emit(child_number)
