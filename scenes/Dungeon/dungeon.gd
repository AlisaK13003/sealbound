extends Node

@export var party_slot_1 : generic_combatants
@export var party_slot_2: generic_combatants
@export var party_slot_3: generic_combatants

@export var current_dungeon_run : dungeon_type

@export var temp_item_list : Array[Items]

@onready var slot_1 = $Player_Container/Player_Slot1
@onready var slot_2 = $Player_Container/Player_Slot2
@onready var slot_3 = $Player_Container/Player_Slot3

@onready var player_container = $Player_Container

@onready var enemy_shit = $Enemy_Container

@onready var item_menu = $UI/DungeonItemMenu
@onready var selected_item = $UI/ItemNode

@onready var rng = RandomNumberGenerator.new()

var all_combatants : Array[combat_template] = []

var mana: int = 3
var max_mana: int = 3

var current_run_id = 0

var waiting_for_confirmation : bool = false
signal confirmation
signal action_taken
signal turn_ended
signal actual_confirmation

func _ready():
	slot_1.setup(party_slot_1, self, 0)
	slot_2.setup(party_slot_2, self, 1)
	slot_3.setup(party_slot_3, self, 2)

	all_combatants.append(slot_1)
	all_combatants.append(slot_2)
	all_combatants.append(slot_3)
	
	get_player_portrait(0)._setup(party_slot_1)
	get_player_portrait(1)._setup(party_slot_2)
	get_player_portrait(2)._setup(party_slot_3)
	
	item_menu.setup(temp_item_list, self)
	
	battle_loop()

func setup(active_combatants: Array[generic_combatants], current_dungeon_type: dungeon_type, current_item_list: Array[Items]):
	current_dungeon_run = current_dungeon_type
	temp_item_list = current_item_list
		
	slot_1.setup(active_combatants[0], self, 0)
	slot_2.setup(active_combatants[1], self, 1)
	slot_3.setup(active_combatants[2], self, 2)

	all_combatants.append(slot_1)
	all_combatants.append(slot_2)
	all_combatants.append(slot_3)
	
	get_player_portrait(0)._setup(active_combatants[0])
	get_player_portrait(1)._setup(active_combatants[1])
	get_player_portrait(2)._setup(active_combatants[2])
	
	item_menu.setup(temp_item_list, self)
	
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
				item_menu.update_item_list(temp_item_list)
				var current_combatant = all_combatants[j]
				if current_combatant.stored_combatant.is_dead:
					continue
				elif current_combatant.stored_combatant.is_combatant_enemy:
					await execute_enemy_turn(current_combatant.stored_combatant, turn_count)
				else:	
					await handle_player_move_selection(current_combatant.stored_combatant)
				revert_to_default_UI()
				await get_tree().create_timer(0.75).timeout
				var number_of_alive_enemies = 0
				for enemy in enemy_shit.get_children():
					if enemy.stored_combatant == null:
						continue
					if not enemy.stored_combatant.is_dead:
						number_of_alive_enemies += 1
						
				await get_tree().create_timer(1).timeout
				if number_of_alive_enemies <= 0:
					is_wave_over = true
					break
	print("BATTLE FINISHED")
	
func execute_enemy_turn(enemy_to_attack, _turn_number):
	print("ACTING")
	rng = RandomNumberGenerator.new()
	var action_selected = rng.randi_range(0,2)
	var player_to_attack = rng.randi_range(0,2)
	while(get_player(player_to_attack).stored_combatant.is_dead or get_player(player_to_attack).is_empty):
		player_to_attack = rng.randi_range(0,2)
	
	var attacking_enemy: combat_template
	for enemy in enemy_shit.get_children():
		if enemy_to_attack == enemy.stored_combatant:
			attacking_enemy = enemy_shit.get_child(enemy.get_index())
	await attacking_enemy.take_turn()
	action_selected = 0
	match action_selected:
		# Basic Attack
		0:
			var damage_to_deal = calculate_damage(attacking_enemy, attacking_enemy.obtain_stat(attacking_enemy.stats.ATTACK), get_player(player_to_attack), true)
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
	var action_sequence: Array[Callable]
	toggle_player_ui(current_slot)
	match what_action[0]:
		"BASIC_ATTACK":
			var target_node = enemy_shit.get_child(what_action[1])
			var damage = get_player(current_slot).execute_base_attack(target_node)
			action_sequence.append(func(): await target_node.update_health([damage, ""], false))
		"BASIC_DEFEND":
			action_sequence.append(func(): await get_player(current_slot).execute_defend())
			update_mana_display(2)
		"SKILL":
			action_sequence.append(func(): await execute_skills(current_slot, what_action))

		"ITEM":
			action_sequence = [
				func(): execute_item(temp_item_list[what_action[2]], what_action[1], what_action[2])
			]
	await action_queue(action_sequence)
	await get_player(current_slot).take_turn(get_player_portrait(current_slot))
	get_player_portrait(current_slot).update_statuses(get_player(current_slot))

func execute_skills(active_player, what_action):
	var current_player: combat_template = get_player(active_player)
	var skill_used: moves = current_player.stored_combatant.combatant_skills[what_action[2]]
	var action_sequence : Array[Callable]
	var parallel_tasks : Array[Callable]
	if skill_used.is_skill_aoe:
		# AOE skill that acts on party
		if skill_used.targets_party:
			# Does skill heal everyone in the party
			var par_task: Array[Callable]
			for player: combat_template in player_container.get_children():
				if skill_used.does_heal_party:
					if get_skill_boost(skill_used) != 999:
						par_task.append(func(): await player.update_health([-1 * (current_player.obtain_stat(current_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL"], false, get_player_portrait(player.get_index())))
						#player.update_health([-1 * (current_player.obtain_stat(current_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL"], false, get_player_portrait(active_player))
					else:
						par_task.append(func(): await player.update_health([-1 * player.stored_combatant.combatant_stats.max_health, "HEAL"], false, get_player_portrait(player.get_index())))
						#player.update_health([-1 * current_player.stored_combatant.combatant_stats.max_health, "HEAL"], false, get_player_portrait(active_player))
				# Does this skill apply a status to every party member
				if skill_used.does_status:
					par_task.append(func(): await player.handle_status(skill_used.status_type))
					#player.handle_status(skill_used.status_type)
				if skill_used.does_remove_status:
					par_task.append(func(): await player.remove_status(skill_used.removes_status))
					#player.remove_status(skill_used.removes_status)
			action_sequence.append(func(): await await_parallel(par_task))
		# AOE skill that effects enemies
		else:
			var par_tasks: Array[Callable]
			for enemy: combat_template in enemy_shit.get_children():
				var chance = rng.randf_range(0, 1)
				par_tasks.append(func(): await deal_damage(current_player, enemy, true, skill_used))
				#await deal_damage(current_player, enemy, true, skill_used)

				if skill_used.does_status:
					chance = rng.randf_range(0, 1)
					if chance <= skill_used.chance_of_status_condition:
						par_tasks.append(func(): await enemy.handle_status(skill_used.status_type))
						#enemy.handle_status(skill_used.status_type)
				if skill_used.removes_status:
					chance = rng.randf_range(0, 1)
					if chance <= skill_used.chance_of_status_condition:
						par_tasks.append(func(): await enemy.remove_status(skill_used.removes_status))
						#enemy.remove_status(skill_used.removes_status)
			action_sequence.append(func(): await await_parallel(par_tasks))
	else:
		if skill_used.targets_party:
			var targetted_player: combat_template = player_container.get_child(what_action[1])
			if skill_used.does_heal_party:
				if get_skill_boost(skill_used) != 999:
					parallel_tasks.append(func(): await targetted_player.update_health([-1 * (current_player.obtain_stat(targetted_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL"], false, get_player_portrait(what_action[1])))
					#await targetted_player.update_health([-1 * (current_player.obtain_stat(targetted_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL"], false, get_player_portrait(what_action[1]))
				else:
					parallel_tasks.append(func(): await targetted_player.update_health([-1 * targetted_player.stored_combatant.combatant_stats.max_health, "HEAL"], false, get_player_portrait(what_action[1])))
					#await targetted_player.update_health([-1 * targetted_player.stored_combatant.combatant_stats.max_health, "HEAL"], false, get_player_portrait(what_action[1]))
			if skill_used.does_status:
				action_sequence.append(func(): await targetted_player.handle_status(skill_used.status_type))
				#await targetted_player.handle_status(skill_used.status_type)
			if skill_used.removes_status:
				action_sequence.append(func(): await targetted_player.remove_status(skill_used.removes_status))
				#await targetted_player.remove_status(skill_used.removes_status)
		else:
			var targetted_enemy = enemy_shit.get_child(what_action[1])
			var check_evasion = current_player.calculate_evasion(targetted_enemy, skill_used.accuracy)
			var chance = rng.randf_range(0, 1)
			if skill_used.does_status and chance <= skill_used.chance_of_status_condition:
				action_sequence.append(func(): await targetted_enemy.handle_status(skill_used.status_type))
				#await targetted_enemy.handle_status(skill_used.status_type)
			if skill_used.removes_status and chance <= skill_used.chance_of_status_condition:
				action_sequence.append(func(): await targetted_enemy.remove_status(skill_used.removes_status))
				#await targetted_enemy.remove_status(skill_used.removes_status)
			if skill_used.multi_hit:
				parallel_tasks.append(func(): await deal_damage(current_player, targetted_enemy, true, skill_used))
				#await deal_damage(current_player, targetted_enemy, true, skill_used)
			else:
				chance = rng.randf_range(0, 1)
				if chance <= check_evasion:
					parallel_tasks.append(func(): await deal_damage(current_player, targetted_enemy, true, skill_used))
					#await deal_damage(current_player, targetted_enemy, true, skill_used)
				else:
					parallel_tasks.append(func(): await targetted_enemy.update_health("MISS"))
					#targetted_enemy.update_health("MISS")
	parallel_tasks.append(func(): await update_mana_display(-1 * skill_used.mana_cost))
	action_sequence.insert(0, func(): await await_parallel(parallel_tasks))
	#update_mana_display(-1 * skill_used.mana_cost)
	await action_queue(action_sequence)

func execute_item(what_item: Items, targets_who, item_index):
	if what_item.targets_players:
		if what_item.is_aoe_item:
			for player_num in range(player_container.get_child_count()):
				var player = get_player(player_num)
				if what_item.does_what == 2:
					player.update_health([-1 * what_item.amount_to_heal_or_deal, "HEAL"], false, get_player_portrait(player_num))
				if what_item.removes_status != null:
					get_player(targets_who).remove_status(what_item.removes_status)
				if what_item.give_status != null:
					get_player(targets_who).handle_status(what_item.give_status)
		else:
			if what_item.does_what == 2:
				get_player(targets_who).update_health([-1 * what_item.amount_to_heal_or_deal, "HEAL"], false, get_player_portrait(targets_who))
			if what_item.removes_status != null:
				get_player(targets_who).remove_status(what_item.removes_status)
			if what_item.give_status != null:
				get_player(targets_who).handle_status(what_item.give_status)
	else:
		if what_item.is_aoe_item:
			for enemy in enemy_shit.get_children():
				if what_item.does_what == 1:
					await enemy.update_health([what_item.amount_to_heal_or_deal, 0])
				if what_item.removes_status != null:
					enemy.remove_status(what_item.removes_status)
				if what_item.give_status != null:
					enemy.handle_status(what_item.give_status)
		else:
			var enemy = enemy_shit.get_child(targets_who)
			if what_item.does_what == 1:
				await enemy.update_health([what_item.amount_to_heal_or_deal, 0])
			if what_item.removes_status != null:
				enemy.remove_status(what_item.removes_status)
			if what_item.give_status != null:
				enemy.handle_status(what_item.give_status)
	temp_item_list.remove_at(item_index)
	update_mana_display(-1)

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

func determine_order():
	all_combatants.clear()
	
	for slot in $Player_Container.get_children():
		all_combatants.append(slot)
	for enemy_slot in enemy_shit.get_children():
		if enemy_slot.visible:
			all_combatants.append(enemy_slot)
	
	all_combatants.sort_custom(func(a, b):
		return a.obtain_stat(5) > b.obtain_stat(5)
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
		all_combatants.append(enemy_shit.get_child(i))

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

# Buttons
func attack_button_pressed():
	if not highlight_enemies():
		unhighlight_all_entities()
		return
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
			highlight_players()
		else:
			get_player(what_player).could_be_selected()
	else:
		highlight_enemies()
		
	var action_on_who = await confirmation
	if action_on_who is bool:
		return
	if not skill_to_use.is_skill_aoe:
		if skill_to_use.targets_party:
			setup_confirmation_button(skill_to_use.move_name, get_player(what_player).stored_combatant.combatant_name)
		else:
			setup_confirmation_button(skill_to_use.move_name, enemy_shit.get_child(action_on_who).stored_combatant.combatant_name)
	else:
		if skill_to_use.targets_party:
			setup_confirmation_button(skill_to_use.move_name, "entire party")
		else:
			setup_confirmation_button(skill_to_use.move_name, "every enemy")

	var confirmed = await actual_confirmation
	if confirmed:
		action_taken.emit("SKILL", action_on_who, what_skill)
	revert_to_default_UI()

func item_selected(item_index):
	current_run_id += 1
	var cur_id = current_run_id
	
	item_menu.visible = false
	selected_item.visible = true
	var used_item: bool = false
	var chosen_item: Items = temp_item_list[item_index]
	var action_on_who
	var is_aoe
	selected_item.setup(chosen_item, item_index, self)
	if chosen_item.targets_players:
		highlight_players()
	else:
		highlight_enemies()
	while not used_item:
		if chosen_item.is_aoe_item:
			setup_confirmation_button(chosen_item.item_name, "entire party" if chosen_item.targets_players else "every enemy")
			var confirmation = await actual_confirmation
			if confirmation:
				is_aoe = true
				revert_to_default_UI()
				break
			else:
				$UI/Confirmation.visible = false
				item_menu.visible = true
				selected_item.visible = false
				unhighlight_all_entities()
				return
		else:
			action_on_who = await confirmation
			if current_run_id != cur_id:
				return
			setup_confirmation_button(chosen_item.item_name, enemy_shit.get_child(action_on_who).stored_combatant.combatant_name if not chosen_item.targets_players else get_player(action_on_who).stored_combatant.combatant_name)
			var confirmed = await actual_confirmation
			if current_run_id != cur_id:
				return
			if confirmed:
				revert_to_default_UI()
				break
			else:
				$UI/Confirmation.visible = false
				selected_item.visible = true
				continue

	action_taken.emit("ITEM", action_on_who if not is_aoe else 4, item_index)

func action_queue(sequence: Array[Callable]):
	for action: Callable in sequence:
		await action.call()


func await_parallel(tasks: Array[Callable]):
	var state = { "active_tasks": tasks.size() }
	if state["active_tasks"] == 0:
		return
		
	for task in tasks:
		var run_task = func():
			await task.call()
			state["active_tasks"] -= 1
		run_task.call() 
	
	while state["active_tasks"] > 0:
		await get_tree().process_frame

func confirmation_button(event, confirm_or_deny):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			await get_tree().create_timer(0.02).timeout
			actual_confirmation.emit(confirm_or_deny)

func setup_confirmation_button(move_name, entity_used_on_name):
	$UI/Confirmation.visible = true
	var question_label = $UI/Confirmation/Label
	question_label.text = "Use " + move_name + " on " + entity_used_on_name + "?"

func revert_to_default_UI():
	unhighlight_all_entities()
	$UI/Confirmation.visible = false
	$UI/ItemNode.visible = false

func unhighlight_all_entities():
	for enemy in enemy_shit.get_children():
		enemy.undo_selection()
	for player in player_container.get_children():
		player.undo_selection()

func highlight_players():
	for player in player_container.get_children():
		if player.currently_selectable:
			return false
		player.could_be_selected()
	return true
		
func highlight_enemies():
	for enemy in enemy_shit.get_children():
		if enemy.currently_selectable:
			return false
		enemy.could_be_selected()
	return true

func hide_everything():
	revert_to_default_UI()

func update_mana_display(mana_used_or_gained):
	mana = clamp(mana + mana_used_or_gained, 0, 3)
	$"UI/Mana Bar/Label".text = str(mana) + "/" + str(max_mana) 

@onready var camera: Camera3D = $Camera3D

@export var original_fov: float = 15.0 
@export var min_fov: float = 8.0      
@export var padding: float = 0.5       
@export var border_size: float = 0.1   

func sci_fi_enhance_zoom(target_a: Node3D, target_b: Node3D, duration: float):
	var local_a = camera.to_local(target_a.global_position)
	var local_b = camera.to_local(target_b.global_position)
	
	var depth_a = abs(local_a.z)
	var depth_b = abs(local_b.z)
	var avg_depth = (depth_a + depth_b) / 2.0
	
	var viewport_size = get_viewport().get_visible_rect().size
	var aspect = viewport_size.x / viewport_size.y
	
	var orig_v_fov_rad = deg_to_rad(original_fov)
	var orig_height = 2.0 * avg_depth * tan(orig_v_fov_rad / 2.0)
	var orig_width = orig_height * aspect
	
	var actual_border = min(border_size, min(orig_height, orig_width) * 0.4)
	
	var shrunk_height = orig_height - (2.0 * actual_border)
	var shrunk_width = orig_width - (2.0 * actual_border)
	
	var limit_v_rad = 2.0 * atan(shrunk_height / (2.0 * avg_depth))
	var limit_h_rad = 2.0 * atan((shrunk_width / aspect) / (2.0 * avg_depth))
	var max_allowed_fov = rad_to_deg(min(limit_v_rad, limit_h_rad))
	
	var target_h_offset = (local_a.x + local_b.x) / 2.0
	var target_v_offset = (local_a.y + local_b.y) / 2.0
	
	var shifted_a_x = local_a.x - target_h_offset
	var shifted_a_y = local_a.y - target_v_offset
	var shifted_b_x = local_b.x - target_h_offset
	var shifted_b_y = local_b.y - target_v_offset
	
	var fov_x_a = 2.0 * atan((abs(shifted_a_x) + padding/2.0) / aspect / depth_a)
	var fov_y_a = 2.0 * atan((abs(shifted_a_y) + padding/2.0) / depth_a)
	var fov_x_b = 2.0 * atan((abs(shifted_b_x) + padding/2.0) / aspect / depth_b)
	var fov_y_b = 2.0 * atan((abs(shifted_b_y) + padding/2.0) / depth_b)
	
	var temp_fov = clamp(rad_to_deg(max(fov_x_a, fov_y_a, fov_x_b, fov_y_b)), min_fov, max_allowed_fov)
	
	var temp_v_fov_rad = deg_to_rad(temp_fov)
	var temp_height = 2.0 * avg_depth * tan(temp_v_fov_rad / 2.0)
	var temp_width = temp_height * aspect
	
	var max_h_offset = max(0.0, (shrunk_width - temp_width) / 2.0)
	var max_v_offset = max(0.0, (shrunk_height - temp_height) / 2.0)
	
	var final_h_offset = clamp(target_h_offset, -max_h_offset, max_h_offset)
	var final_v_offset = clamp(target_v_offset, -max_v_offset, max_v_offset)
	
	var final_shifted_a_x = local_a.x - final_h_offset
	var final_shifted_a_y = local_a.y - final_v_offset
	var final_shifted_b_x = local_b.x - final_h_offset
	var final_shifted_b_y = local_b.y - final_v_offset
	
	var final_fov_x_a = 2.0 * atan((abs(final_shifted_a_x) + padding/2.0) / aspect / depth_a)
	var final_fov_y_a = 2.0 * atan((abs(final_shifted_a_y) + padding/2.0) / depth_a)
	var final_fov_x_b = 2.0 * atan((abs(final_shifted_b_x) + padding/2.0) / aspect / depth_b)
	var final_fov_y_b = 2.0 * atan((abs(final_shifted_b_y) + padding/2.0) / depth_b)
	
	var required_fov = clamp(rad_to_deg(max(final_fov_x_a, final_fov_y_a, final_fov_x_b, final_fov_y_b)), min_fov, max_allowed_fov)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(camera, "h_offset", final_h_offset, duration)
	tween.tween_property(camera, "v_offset", final_v_offset, duration)
	tween.tween_property(camera, "fov", required_fov, duration)
	await get_tree().create_timer(duration).timeout


func revert_camera(duration: float):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(camera, "h_offset", 0.0, duration)
	tween.tween_property(camera, "v_offset", 0.0, duration)
	tween.tween_property(camera, "fov", original_fov, duration)
