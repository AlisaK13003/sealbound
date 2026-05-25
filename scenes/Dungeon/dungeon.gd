extends Node3D

# temporary onboarding
@export var party_slot_1 : generic_combatants
@export var party_slot_2 : generic_combatants
@export var party_slot_3 : generic_combatants

@export var current_dungeon_run : dungeon_type

@onready var slot_1 = $Player_Container/Player_Slot1
@onready var slot_2 = $Player_Container/Player_Slot2
@onready var slot_3 = $Player_Container/Player_Slot3

@onready var player_container = $Player_Container

@onready var enemy_shit = $Enemy_Container

@onready var rng = RandomNumberGenerator.new()

var all_combatants : Array[generic_combatants] = []

var mana: int = 3
var max_mana: int = 3

var waiting_for_confirmation : bool = false
signal confirmation
signal action_taken
signal turn_ended
signal actual_confirmation

func _ready():
	slot_1.setup(party_slot_1, self, 0)
	slot_2.setup(party_slot_2, self, 1)
	slot_3.setup(party_slot_3, self, 2)

	all_combatants.append(party_slot_1)
	all_combatants.append(party_slot_2)
	all_combatants.append(party_slot_3)
	
	get_player_portrait(0)._setup(party_slot_1)
	get_player_portrait(1)._setup(party_slot_2)
	get_player_portrait(2)._setup(party_slot_3)
	
	battle_loop()

func battle_loop():
	print("BATTLE_STARTED")
	var turn_count = 0
	var is_wave_over : bool = false
	var number_of_waves_to_fight = rng.randi_range(current_dungeon_run.minimum_number_of_waves, current_dungeon_run.max_number_of_waves)
	for i in range(number_of_waves_to_fight):
		turn_count = 0
		is_wave_over = false
		select_next_wave()
		update_mana_display(1)
		$UI/Dungeon_Floor.text = current_dungeon_run.dungeon_name + "\n" + str(i + 1) + "F"

		while(not is_wave_over):
			turn_count += 1
			$"UI/Turn Counter".text = "Turn: " + str(turn_count)
			determine_order()
			for j in range(all_combatants.size()):
				var current_combatant = all_combatants[j]
				if current_combatant.is_dead:
					continue
				elif current_combatant.is_combatant_enemy:
					await execute_enemy_turn(current_combatant, turn_count)
				else:	
					await handle_player_move_selection(current_combatant)
				revert_to_default_UI()
				await get_tree().create_timer(0.75).timeout
				var number_of_alive_enemies = 0
				for enemy in enemy_shit.get_children():
					if enemy.stored_combatant == null:
						continue
					if not enemy.stored_combatant.is_dead:
						number_of_alive_enemies += 1
				if number_of_alive_enemies <= 0:
					is_wave_over = true
					break
		
func execute_enemy_turn(enemy_to_attack, turn_number):
	rng = RandomNumberGenerator.new()
	var action_selected = rng.randi_range(0,2)
	var player_to_attack = rng.randi_range(0,2)
	while(get_player(player_to_attack).stored_combatant.is_dead or get_player(player_to_attack).is_empty):
		player_to_attack = rng.randi_range(0,2)
	
	var attacking_enemy : int
	for enemy in enemy_shit.get_children():
		if enemy_to_attack == enemy.stored_combatant:
			attacking_enemy = enemy.get_index()
	enemy_shit.get_child(attacking_enemy).take_turn()
	action_selected = 0
	match action_selected:
		# Basic Attack
		0:
			var damage_to_deal = enemy_shit.get_child(attacking_enemy).execute_base_attack(get_player(player_to_attack))
			if await get_player(player_to_attack).update_health(damage_to_deal, false, get_player_portrait(player_to_attack)):
				get_player(player_to_attack).stored_combatant.is_dead = true
			set_health_bar_values(player_to_attack)
		1:
			pass
		2:
			pass

func handle_player_move_selection(current_combatant):
	var current_slot : int = 0
	for person in $Player_Container.get_children():
		if person.stored_combatant.combatant_name == current_combatant.combatant_name:
			current_slot = person.get_index()
	toggle_player_ui(current_slot)
	get_player(current_slot).combatant_ui_.update_skill_buttons(get_player(current_slot).stored_combatant, mana)
	var what_action = await action_taken
	toggle_player_ui(current_slot)
	match what_action[0]:
		"BASIC_ATTACK":
			var target_node = enemy_shit.get_child(what_action[1])
			var damage = get_player(current_slot).execute_base_attack(target_node)
			if await target_node.update_health(damage, false):
				target_node.stored_combatant.is_dead = true
		"BASIC_DEFEND":
			$Player_Container.get_child(current_slot).execute_defend()
			update_mana_display(2)
		"SKILL":
			execute_skills(current_slot, what_action)

		"ITEM":
			print("ITEM")
	get_player(current_slot).take_turn(get_player_portrait(current_slot))
	get_player_portrait(current_slot).update_statuses(get_player(current_slot))

func execute_skills(active_player, what_action):
	var current_player: combat_template = get_player(active_player)
	var skill_used: moves = current_player.stored_combatant.combatant_skills[what_action[2]]
	
	if skill_used.is_skill_aoe:
		# AOE skill that acts on party
		if skill_used.targets_party:
			# Does skill heal everyone in the party
			if skill_used.does_heal_party:
				for player: combat_template in player_container:
					if get_skill_boost(skill_used) != 999:
						player.update_health(-1 * (current_player.obtain_stat(current_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), false, get_player_portrait(active_player))
					else:
						player.update_health(-1 * current_player.stored_combatant.combatant_stats.max_health, false, get_player_portrait(active_player))
			# Does this skill apply a status to every party member
			if skill_used.does_status:
				for player: combat_template in player_container.get_children():
					player.handle_status(skill_used.status_type)
		# AOE skill that effects enemies
		else:
			for enemy: combat_template in enemy_shit.get_children():
				var chance = rng.randf_range(0, 1)
				calculate_multi_hit(skill_used, enemy, current_player, get_skill_boost(skill_used))
				if skill_used.does_status:
					chance = rng.randf_range(0, 1)
					if chance <= skill_used.chance_of_status_condition:
						enemy.handle_status(skill_used.status_type)
	else:
		if skill_used.targets_party:
			var targetted_player: combat_template = player_container.get_child(what_action[1])
			if skill_used.does_heal_party:
				if get_skill_boost(skill_used) != 999:
					targetted_player.update_health(-1 * (current_player.obtain_stat(active_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), false, get_player_portrait(active_player))
				else:
					targetted_player.update_health(-1 * current_player.stored_combatant.combatant_stats.max_health, false, get_player_portrait(active_player))
			if skill_used.does_status:
				targetted_player.handle_status(skill_used.status_type)
		else:
			var targetted_enemy = enemy_shit.get_child(what_action[1])
			var check_evasion = current_player.calculate_evasion(targetted_enemy, skill_used.accuracy)
			var chance = rng.randf_range(0, 1)
			if skill_used.does_status and chance <= skill_used.chance_of_status_condition:
				targetted_enemy.handle_status(skill_used.status_type)
			if skill_used.multi_hit:
				calculate_multi_hit(skill_used, targetted_enemy, current_player, get_skill_boost(skill_used))
			else:
				chance = rng.randf_range(0, 1)
				if chance <= check_evasion:
					var damage = calculate_damage(current_player, get_skill_boost(skill_used), targetted_enemy, skill_used.is_magic_skill)
					targetted_enemy.update_health(damage)
				else:
					targetted_enemy.update_health("MISS")
	update_mana_display(-1 * skill_used.mana_cost)
	
# Helper Functions
func get_player(player_to_get: int):
	return $Player_Container.get_child(player_to_get)

func get_player_portrait(portrait_to_get: int):
	return $UI/Party_Portraits/HBoxContainer.get_child(portrait_to_get)

func check_if_critical_hit(current_individual: combat_template):
	var chance_of_crit_hit = rng.randf_range(0,1)
	
	if chance_of_crit_hit <= (0.04 * current_individual.obtain_stat(current_individual.stats.CRIT_CHANCE)):
		return true
	else:
		return false

func calculate_damage(current_player, stat_boost, targetted_enemy, attack_or_magic):
	var correct_player_stat
	if attack_or_magic:
		correct_player_stat = current_player.stats.ATTACK
	else:
		correct_player_stat = current_player.stats.MAGIC
	
	var do_critical_hit = check_if_critical_hit(current_player)
	var attacker_atk = current_player.obtain_stat(correct_player_stat) + stat_boost
	var enemy_def = targetted_enemy.obtain_stat(current_player.stats.DEFENSE) + 1.0
	var weapon_pwr = current_player.stored_combatant.stored_weapon.weapon_attack + stat_boost
	var acc_mod = current_player.obtain_stat_alteration(current_player.stats.ACCURACY)

	var ratio = (attacker_atk / enemy_def) * (weapon_pwr * acc_mod)
	
	var damage = (5.0 * sqrt(max(0, ratio))) * (2 if do_critical_hit else 1)
	return (damage * randf_range(0.95, 1.05))

func calculate_multi_hit(skill_used, targetted_enemy, current_player, attack_boost):
	var check_evasion = current_player.calculate_evasion(targetted_enemy, skill_used.accuracy)
	var chance = rng.randf_range(0, 1)
	for hit in range(skill_used.max_hit_count):
		if hit < skill_used.guaranteed_hit_count:
			targetted_enemy.update_health(calculate_damage(current_player, attack_boost, targetted_enemy, skill_used.is_magic_skill))
		else:
			chance = rng.randf_range(0, 1)
			if chance <= check_evasion:
				targetted_enemy.update_health(calculate_damage(current_player, attack_boost, targetted_enemy, skill_used.is_magic_skill))
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

func determine_order():
	all_combatants.clear()
	
	for slot in $Player_Container.get_children():
		all_combatants.append(slot.stored_combatant)
	for enemy_slot in enemy_shit.get_children():
		if enemy_slot.visible:
			all_combatants.append(enemy_slot.stored_combatant)
	
	all_combatants.sort_custom(func(a, b):
		return a.combatant_stats.altered_speed > b.combatant_stats.altered_speed
	)

func select_next_wave():
	update_mana_display(3)
	var number_of_possible_waves = current_dungeon_run.potential_waves.size()
	var random_wave = rng.randi_range(0, number_of_possible_waves - 1)
	var enemy_count_for_current_wave = current_dungeon_run.potential_waves[random_wave].enemies.size()
	for i in range(enemy_shit.get_child_count()):
		if i >= enemy_count_for_current_wave:
			enemy_shit.get_child(i).visible = false
			continue
		else:
			enemy_shit.get_child(i).visible = true
		enemy_shit.get_child(i).setup(current_dungeon_run.potential_waves[random_wave].enemies[i].duplicate(true), self, i)
		all_combatants.append(current_dungeon_run.potential_waves[random_wave].enemies[i].duplicate(true))

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
	get_player_portrait(player_to_set_for).get_node("Health_Num").text = str(get_player(player_to_set_for).stored_combatant.combatant_stats.health) + "/" + str(get_player(player_to_set_for).stored_combatant.combatant_stats.max_health)

# Buttons
func attack_button_pressed():
	for enemy in enemy_shit.get_children():
		enemy.could_be_selected()
	var action_on_who = await confirmation
	revert_to_default_UI()
	enemy_shit.get_child(action_on_who).could_be_selected()
	setup_confirmation_button("Attack", enemy_shit.get_child(action_on_who).stored_combatant.combatant_name)
	var confirmed = await actual_confirmation
	if confirmed:
		action_taken.emit("BASIC_ATTACK", action_on_who)
	revert_to_default_UI()
			
func defend_button_pressed(stored_combatant_name):
	setup_confirmation_button("Defend", stored_combatant_name)
	var confirmed = await actual_confirmation
	if confirmed:
		action_taken.emit("BASIC_DEFEND", false)
	revert_to_default_UI()
	
func skill_selected(what_skill, what_player):
	var skill_to_use: moves = get_player(what_player).stored_combatant.combatant_skills[what_skill]
	if skill_to_use.targets_party:
		if skill_to_use.is_skill_aoe:
			for player in player_container.get_children():
				player.could_be_selected()
		else:
			get_player(what_player).could_be_selected()
	else:
		for enemy in enemy_shit.get_children():
			enemy.could_be_selected()
		
	var action_on_who = await confirmation
	if not skill_to_use.is_skill_aoe:
		if skill_to_use.targets_party:
			setup_confirmation_button(skill_to_use.move_name, get_player(what_player).stored_combatant.combatant_name)
		else:
			setup_confirmation_button(skill_to_use.move_name, enemy_shit.get_child(action_on_who).combatant_name)
	else:
		if skill_to_use.targets_party:
			setup_confirmation_button(skill_to_use.move_name, "entire party")
		else:
			setup_confirmation_button(skill_to_use.move_name, "every enemy")

	var confirmed = await actual_confirmation
	if confirmed:
		action_taken.emit("SKILL", action_on_who, what_skill)
	revert_to_default_UI()

func confirmation_button(event, confirm_or_deny):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			actual_confirmation.emit(confirm_or_deny)

func setup_confirmation_button(move_name, entity_used_on_name):
	$UI/Confirmation.visible = true
	var question_label = $UI/Confirmation/Label
	question_label.text = "Use " + move_name + " on " + entity_used_on_name + "?"

func revert_to_default_UI():
	for enemy in enemy_shit.get_children():
		enemy.undo_selection()
	for player in player_container.get_children():
		player.undo_selection()
	$UI/Confirmation.visible = false
		
func hide_everything():
	revert_to_default_UI()

func update_mana_display(mana_used_or_gained):
	mana = clamp(mana + mana_used_or_gained, 0, 3)
	$"UI/Mana Bar/Label".text = str(mana) + "/" + str(max_mana) 
