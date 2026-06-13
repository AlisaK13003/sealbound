extends Node

class_name dungeon_helper

@onready var rng = RandomNumberGenerator.new()

func hide_player_UI(what_player):
	get_player(what_player).combatant_ui_.visible = false

func revert_to_default_UI(enemy_container, player_container):
	for enemy in enemy_container.get_children():
		enemy.combatant_ui_.reset_ui()
	for player in player_container.get_children():
		player.combatant_ui_.reset_ui()
	unhighlight_all_entities(enemy_container, player_container)
	$UI/Confirmation.visible = false
	$UI/ItemNode.visible = false

func unhighlight_all_entities(enemy_container, player_container):
	for enemy in enemy_container.get_children():
		enemy.undo_selection()
	for player in player_container.get_children():
		player.undo_selection()

func highlight_players(player_container):
	for player in player_container.get_children():
		if player.currently_selectable:
			return false
		player.could_be_selected()
	return true
		
func highlight_enemies(enemy_container):
	var ret_val = true
	for enemy in enemy_container.get_children():
		if enemy.currently_selectable:
			ret_val = false
		enemy.could_be_selected()
	return ret_val

func only_highlight_necessary(is_player, what_entity, enemy_container, player_container):
	unhighlight_all_entities(enemy_container, player_container)
	if is_player:
		if what_entity == 3:
			highlight_players(player_container)
		else:
			get_player(what_entity).could_be_selected()
	else:
		if what_entity == 5:
			highlight_enemies(enemy_container)
		else:
			enemy_container.get_child(what_entity).could_be_selected()

func hide_everything(enemy_container, player_container):
	revert_to_default_UI(enemy_container, player_container)

func update_mana_display(mana, max_mana, mana_used_or_gained, mana_label):
	mana = clamp(mana + mana_used_or_gained, 0, 3)
	mana_label.text = str(mana) + "/" + str(max_mana)
	return mana

@onready var camera: Camera3D = $Camera3D

@export var original_fov: float = 15.0 
@export var min_fov: float = 8.0      
@export var padding: float = 0.5       
@export var border_size: float = 0.01   

func sci_fi_enhance_zoom(values: Array):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(camera, "h_offset", values[0], values[3])
	tween.tween_property(camera, "v_offset", values[1], values[3])
	tween.tween_property(camera, "fov", values[2], values[3])
	
	await tween.finished

func get_camera_offset(is_player, what_entity):
	if not is_player:
		if what_entity == 6:
			return [0.5, 0.0, 10, 1.0]
		else:
			match what_entity:
				0:
					return [0.1, -0.125, 8.0, 1.0]
					
				1:
					return [0.75, -0.125, 8.0, 1.0]
				2:
					return [0.4, -0.125, 8.0, 1.0]
				3:
					return [0.15, -0.125, 8.0, 1.0]
				4:
					return [-0.05, -0.125, 8.0, 1.0]
	else:
		if what_entity == 4:
			return [-1.03, -0.13, 6.0, 1.0]
		else:
			match what_entity:
				0:
					return [-0.75, 0, 8.0, 1.0]
				1:
					return [-1.0, 0, 8.0, 1.0]
				2:
					return [-1.25, 0, 8.0, 1.0]

func revert_camera(duration: float):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(camera, "h_offset", 0.0, duration)
	tween.tween_property(camera, "v_offset", 0.0, duration)
	tween.tween_property(camera, "fov", original_fov, duration)

func setup_confirmation_button(move_name, entity_used_on_name, used_on):
	if used_on is combat_template:
		if used_on.stored_combatant.is_combatant_enemy:
			sci_fi_enhance_zoom(get_camera_offset(false, used_on.child_number))
		else:
			sci_fi_enhance_zoom(get_camera_offset(true, used_on.child_number))
	elif used_on == 4:
		sci_fi_enhance_zoom(get_camera_offset(true, 4))
	elif used_on == 5:
		sci_fi_enhance_zoom(get_camera_offset(false, 6))
	$UI/Confirmation.visible = true
	var question_label = $UI/Confirmation/Label
	question_label.text = "Use " + move_name + " on " + entity_used_on_name + "?"

func calculate_multi_hit(skill_used: moves, targetted_enemy, current_player, attack_boost):
	var check_evasion = current_player.calculate_evasion(targetted_enemy, skill_used.accuracy)
	var chance = rng.randf_range(0, 1)
	for hit in range(skill_used.max_hit_count):
		if hit < skill_used.guaranteed_hit_count:
			await deal_damage(current_player, targetted_enemy, true, skill_used)
		else:
			chance = rng.randf_range(0, 1)
			if chance <= check_evasion:
				await deal_damage(current_player, targetted_enemy, true, skill_used)
			else:
				targetted_enemy.update_health("MISS")

func get_skill_boost(skill_used: moves):
	var attack_boost = 0
	var magic_boost = 0
	if not skill_used.is_magic_skill:
		match skill_used.attack_power:
			0:
				attack_boost = 100
			1:
				attack_boost = 180
			2:
				attack_boost = 300
		return attack_boost
	else:
		match skill_used.amount_healed:
			0:
				magic_boost = 20
			1:
				magic_boost = 40
			2:
				magic_boost = 999
		return magic_boost

func deal_damage(entity_attacking, entity_being_attacked, was_a_skill_used, what_skill_was_used: moves):
	if was_a_skill_used:
		if what_skill_was_used.multi_hit:
			await calculate_multi_hit(what_skill_was_used, entity_being_attacked, entity_attacking, get_skill_boost(what_skill_was_used))
		else:
			await entity_being_attacked.update_health(calculate_damage(entity_attacking, get_skill_boost(what_skill_was_used), entity_being_attacked, what_skill_was_used.is_magic_skill, what_skill_was_used.accuracy))
	else:
		pass
	
	pass

func determine_order(all_combatants, enemy_container):
	all_combatants.clear()
	
	for slot in $Player_Container.get_children():
		all_combatants.append(slot)
	for enemy_slot in enemy_container.get_children():
		if enemy_slot.visible:
			all_combatants.append(enemy_slot)
	
	all_combatants.sort_custom(func(a, b):
		return a.obtain_stat(5) > b.obtain_stat(5)
	)

func select_next_wave(mana, max_mana, mana_label, all_combatants, enemy_container, current_dungeon_run):
	update_mana_display(mana, max_mana, 3, mana_label)
	var number_of_possible_waves = current_dungeon_run.potential_waves.size()
	var random_wave = rng.randi_range(0, number_of_possible_waves - 1)
	var enemy_count_for_current_wave = current_dungeon_run.potential_waves[random_wave].enemies.size()
	for i in range(enemy_container.get_child_count()):
		if i >= enemy_count_for_current_wave:
			enemy_container.get_child(i).visible = false
			continue
		else:
			enemy_container.get_child(i).visible = true
		enemy_container.get_child(i).setup(current_dungeon_run.potential_waves[random_wave].enemies[i].duplicate(true), self, i)
		all_combatants.append(enemy_container.get_child(i))

func toggle_player_ui(player_to_toggle):
	if not get_player(player_to_toggle).combatant_ui.visible:
		get_player(player_to_toggle).combatant_ui.visible = true
		get_player(player_to_toggle).combatant_ui_area.visible = true
	else:
		get_player(player_to_toggle).combatant_ui.visible = false
		get_player(player_to_toggle).combatant_ui_area.visible = false
		get_player(player_to_toggle).reset_ui()

func set_health_bar_values(player_to_set_for):
	get_player_portrait(player_to_set_for).get_node("HealthBar").value = get_player(player_to_set_for).stored_combatant.combatant_stats.health
	get_player_portrait(player_to_set_for).get_node("Health_Num").text = str(get_player(player_to_set_for).stored_combatant.combatant_stats.health)

# Helper Functions
func get_player(player_to_get: int):
	return $Player_Container.get_child(player_to_get)

func get_player_portrait(portrait_to_get: int):
	return $UI/Party_Portraits/VBoxContainer.get_child(portrait_to_get)

func check_if_critical_hit(current_individual: combat_template):
	var chance_of_crit_hit = rng.randf_range(0,1)
	
	if chance_of_crit_hit <= (0.04 * current_individual.obtain_stat(current_individual.stats.CRIT_CHANCE)):
		return true
	else:
		return false

func calculate_damage(current_player: combat_template, stat_boost, targetted_enemy, attack_or_magic, _skill_accuracy = 1):
	var correct_player_stat
	if attack_or_magic:
		correct_player_stat = current_player.stats.ATTACK
	else:
		correct_player_stat = current_player.stats.MAGIC
	
	var do_critical_hit = check_if_critical_hit(current_player)
	var attacker_atk = current_player.obtain_stat(correct_player_stat) + stat_boost
	var enemy_def = targetted_enemy.obtain_stat(current_player.stats.DEFENSE) + 1.0
	var weapon_pwr = current_player.stored_combatant.stored_weapon.weapon_attack + stat_boost
	# var acc_mod = current_player.obtain_stat_alteration(current_player.stats.ACCURACY) * ((float(skill_accuracy) / 100) if skill_accuracy != 1 else 1)
	var ratio = (attacker_atk / enemy_def) * (weapon_pwr if not current_player.stored_combatant.is_combatant_enemy else 1) #* acc_mod)
	
	var damage = (5.0 * sqrt(max(0, ratio))) * (2 if do_critical_hit else 1)
	var retval = [damage * randf_range(0.95, 1.05), 1 if do_critical_hit else 0]
	return retval
