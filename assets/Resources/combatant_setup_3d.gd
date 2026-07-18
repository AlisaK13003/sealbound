extends Node3D

class_name combat_template

#region Variables

@onready var combatant_ui_: combatant_ui = $Sprite3D2/SubViewport/CombatantUi
@onready var status_sprite = load("res://assets/tile sheets/Up_Arrow.png")
@onready var enemy_collision = $Sprite3D2/Enemy_Collision
@onready var selection_area_sprite = $Sprite3D2/AnimatedSprite3D
@onready var animated_sprite = $AnimatedSprite3D2
@onready var ui_sprite = $Sprite3D2
@onready var rng = RandomNumberGenerator.new()
@onready var animator = SpriteFrames.new()
@onready var animation_player = $AnimationPlayer

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
var current_mana = 3

var is_dead: bool = false

var time_until_turn

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

enum stats {ATTACK, DEFENSE, ACCURACY, EVASION, CRIT_CHANCE, SPEED, MAGIC, RESISTANCE}

#endregion

var has_been_setup: bool = false

func setup(combatant : generic_combatants, parent_ref, child_num):
	if combatant == null:
		is_empty = true
		return
	
	parent_reference = parent_ref
	child_number = child_num
	base_location = self.global_position
	for status_ in active_statuses:
		combatant_ui_.remove_active_status(status_)
		_remove_active_status(status_.status_type)
		
	all_active_effects = 0
	active_statuses.clear()
	if not combatant.is_combatant_enemy:
		parent_ref.gui.get_player_portrait(child_num).update_statuses(self)
	is_defending = false
	stored_combatant = combatant
	if stored_combatant.is_combatant_enemy:
		stored_combatant.gather_actual_stats()
	combatant_ui_.setup(parent_ref, stored_combatant, all_active_effects)

	time_until_turn = 10000.0 / obtain_stat(stats.SPEED)

	animated_sprite.offset = combatant.sprite_offset
	animated_sprite.modulate = Color.WHITE
	current_mana = 3
	animated_sprite.flip_h = combatant.should_flip_sprite
	if combatant.is_combatant_enemy:
		currently_selectable = true
	else:
		combatant_ui_.get_node("TextureProgressBar").visible = false
		# combatant_sprite.texture = combatant.combatant_sprite
	animated_sprite.sprite_frames = combatant.sprite_frames
	animated_sprite.pixel_size = stored_combatant.sprite_scale
	animated_sprite.speed_scale = stored_combatant.idle_speed
	animated_sprite.frame = (rng.randi_range(0, (animated_sprite.sprite_frames.get_frame_count("Idle")) - 1))
	animated_sprite.play("Idle")
	has_been_setup = true
	selection_area_sprite.position = self.global_position
	selection_area_sprite.offset = Vector2(-35, 45)
	
	
func update_health(change_health_value, what_action = null):
	if what_action != null and what_action != "MISS":
		if change_health_value > 0:
			AudioManager.play_ui_sound(AudioManager.BATTLE_DEAL_DAMAGE)
		elif change_health_value <= 0:
			AudioManager.play_ui_sound(AudioManager.BATTLE_HEAL)

	var update_portrait = parent_reference.gui.get_player_portrait(child_number) if not stored_combatant.is_combatant_enemy else null
	if what_action != "STATUS":
		if what_action == "MISS":
			await combatant_ui_.update_damage_label(0, "MISS")
		elif what_action == "MULTI":
			var current_damage = int(ceil(change_health_value[0]))
			while(current_damage is int or current_damage != "MISS"):
				if is_defending and change_health_value > 0:
					update_portrait._update_health(current_damage * 0.6)
					stored_combatant.take_damage(-1 * current_damage * 0.6)
					await combatant_ui_.update_damage_label(current_damage * 0.6, what_action)
				else:
					if update_portrait != null:
						update_portrait._update_health(current_damage)
					stored_combatant.take_damage(-1 * current_damage)

					await combatant_ui_.update_damage_label(current_damage, what_action)
				await get_tree().create_timer(1.5).timeout
				change_health_value.pop_front()
				if change_health_value.size() == 0:
					break
				current_damage = change_health_value[0]
				if current_damage is String:
					if current_damage == "MISS":
						break
					elif current_damage.size() == 0:
						break
		else:
			var damage_to_take = int(ceili(change_health_value))
			if is_defending:
				update_portrait._update_health(damage_to_take * 0.6)
				stored_combatant.take_damage(-1 * damage_to_take * 0.6) 
				await combatant_ui_.update_damage_label(damage_to_take * 0.6, what_action)
			else:
				if update_portrait != null:
					update_portrait._update_health(damage_to_take)
				stored_combatant.take_damage(-1 * damage_to_take)

				await combatant_ui_.update_damage_label(damage_to_take, what_action)
	else:
		var damage_to_take = int(ceili(change_health_value))
		if not stored_combatant.is_combatant_enemy:
			parent_reference.gui.get_player_portrait(child_number)._update_health(damage_to_take)
			stored_combatant.take_damage(-1 * damage_to_take)

		await combatant_ui_.update_damage_label(damage_to_take, what_action)

	if stored_combatant.actual_stats.health <= 0:
		await on_death()
	if not parent_reference.training:	
		await get_tree().create_timer(0.5).timeout
	

# Combat related stuff

func use_item(which_item):
	animated_sprite.play("Use_Item")	
	combatant_ui_.play_use_item_animation(which_item)
	await combatant_ui_.animation_player.animation_finished
	return

func on_death():
	parent_reference.someone_is_dying = true
	stored_combatant.is_dead = true
	is_dead = true
	enemy_collision.visible = false
	all_active_effects = 0
	for status_ in active_statuses:
		_remove_active_status(status_.status_type)
	active_statuses.clear()
	stored_combatant.is_dead = true
	if not parent_reference.training:		
		if stored_combatant.is_combatant_enemy:
			combatant_ui_.visible = false
			animation_player.play("On_Death")
			parent_reference.killed_enemies.append(stored_combatant)
			await animation_player.animation_finished
		else:
			animated_sprite.play("On_Death")
			animated_sprite.speed_scale = 1.5
			animated_sprite.sprite_frames.set_animation_loop("On_Death", false)
			if stored_combatant.is_MC:
				parent_reference.main_character_died.emit()
				parent_reference.turn_ended.emit()
			await get_tree().create_timer(1.0).timeout
	if not stored_combatant.is_combatant_enemy:
		parent_reference.gui.get_player_portrait(child_number).update_statuses(self)
	else:
		parent_reference.gui.update_bond_attack(0.5)
		
	parent_reference.finished_dying.emit()
	parent_reference.someone_is_dying = false
	animated_sprite.modulate = Color.WHITE
	if stored_combatant.is_combatant_enemy:
		self.visible = false
	
	
func execute_defend():
	is_defending = true
	animated_sprite.play("On_Defend")

# Checks if you can click the entity to execute skill/attack
func do_nothing_3d(_camera, event, _event_position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and currently_selectable:
			parent_reference.confirmation.emit(child_number)

# Status Stuff
func handle_status(incoming_statuses, turn_limit):
	for key in conflicts.keys():
		var opposite = conflicts[key]
		if (incoming_statuses & key) and (all_active_effects & opposite):
			combatant_ui_.remove_active_status(opposite)
			parent_reference.gui.get_player_portrait(child_number).update_statuses(parent_reference.get_player(child_number))
			_remove_active_status(opposite)
			incoming_statuses &= ~key
	for key in status_map:
		if incoming_statuses & key:
			if key <= statuses.AGRO and already_inflicted_with_major_status:
				for _status in active_statuses:
					if _status.status_type & key:
						_status.remaining_turns = turn_limit
						AudioManager.play_ui_sound(AudioManager.STATUS_SOUND)
						break
			else:
				if (all_active_effects != 0) and (all_active_effects & key) == key:
					for _status in active_statuses:
						if _status.status_type & (incoming_statuses & key):
							if _status.status_type < statuses.ATTACKdown:
								parent_reference.gui.update_bond_attack(0.5)
							_status.remaining_turns += turn_limit
							AudioManager.play_ui_sound(AudioManager.STATUS_SOUND)
							break
				else:
					var add_status = status.new()
					AudioManager.play_ui_sound(AudioManager.STATUS_SOUND)
					add_status.status_type = key
					already_inflicted_with_major_status = true
					add_status.setup(turn_limit)
					if add_status.status_type < statuses.ATTACKdown:
						if stored_combatant.is_combatant_enemy:
							parent_reference.gui.update_bond_attack(0.5)
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
		parent_reference.gui.get_player_portrait(child_number).update_statuses(parent_reference.get_player(child_number))

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
	if stored_combatant.is_combatant_enemy:
		current_mana += 1
	is_defending = false
	if all_active_effects != null:
		for key in status_map:
			if all_active_effects & key:
				status_map[key].call()
	if active_statuses != null:
		for _status in range(active_statuses.size() - 1, -1, -1):
			active_statuses[_status].remaining_turns -= 1
			combatant_ui_.update_active_status(active_statuses[_status])
			if active_statuses[_status].status_type == statuses.POISON:
				AudioManager.play_ui_sound(AudioManager.STATUS_SOUND)
			elif active_statuses[_status].status_type == statuses.DEFENSEup:
				AudioManager.play_ui_sound(AudioManager.BATTLE_DEF_UP)
			elif active_statuses[_status].status_type == statuses.ATTACKup:
				AudioManager.play_ui_sound(AudioManager.BATTLE_ATK_UP)
			else:
				AudioManager.play_ui_sound(AudioManager.BATTLE_GENERIC_STAT)
				
			if active_statuses[_status].remaining_turns == 0:
				if active_statuses[_status].status_type <= statuses.AGRO:
					already_inflicted_with_major_status = false
				combatant_ui_.remove_active_status(active_statuses[_status].status_type)
				_remove_active_status(active_statuses[_status].status_type)
				
	if not stored_combatant.is_combatant_enemy:
		await player_portrait.update_statuses(self)

# Functions that run if status is active

# Helper Functions
func obtain_stat(what_stat):
	match what_stat:
		# Attack
		0:
			var ret_stat = obtain_stat_alteration(stats.ATTACK)
			return stored_combatant.actual_stats.attack * ret_stat if (ret_stat != 0) else 1
		# Defense
		1:
			var ret_stat = obtain_stat_alteration(stats.DEFENSE)
			return stored_combatant.actual_stats.defense * ret_stat if (ret_stat != 0) else 1
		# Evasion
		3:
			var ret_stat = obtain_stat_alteration(stats.EVASION)
			return stored_combatant.actual_stats.evasion * ret_stat if (ret_stat != 0) else 1
		# Crit Chance
		4:
			var ret_stat = obtain_stat_alteration(stats.CRIT_CHANCE)
			return (ret_stat * stored_combatant.actual_stats.luck) if (ret_stat != 0) else 1
		5: 
			var ret_stat = obtain_stat_alteration(stats.SPEED)
			return stored_combatant.actual_stats.speed * ret_stat if (ret_stat != 0) else 1
		6:
			var ret_stat = obtain_stat_alteration(stats.ATTACK)
			return stored_combatant.actual_stats.magic * ret_stat if (ret_stat != 0) else 1
		7:
			return stored_combatant.actual_stats.resistance

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
	parent_reference.gui.update_selection_section(self)

func unselect():
	selection_area_sprite.visible = false
	selection_area_sprite.stop()

func can_no_longer_be_selected():
	unselect()
	currently_selectable = false
	can_be_unselected = true

func empty():
	stored_combatant = null

#region States

func walk_towards_entity(node_to_walk_to):
	if node_to_walk_to != base_location:
		if stored_combatant.is_combatant_enemy:
			node_to_walk_to += displacement
		else:
			node_to_walk_to -= displacement
	else:
		if stored_combatant.is_combatant_enemy:
			animated_sprite.flip_h = true
	var tween = create_tween()

	tween.tween_property(self, "global_position", node_to_walk_to, 2)
	
	await tween.finished
	if not stored_combatant.is_combatant_enemy and node_to_walk_to == base_location:
		animated_sprite.flip_h = false

func idle_animation():
	animated_sprite.flip_h = stored_combatant.should_flip_sprite
	animated_sprite.speed_scale = stored_combatant.idle_speed
	animated_sprite.play("Idle")
	animated_sprite.sprite_frames.set_animation_loop("Idle", true)

func walk_animation(walk_left = null):
	if walk_left != null:
		if walk_left:
			animated_sprite.speed_scale = stored_combatant.walk_speed
			animated_sprite.play("Walk_Left")
			animated_sprite.sprite_frames.set_animation_loop("Walk_Left", true)
		else:
			animated_sprite.speed_scale = stored_combatant.walk_speed
			animated_sprite.play("Walk_Right")
			animated_sprite.sprite_frames.set_animation_loop("Walk_Right", true)
	else:
		animated_sprite.speed_scale = stored_combatant.walk_speed
		animated_sprite.play("Walk")
		animated_sprite.sprite_frames.set_animation_loop("Walk", true)

func attack_animation(what_attack_anim):
	var what_attack
	match what_attack_anim:
		0:
			what_attack = "On_Attack_Base"
		1:
			what_attack = "On_Attack_1"
		2:
			what_attack = "On_Attack_2"
		_:
			what_attack = "On_Attack_Base"
	if stored_combatant.attack_speed.size() > 0:
		animated_sprite.speed_scale = stored_combatant.attack_speed[what_attack_anim if what_attack_anim <= 1 else 0]
		animated_sprite.play(what_attack)
		animated_sprite.sprite_frames.set_animation_loop(what_attack, false)
		await animated_sprite.animation_finished

	animated_sprite.play("Idle")
	animated_sprite.speed_scale = stored_combatant.idle_speed
	
#endregion

func _on_enemy_collision_mouse_entered():
	print("ENTERED")
	if not has_been_setup:
		return
	if currently_selectable and not stored_combatant.is_dead :
		selection_area_sprite.visible = true
		selection_area_sprite.play("selectable")
		if can_be_unselected:
			parent_reference.unselect_all()
			parent_reference.select_individual(false if stored_combatant.is_combatant_enemy else true, child_number)

func _mouse_confirmation_given(_camera, event, _event_position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and currently_selectable:
			parent_reference.confirmation.emit(child_number)

func _apply_stun(): print("STUN")
func _apply_sleep(): print("SLEEP")
func _apply_shock(): print("SHOCK")
func _apply_freeze(): print("FREEZE")
func _apply_agro(): print("AGRO")
func _apply_momentum(): print("momentum")
func _apply_stun_imm():  print("stun imun")
func _apply_poison(): 
	update_health(int(stored_combatant.actual_stats.max_health * 0.125), "STATUS")
	animated_sprite.modulate = Color.PURPLE
func _apply_burn(): 
	update_health(int(stored_combatant.actual_stats.max_health * 0.16), "STATUS")
	animated_sprite.modulate = Color.FIREBRICK
func _apply_regen():  
	update_health(int(-1 * stored_combatant.actual_stats.max_health * 0.125), "STATUS")
	
func stat_does_nothing(): return
