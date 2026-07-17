extends Node

class_name dungeon_loop

#region Variables
const PARTY_ATTACK_OVERLAY_SCENE := preload("res://scenes/cutscenes/PartyAttackOverlay.tscn")

@export var party_slot_1 : generic_combatants
@export var party_slot_2: generic_combatants
@export var party_slot_3: generic_combatants

@export var temp_item_list : Array[Items]

@onready var gui: dungeon_gui = $CanvasLayer/UI/DungeonPlayerGui

@onready var slot_1: combat_template = $Player_Container/Player_Slot1
@onready var slot_2: combat_template = $Player_Container/Player_Slot2
@onready var slot_3: combat_template = $Player_Container/Player_Slot3

@onready var player_container: Node = $Player_Container

@onready var enemy_shit: Node = $Enemy_Container

@onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var floor_tiles: Node = $Background/Floor_Tiles

var all_combatants : Array[combat_template] = []
var killed_enemies: Array[generic_combatants] = []

var selecting_entity: bool = false
var current_dungeon_run : dungeon_type

var current_selected_person: int

var current_bond_points: int = 0
var max_bond_points_: int = 0

var current_run_id: int = 0
var active_player_turn: int = 0

var waiting_for_confirmation : bool = false

const MAX_AMOUNT_OF_ENEMIES = 5

signal confirmation
signal action_taken
signal turn_ended
signal actual_confirmation

var healing_weight: float = 14.9862954393029
var kill_weight: float = 45.2582422494888
var damage_importance_weight: float = 45.0503428578377
var healing_importance_weight: float = 0.6637550592422
var remove_status_weight: float = 37.6523693203926
var give_self_status_weight: float = 33.7605845928192
var remove_players_status_weight: float = 25.3082177639008
var give_player_status_weight: float = 0
var skill_importance: float = 50.0
var summon_importance: float = 50.0


#[14.9862954393029, 50, 11.0503428578377, 20.6637550592422, 37.6523693203926, 33.7605845928192, 50, 33.1900285482407, 16.6770209241658]
var p_healing_weight: float = 10
var p_kill_weight: float = 50
var p_damage_importance_weight: float = 10
var p_healing_importance_weight: float = 10
var p_remove_status_weight: float = 15
var p_give_self_status_weight: float = 15
var p_remove_players_status_weight: float = 20
var p_give_player_status_weight: float = 20
var p_skill_importance: float = 0

#endregion

var skills_enemies_have_used: int = 0

@export var test_encounter: dungeon_wave

#region Initialization
var training: bool = false
var testing: bool = false
func _ready():
	#setup(GlobalCombatInformation.dungeon_types[0], test_encounter, false)
	return
	Fade.fade_thing.visible = false
	Fade.fade_thing_2.visible = false
	gui.hide_gui(false)
	if testing:
		gui._setup(self)
		gui.display_enemies.connect(highlight_check)
		gui.confirmation_given.connect(action_was_taken)
		
		if training:
			#await EnemyGeneticAlgorithm._setup(self)
			get_tree().quit()

		else:
			await _reset()
			#await battle_loop(encounter)

			#return (killed_enemies)
		
func _reset() -> void:
	all_combatants.clear()
	
	for combatant in all_combatants:
		if is_instance_valid(combatant) and combatant != slot_1 and combatant != slot_2 and combatant != slot_3:
			combatant.queue_free()
	await get_tree().process_frame
	
	await gui._setup(self)
	gui.display_enemies.connect(highlight_check)
	gui.confirmation_given.connect(action_was_taken)
	
	gui.get_player_portrait(0)._setup(GlobalCombatInformation.active_party_slots[0])
	slot_1.setup(GlobalCombatInformation.active_party_slots[0], self, 0)
	all_combatants.append(slot_1)

	if GlobalCombatInformation.active_party_slots.size() > 1:
		gui.get_player_portrait(1)._setup(GlobalCombatInformation.active_party_slots[1])
		slot_2.setup(GlobalCombatInformation.active_party_slots[1], self, 1)
		all_combatants.append(slot_2)

		if GlobalCombatInformation.active_party_slots.size() > 2:
			gui.get_player_portrait(2)._setup(GlobalCombatInformation.active_party_slots[2])
			slot_3.setup(GlobalCombatInformation.active_party_slots[2], self, 2)
			all_combatants.append(slot_3)
	
	#item_menu.setup(temp_item_list, self)
	if not training:
		await GlobalCombatInformation.load_items()
		temp_item_list = GlobalCombatInformation.all_held_items

func action_was_taken(which_thing):
	if which_thing is Items:
		action_taken.emit("ITEM", which_thing)
	elif which_thing is moves:
		action_taken.emit("SKILL", which_thing)

func hide():
	self.visible = false
	gui.visible = false
	gui.get_child(0).visible = false

func setup(current_dungeon_type: dungeon_type, encounter: dungeon_wave, is_boss: bool):
	for person in GlobalCombatInformation.active_party_slots:
		person.gather_actual_stats()

	gui.call_deferred("hide_gui", false)
	Fade.fade_out(0.0)
	self.current_dungeon_run = current_dungeon_type
	temp_item_list = GlobalCombatInformation.all_held_items
	current_bond_points = GlobalCombatInformation.current_BP
	max_bond_points_ = GlobalCombatInformation.max_BP

	for child in floor_tiles.get_children():
		if child.get_index() == current_dungeon_type.type_of_dungeon:
			child.visible = true
		else:
			child.visible = false
			
	gui._setup(self)
	
	gui.get_player_portrait(0)._setup(GlobalCombatInformation.active_party_slots[0])
	slot_1.setup(GlobalCombatInformation.active_party_slots[0], self, 0)
	all_combatants.append(slot_1)

	if GlobalCombatInformation.active_party_slots.size() > 1:
		gui.get_player_portrait(1)._setup(GlobalCombatInformation.active_party_slots[1])
		slot_2.setup(GlobalCombatInformation.active_party_slots[1], self, 1)
		all_combatants.append(slot_2)

		if GlobalCombatInformation.active_party_slots.size() > 2:
			gui.get_player_portrait(2)._setup(GlobalCombatInformation.active_party_slots[2])
			slot_3.setup(GlobalCombatInformation.active_party_slots[2], self, 2)
			all_combatants.append(slot_3)
		else:
			slot_3.visible = false
			gui.get_player_portrait(2).visible = false
	else:
		slot_2.visible = false
		slot_3.visible = false
		gui.get_player_portrait(1).visible = false
		gui.get_player_portrait(2).visible = false
	
	for player in player_container.get_children():
		if player.stored_combatant == null:
			player.queue_free()
	
	AudioManager.play_bgm(AudioManager.BATTLE_MUSIC)
	return await battle_loop(encounter, is_boss)
	
	#item_menu.setup(temp_item_list, self)

#endregion

#region CombatHelpers
func _has_combatant(entity) -> bool:
	return entity != null and is_instance_valid(entity) and entity.stored_combatant != null

func _is_living_combatant(entity) -> bool:
	return _has_combatant(entity) and not entity.stored_combatant.is_dead

func determine_order() -> void:
	all_combatants.clear()
	
	for slot in $Player_Container.get_children():
		if slot.visible and _is_living_combatant(slot):
			all_combatants.append(slot)
	for enemy_slot in enemy_shit.get_children():
		if enemy_slot.visible and _is_living_combatant(enemy_slot):
			all_combatants.append(enemy_slot)
	
	all_combatants.sort_custom(func(a, b) -> int:
		return a.obtain_stat(5) > b.obtain_stat(5)
	)

func get_next_actor():
	if all_combatants.is_empty():
		return null
		
	return all_combatants[0]

func advance_turn(actor):
	var completed_actor = all_combatants.pop_front()
	
	if _is_living_combatant(completed_actor):
		all_combatants.append(completed_actor)
		
	var living_combatants: Array[combat_template] = []
	for entity in all_combatants:
		if _is_living_combatant(entity):
			living_combatants.append(entity)
	all_combatants = living_combatants
	
	gui.update_turn_queue_ui()

func calculate_turn_order() -> Array:
	var projected_queue: Array = []
	
	var simulations = []
	for entity in all_combatants:
		if _is_living_combatant(entity):
			var speed = entity.obtain_stat(entity.stats.SPEED)
			simulations.append({
				"entity": entity,
				"current_time": entity.time_until_turn, 
				"speed": speed
			})
			
	for i in range(8):
		simulations.sort_custom(func(a, b): return a["current_time"] < b["current_time"])

		var next_actor = simulations[0]
		projected_queue.append(next_actor["entity"])

		next_actor["current_time"] += (10000.0 / next_actor["speed"])

	return projected_queue

func sort_player_actions(player_actions: Array[player_weighting]) -> Array[player_weighting]:
	player_actions.sort_custom(func(a, b):
		return a.action_weight > b.action_weight
	)
	return player_actions

func sort_enemy_actions(enemy_actions: Array[enemy_weighting]) -> Array[enemy_weighting]:
	enemy_actions.sort_custom(func(a, b):
		return a.action_weight > b.action_weight
	)
	return enemy_actions

var enemy_scene = "res://assets/Resources/Combat_Template_3D.tscn"
func setup_encounter(new_encounter: dungeon_wave, is_boss):
	var enemy_list = new_encounter.enemies.duplicate()
	enemy_list.shuffle()
	var enemy_count_for_current_wave: int = enemy_list.size()
	for i in range(0, enemy_count_for_current_wave):
		var new_enemy = load(enemy_scene)
		var new_enemy_instance = new_enemy.instantiate()
		enemy_shit.add_child(new_enemy_instance)
		#new_enemy_instance.position = Vector3(-0.5 + (i * 0.25), -0.131, 0.0)
		if not is_boss:
			if i < 3:
				new_enemy_instance.position = Vector3((i * 0.1), (i * -0.15), (i * 0.4))
			elif i >= 3:
				new_enemy_instance.position = Vector3(0.8 - ((i - 3) * 0.2), 0.0, 0.35 + ((i - 3) * 0.55))
		else:
			AudioManager.play_bgm(AudioManager.BOSS_BATTLE_MUSIC)
			new_enemy_instance.position = Vector3(-0.7, 0.0, 0.75)
		new_enemy_instance.setup(enemy_list[i].duplicate(true), self, i)
		all_combatants.append(new_enemy_instance)
	turn_ended.emit()
#endregion

var turn_count: int = 0

func battle_loop(encounter, is_boss, training_weight = null, p_weights = null):
	skills_enemies_have_used = 0
	training = false
	
	# For use when training genetic_algorithm
	if training_weight != null:
		healing_weight = training_weight[0]
		kill_weight = training_weight[1]
		damage_importance_weight = training_weight[2]
		healing_importance_weight = training_weight[3]
		remove_status_weight = training_weight[4]
		give_self_status_weight = training_weight[5]
		remove_players_status_weight = training_weight[6]
		give_player_status_weight = training_weight[7]
		skill_importance = training_weight[8]
		
		p_healing_weight = p_weights[0]
		p_kill_weight = p_weights[1]
		p_damage_importance_weight = p_weights[2]
		p_healing_importance_weight = p_weights[3]
		p_remove_status_weight = p_weights[4]
		p_give_self_status_weight = p_weights[5]
		p_remove_players_status_weight = p_weights[6]
		p_give_player_status_weight = p_weights[7]
		p_skill_importance = p_weights[8]
		
		training = true
	
	var is_wave_over : bool = false
	var number_of_waves_to_fight = 1#rng.randi_range(current_dungeon_run.minimum_number_of_floors, current_dungeon_run.max_number_of_floors)
	
	# Genetic algorithm return values
	var number_of_killed_players = 0
	var cum_player_health = 0
	var number_of_killed_enemies = 0
	var highest_wave_reached = 0
	var did_players_win: bool = false
	gui.update_mana_display(current_bond_points, true)
	for i in range(number_of_waves_to_fight):
		highest_wave_reached += 1
		turn_count = 0
		is_wave_over = false
		setup_encounter(encounter, is_boss)
		determine_order()
		gui.update_turn_queue_ui()
		while(not is_wave_over):
			turn_count += 1
			
			var current_actor = get_next_actor()
			if not _has_combatant(current_actor):
				is_wave_over = true
				break
			
			# If player is dead, you lost
			if current_actor.stored_combatant.is_MC and current_actor.stored_combatant.is_dead:
				is_wave_over = true
				did_players_win = false
				break

			# After each turn checks if all players or all enemies are dead
			var number_of_alive_enemies = 0
			var number_of_alive_players = 0
			
			if not _is_living_combatant(slot_1):
				is_wave_over = true
				did_players_win = false
				break
			
			# Enemy Check
			for enemy in enemy_shit.get_children():
				if enemy.stored_combatant == null:
					continue
				if not enemy.stored_combatant.is_dead:
					number_of_alive_enemies += 1
			# Player check
			for player in player_container.get_children():
				if player.visible and _is_living_combatant(player):
					number_of_alive_players += 1
			# Wait so all animations can finish
			if not training:
				await get_tree().create_timer(0.5).timeout
			await get_tree().process_frame
			if number_of_alive_enemies == 0:
				is_wave_over = true
				did_players_win = true
				break
			elif number_of_alive_players == 0:
				is_wave_over = true
				did_players_win = false
				break
				
			# Enemy Turn
			if current_actor.stored_combatant.is_combatant_enemy:
				active_player_turn = current_actor.child_number
				await execute_enemy_turn(current_actor.stored_combatant, turn_count, training)
			# Player Turn
			else:	
				active_player_turn = current_actor.child_number
				if training:
					await execute_player_auto_turn(current_actor.stored_combatant, turn_count, training)
				else:
					#var thing = await handle_player_move_selection(current_combatant.stored_combatant)
					selecting_entity = false
					if get_player(active_player_turn).stored_combatant == null or get_player(active_player_turn).stored_combatant.is_dead:
						continue
					await get_player(active_player_turn).take_turn(gui.get_player_portrait(active_player_turn))
					gui.get_player_portrait(active_player_turn).update_statuses(get_player(active_player_turn))
					current_actor.animated_sprite.play("Idle")
					await gui.new_player_turn()
					make_enemies_selectable()
					select_individual(false, 0)
					await turn_ended

					#if thing == "RUN":
					#	return killed_enemies
				hidden_default()
			advance_turn(current_actor)
		if i != number_of_waves_to_fight - 1:
			gui.next_floor(i)
			await get_tree().create_timer(2).timeout
			
	if not did_players_win:
		await gui.play_game_over()
			
	var ret_val: Array = _collect_active_party_results()
	ret_val.append(current_bond_points)
	ret_val.append(gui.bond_bar.value)
	print(current_bond_points)
	return [killed_enemies, did_players_win, ret_val]
	#return [number_of_killed_players, number_of_killed_enemies, player_container, highest_wave_reached, number_of_waves_to_fight, cum_player_health, skills_enemies_have_used]

func _collect_active_party_results() -> Array:
	var results: Array = []
	var slots: Array = [slot_1, slot_2, slot_3]
	for slot in slots:
		if slot == null or not slot.visible or slot.stored_combatant == null:
			results.append(null)
			continue
		results.append(slot.stored_combatant.duplicate())
	return results

#region EntityTurns

func execute_enemy_turn(enemy_to_attack, _turn_number, testing):
	if enemy_to_attack.is_dead:
		return
	
	rng = RandomNumberGenerator.new()
	var possible_enemy_actions: Array[enemy_weighting]

	var attacking_enemy: combat_template
	for enemy in enemy_shit.get_children():
		if enemy_to_attack == enemy.stored_combatant:
			attacking_enemy = enemy
			
	for player in player_container.get_children():
		if not _is_living_combatant(player):
			continue
		else:
			var new_action = enemy_weighting.new(enemy_shit, player_container, attacking_enemy, player)
			possible_enemy_actions.append(new_action)
			
	for action: moves in attacking_enemy.stored_combatant.combatant_skills_.keys():
		if action.does_summon:
			var new_action = enemy_weighting.new(enemy_shit, player_container, attacking_enemy, null, false, action)
			possible_enemy_actions.append(new_action)
			continue
		else:
			for player in player_container.get_children():
				if not _is_living_combatant(player):
					continue

				var new_action = enemy_weighting.new(enemy_shit, player_container, attacking_enemy, player, true, action)
				possible_enemy_actions.append(new_action)
				continue
			if action.targets_party:
				for enemy in enemy_shit.get_children():
					if not enemy.visible:
						continue
					var new_action = enemy_weighting.new(enemy_shit, player_container, attacking_enemy, enemy, false, action)
					possible_enemy_actions.append(new_action)

	var finalized_enemy_actions: Array[enemy_weighting] = []
	for action: enemy_weighting in possible_enemy_actions:
		if action == null:
			continue
		if action.action_weight != 0:
			finalized_enemy_actions.append(action)
			
	for action: enemy_weighting in finalized_enemy_actions:
		action.set_action_weight(gather_true_action_weights(action))
		
	finalized_enemy_actions.shuffle()
	var selected_action: enemy_weighting
	if finalized_enemy_actions.size() > 0:
		var weights: Array[float] = []
		for action in finalized_enemy_actions:
			var scale = 0.75
			var exaggerated_weight = exp(max(0.0, action.action_weight) * scale)
			weights.append(exaggerated_weight)
		
		var selected_index = rng.rand_weighted(weights)
		selected_action = finalized_enemy_actions[selected_index]
	await attacking_enemy.take_turn()
		
	var action_sequence: Array[Callable]
	var par_task : Array[Callable]
	if selected_action.is_base_attack:
		if testing:
			action_sequence.append(func(): await deal_damage(attacking_enemy, selected_action.targetting_who, false, null))
		if not testing:
			action_sequence.append(func(): await attacking_enemy.attack_animation(0))
			action_sequence.append(func(): deal_damage(attacking_enemy, selected_action.targetting_who, false, null))
		
		await action_queue(action_sequence)
	else:
		if not testing:
			var random_attack = rng.randi_range(0, 1)
			match random_attack:
				0:
					action_sequence.append(func(): await attacking_enemy.attack_animation(0))
				1:
					action_sequence.append(func(): await attacking_enemy.attack_animation(1))
			action_sequence.append(func(): await execute_enemy_skills(selected_action))

		else:
			action_sequence.append(func(): await execute_enemy_skills(selected_action))

		skills_enemies_have_used += 1
		await action_queue(action_sequence)
	turn_ended.emit()

func execute_enemy_skills(action):
	var skill_used: moves = action.skill_type
	var person_acting = action.person_acting
	var person_recieving = action.targetting_who
	var action_sequence : Array[Callable] = []
	var parallel_tasks : Array[Callable] = []

	if not skill_used.does_summon:
		if skill_used.is_skill_aoe:
			var targets = enemy_shit.get_children() if skill_used.targets_party else player_container.get_children()
			
			for entity in targets:
				if not is_instance_valid(entity):
					continue
				if not _has_combatant(entity):
					continue

				if entity.stored_combatant.is_combatant_enemy:
					if not entity.visible or entity.stored_combatant.is_dead:
						continue
				else:
					if entity.stored_combatant.is_dead:
						continue

				var seq_task: Array[Callable] = []
				var par_task : Array[Callable] = []
		
				var wait_time: float = 0.25 * entity.get_index()
				seq_task.append(func(): await get_tree().create_timer(wait_time).timeout)

				var chance
				if skill_used.does_heal_party:
					if get_skill_boost(skill_used) != 999:
						par_task.append(func(e=entity): 
							if is_instance_valid(e): 
								await e.update_health(-1 * (person_acting.obtain_stat(person_acting.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL")
						)
					else:
						par_task.append(func(e=entity): 
							if is_instance_valid(e):
								await e.update_health(-1 * e.stored_combatant.actual_stats.max_health, "HEAL")
						)
				if skill_used.does_status:
					if skill_used.targets_party:
						par_task.append(func(e=entity): 
							if is_instance_valid(e):
								await e.handle_status(skill_used.status_type, skill_used.lasts_x_turns)
						)
					else:
						chance = rng.randf_range(0, 1)
						if chance <= skill_used.chance_of_status_condition:
							par_task.append(func(e=entity): 
								if is_instance_valid(e):
									await e.handle_status(skill_used.status_type, skill_used.lasts_x_turns)
							)
				if skill_used.does_remove_status or skill_used.removes_status:
					if skill_used.targets_party:
						par_task.append(func(e=entity): 
							if is_instance_valid(e):
								await e.remove_status(skill_used.removes_status)
						)
					else:
						chance = rng.randf_range(0, 1)
						if chance <= skill_used.chance_of_status_condition:
							par_task.append(func(e=entity): 
								if is_instance_valid(e):
									await e.remove_status(skill_used.removes_status)
							)
				if skill_used.does_damage:
					parallel_tasks.append(func(e=entity): 
						if is_instance_valid(e):
							await deal_damage(person_acting, e, true, skill_used)
					)
				
				seq_task.append(func(): await await_parallel(par_task))
				parallel_tasks.append(func(): await action_queue(seq_task))
		else:
			if person_recieving != null and is_instance_valid(person_recieving):
				# Bake the wait time immediately
				var wait_time: float = 0.25 * person_recieving.get_index()
				action_sequence.append(func(): await get_tree().create_timer(wait_time).timeout)

				var chance
				if skill_used.does_heal_party:
					if get_skill_boost(skill_used) != 999:
						parallel_tasks.append(func(): 
							if is_instance_valid(person_recieving):
								await person_recieving.update_health(-1 * (person_recieving.obtain_stat(person_recieving.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL")
						)
					else:
						parallel_tasks.append(func(): 
							if is_instance_valid(person_recieving):
								await person_recieving.update_health(-1 * person_recieving.stored_combatant.actual_stats.max_health, "HEAL")
						)
				if skill_used.does_status:
					if skill_used.targets_party:
						parallel_tasks.append(func(): 
							if is_instance_valid(person_recieving):
								await person_recieving.handle_status(skill_used.status_type, skill_used.lasts_x_turns)
						)
					else:
						chance = rng.randf_range(0, 1)
						if chance <= skill_used.chance_of_status_condition:
							parallel_tasks.append(func(): 
								if is_instance_valid(person_recieving):
									await person_recieving.handle_status(skill_used.status_type, skill_used.lasts_x_turns)
							)
				if skill_used.removes_status:
					if skill_used.targets_party:
						parallel_tasks.append(func(): 
							if is_instance_valid(person_recieving):
								await person_recieving.remove_status(skill_used.removes_status)
						)
					else:
						chance = rng.randf_range(0, 1)
						if chance <= skill_used.chance_of_status_condition:
							parallel_tasks.append(func(): 
								if is_instance_valid(person_recieving):
									await person_recieving.remove_status(skill_used.removes_status)
							)
				if skill_used.multi_hit:
					if skill_used.does_damage:
						parallel_tasks.append(func(): 
							if is_instance_valid(person_recieving):
								await deal_damage(person_acting, person_recieving, true, skill_used)
						)
				else:
					if skill_used.does_damage:
						var check_evasion = calculate_evasion(person_recieving, skill_used.accuracy)
						chance = rng.randf_range(0, 1)
						if chance <= check_evasion:
							parallel_tasks.append(func(): 
								if is_instance_valid(person_recieving):
									await deal_damage(person_acting, person_recieving, true, skill_used)
							)
						else:
							parallel_tasks.append(func(): 
								if is_instance_valid(person_recieving):
									await person_recieving.update_health(0, "MISS")
							)
	
			person_acting.current_mana = clamp(person_acting.current_mana - skill_used.mana_cost, 0, 3)

			action_sequence.insert(0, func(): await await_parallel(parallel_tasks))
			await action_queue(action_sequence)
	else:
		var get_position_for_slot = func(idx: int) -> Vector3:
			if idx < 3:
				return Vector3(idx * 0.1, idx * -0.15, idx * 0.4)
			else:
				return Vector3(0.8 - ((idx - 3) * 0.2), 0.0, 0.35 + ((idx - 3) * 0.55))

		var is_slot_occupied = func(idx: int) -> bool:
			var target_pos = get_position_for_slot.call(idx)
			for enemy in enemy_shit.get_children():
				# Ensure the node is valid and not currently being deleted/freed
				if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
					# Ensure the enemy is visible and alive
					if enemy.visible and not (enemy.stored_combatant and enemy.stored_combatant.is_dead):
						# If an active enemy is sitting at this position, the slot is occupied
						if enemy.position.distance_to(target_pos) < 0.01:
							return true
			return false

		var random_amount_to_summon = randi_range(skill_used.summon_count_range.x, skill_used.summon_count_range.y)
		for i in range(0, random_amount_to_summon):
			var enemy_index: int = -1
			for slot_idx in range(MAX_AMOUNT_OF_ENEMIES):
				if not is_slot_occupied.call(slot_idx):
					enemy_index = slot_idx
					break
			
			if enemy_index == -1:
				break

			var new_enemy = load(enemy_scene)
			var new_enemy_instance = new_enemy.instantiate()
			enemy_shit.add_child(new_enemy_instance)
			
			new_enemy_instance.position = get_position_for_slot.call(enemy_index)
			
			new_enemy_instance.setup(skill_used.summons_who.duplicate(), self, enemy_index)
			all_combatants.append(new_enemy_instance)
		
		
		pass
	return

#region PARTY

func get_player(player_to_get: int):
	if player_to_get >= player_container.get_child_count():
		return -1
	return $Player_Container.get_child(player_to_get)

func basic_attack():
	gui.action_hint_area.visible = false
	var action_sequence: Array[Callable]
	var current_player = get_player(active_player_turn)
	
	var target_node = return_whos_highlighted(false)
	unselect_all()
	action_sequence.append(func(): await current_player.attack_animation(0))
	action_sequence.append(func(): await deal_damage(current_player, target_node, false, null))
		
	await action_queue(action_sequence)
	selecting_entity = false

	turn_ended.emit()
		
func player_defended():
	gui.action_hint_area.visible = false
	var current_player = get_player(active_player_turn)
	var action_sequence: Array[Callable]

	action_sequence.append(func(): await current_player.execute_defend())
	unselect_all()
	selecting_entity = false
	await action_queue(action_sequence)
	turn_ended.emit()

func skill_used(skill_used: moves, skill_index):
	gui.action_hint_area.visible = false
	var action_sequence: Array[Callable]
	var current_player = get_player(active_player_turn)
	
	var action_on_who = return_whos_highlighted(skill_used.targets_party)
	GlobalCombatInformation.do_something_with_BP(-1 * skill_used.mana_cost)
	unselect_all()
	gui.update_mana_display(-1 * skill_used.mana_cost, false)

	selecting_entity = false
	action_sequence.append(func(): await current_player.attack_animation(skill_index + 1))
	action_sequence.append(func(): await gui.update_bond_attack(skill_used.mana_cost))
	action_sequence.append(func(): await execute_skills_fixed(skill_used, action_on_who))
	await action_queue(action_sequence)
	turn_ended.emit()
	
	
func item_used(item_used: Items, item_index):
	gui.action_hint_area.visible = false
	var action_sequence : Array[Callable]
	
	var action_on_who = return_whos_highlighted(item_used.does_what == 2)
	GlobalCombatInformation.remove_thing(item_used, 1)
	unselect_all()
	var current_player = get_player(active_player_turn)
	action_sequence.append(func(): await current_player.use_item(item_used))
	action_sequence.append(func(): await AudioManager.play_ui_sound(AudioManager.USE_ITEM))
	action_sequence.append(func(): await execute_items_fixed(item_used, action_on_who))
	selecting_entity = false
	await action_queue(action_sequence)
	turn_ended.emit()
	gui.action_hint_area.visible = false
	
func execute_items_fixed(item_used, acted_on_who):
	var seq_task: Array[Callable] = []
	var par_task : Array[Callable] = []
	var current_player = get_player(active_player_turn)
	
	if acted_on_who is Array:
		for entity in acted_on_who:
			if item_used.does_what == 2:
				par_task.append(func(): await entity.update_health(-1 * item_used.amount_to_heal_or_deal, "HEAL"))
			if item_used.does_what == 1:
				par_task.append(func(): await entity.update_health(item_used.amount_to_heal_or_deal, "DAMAGE"))
			if item_used.removes_status != null:
				par_task.append(func(): await entity.remove_status(item_used.removes_status))
			if item_used.give_status != null:
				par_task.append(func(): await entity.handle_status(item_used.give_status, 3))
			seq_task.insert(0, func(): await await_parallel(par_task))
	else:
		if item_used.does_what == 2:
			par_task.append(func(): await acted_on_who.update_health(-1 * item_used.amount_to_heal_or_deal, "HEAL"))
		if item_used.does_what == 1:
			par_task.append(func(): await acted_on_who.update_health(item_used.amount_to_heal_or_deal, "DAMAGE"))
		if item_used.removes_status != null:
			par_task.append(func(): await acted_on_who.remove_status(item_used.removes_status))
		if item_used.give_status != null:
			par_task.append(func(): await acted_on_who.handle_status(item_used.give_status, 3))
	
		seq_task.insert(0, func(): await await_parallel(par_task))
	await action_queue(seq_task)
	current_player.animated_sprite.play("Idle")
	current_player.animated_sprite.speed_scale = current_player.stored_combatant.idle_speed
	turn_ended.emit()

func player_did_bond_attack():
	gui.base_menu.visible = false
	gui.hide_gui(false)
	gui.set_bond_attack(0)
	
	var action_sequence: Array[Callable] = []
	print("BOND ATTACXK")
	var alive_player_count = 0
	for player in player_container.get_children():
		if not _is_living_combatant(player):
			continue
		else:
			alive_player_count += 1
	
	var attacking = return_whos_highlighted(false)
	unselect_all()
	action_sequence.append(func(): await _play_party_attack_overlay(attacking))
	if attacking is Array:
		var par_task: Array[Callable] = []
		for entity in attacking:
			var base_damage = calculate_damage(get_player(active_player_turn), 1.0, entity, false, false)
			var actual_damage = base_damage[0] + (base_damage[0] * (0.2 * alive_player_count))
			par_task.append(func(): await entity.update_health(actual_damage))
		action_sequence.append(func(): await await_parallel(par_task))
	else:
		var base_damage = calculate_damage(get_player(active_player_turn), 3.0, attacking, false, false)
		print(base_damage)
		var actual_damage = base_damage[0] + (base_damage[0] * (0.2 * alive_player_count))
		action_sequence.append(func(): await attacking.update_health(actual_damage))
	await action_queue(action_sequence)

	turn_ended.emit()

func _play_party_attack_overlay(targets) -> void:
	var overlay = PARTY_ATTACK_OVERLAY_SCENE.instantiate()
	add_child(overlay)
	await overlay.play_attack(player_container.get_children(), targets)

func ran_from_combat():
	get_viewport().set_input_as_handled()
	GlobalCombatInformation.bring_back_combat()

func execute_skills_fixed(skill_used: moves, acted_on_who):
	var current_player = get_player(active_player_turn)
	var action_sequence : Array[Callable] = []
	var parallel_tasks : Array[Callable] = []

	if acted_on_who is Array:
		for entity in acted_on_who:
			if not is_instance_valid(entity):
				continue

			var seq_task: Array[Callable] = []
			var par_task : Array[Callable] = []
	
			var wait_time: float = 0.25 * entity.get_index()
			seq_task.append(func(): await get_tree().create_timer(wait_time).timeout)

			var chance
			if skill_used.does_heal_party:
				if get_skill_boost(skill_used) != 999:
					par_task.append(func(e=entity): 
						if is_instance_valid(e): 
							await e.update_health(-1 * (current_player.obtain_stat(current_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL")
					)
				else:
					par_task.append(func(e=entity): 
						if is_instance_valid(e):
							await e.update_health(-1 * e.stored_combatant.actual_stats.max_health, "HEAL")
					)
			if skill_used.does_status:
				chance = rng.randf_range(0, 1)
				if chance <= skill_used.chance_of_status_condition:
					par_task.append(func(e=entity): 
						if is_instance_valid(e):
							await e.handle_status(skill_used.status_type, skill_used.lasts_x_turns)
					)
			if skill_used.removes_status:
				chance = rng.randf_range(0, 1)
				if chance <= skill_used.chance_of_status_condition:
					par_task.append(func(e=entity): 
						if is_instance_valid(e):
							await e.remove_status(skill_used.removes_status)
					)
			if skill_used.multi_hit:
				if skill_used.does_damage:
					parallel_tasks.append(func(e=entity): 
						if is_instance_valid(e):
							await deal_damage(current_player, e, true, skill_used)
					)
			else:
				if skill_used.does_damage:
					var check_evasion = calculate_evasion(entity, skill_used.accuracy)
					chance = rng.randf_range(0, 1)
					if chance <= check_evasion:
						parallel_tasks.append(func(e=entity): 
							if is_instance_valid(e):
								await deal_damage(current_player, e, true, skill_used)
						)
					else:
						parallel_tasks.append(func(e=entity): 
							if is_instance_valid(e):
								await e.update_health(0, "MISS")
						)
			
			seq_task.append(func(): await await_parallel(par_task))
			parallel_tasks.append(func(): await action_queue(seq_task))
	else:
		if acted_on_who != null and is_instance_valid(acted_on_who):
			var wait_time: float = 0.25 * acted_on_who.get_index()
			action_sequence.append(func(): await get_tree().create_timer(wait_time).timeout)

			var chance
			if skill_used.does_heal_party:
				if get_skill_boost(skill_used) != 999:
					parallel_tasks.append(func(): 
						if is_instance_valid(acted_on_who):
							await acted_on_who.update_health(-1 * (current_player.obtain_stat(current_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL")
					)
				else:
					parallel_tasks.append(func(): 
						if is_instance_valid(acted_on_who):
							await acted_on_who.update_health(-1 * acted_on_who.stored_combatant.actual_stats.max_health, "HEAL")
					)
			if skill_used.does_status:
				chance = rng.randf_range(0, 1)
				if chance <= skill_used.chance_of_status_condition:
					parallel_tasks.append(func(): 
						if is_instance_valid(acted_on_who):
							await acted_on_who.handle_status(skill_used.status_type, skill_used.lasts_x_turns)
					)
			if skill_used.removes_status:
				chance = rng.randf_range(0, 1)
				if chance <= skill_used.chance_of_status_condition:
					parallel_tasks.append(func(): 
						if is_instance_valid(acted_on_who):
							await acted_on_who.remove_status(skill_used.removes_status)
					)
			if skill_used.multi_hit:
				if skill_used.does_damage:
					parallel_tasks.append(func(): 
						if is_instance_valid(acted_on_who):
							await deal_damage(current_player, acted_on_who, true, skill_used)
					)
			else:
				if skill_used.does_damage:
					var check_evasion = calculate_evasion(acted_on_who, skill_used.accuracy)
					chance = rng.randf_range(0, 1)
					if chance <= check_evasion:
						parallel_tasks.append(func(): 
							if is_instance_valid(acted_on_who):
								await deal_damage(current_player, acted_on_who, true, skill_used)
						)
					else:
						parallel_tasks.append(func(): 
							if is_instance_valid(acted_on_who):
								await acted_on_who.update_health(0, "MISS")
						)
	action_sequence.insert(0, func(): await await_parallel(parallel_tasks))
	await action_queue(action_sequence)
	return

#endregion
	
#endregion

#region ENEMIES



#endregion


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

#region UI

func revert_to_default_UI():
	gui.show_base_gui()
	make_enemies_selectable()
	select_individual(false, 0)
	revert_camera()
	gui.confirmation_button.visible = false

func hidden_default():
	gui.hide_gui(false)
	revert_camera()
	gui.confirmation_button.visible = false

# Makes it so no one can be selected
func no_one_can_be_selected():
	selecting_entity = false
	for player in player_container.get_children():
		player.can_no_longer_be_selected()
	for enemy in enemy_shit.get_children():
		enemy.can_no_longer_be_selected()

# Puts the selection arrow over an individual
func select_individual(is_player, index):
	current_selected_person = index
	index -= 1
	while(true):
		index += 1
		if is_player:
			if index >= 3:
				break
			if not _is_living_combatant(get_player(index)):
				continue
			get_player(index).selected(true)
			break
		else:
			if index >= 5:
				break
			if enemy_shit.get_child(index) == null or not enemy_shit.get_child(index).visible or enemy_shit.get_child(index).stored_combatant.is_dead:
				continue
			enemy_shit.get_child(index).selected(true)
			break

func unselect_all():
	for player in player_container.get_children():
		player.unselect()
		player.can_no_longer_be_selected()
	for enemy in enemy_shit.get_children():
		enemy.unselect()
		enemy.can_no_longer_be_selected()
		
func make_players_selectable():
	selecting_entity = true
	for player in player_container.get_children():
		if not _is_living_combatant(player):
			continue
		player.could_be_selected()

func make_enemies_selectable():
	selecting_entity = true
	for enemy in enemy_shit.get_children():
		if enemy.stored_combatant == null or not enemy.visible:
			return
		enemy.could_be_selected()

func select_all_players():
	selecting_entity = false
	for player in player_container.get_children():
		if _is_living_combatant(player):
			player.selected(false)
	
func select_all_enemies():
	selecting_entity = false
	for enemy in enemy_shit.get_children():
		if not enemy.visible or not _is_living_combatant(enemy):
			continue
		enemy.selected(false)

func return_whos_highlighted(targets_party):
	var highlighted_entities = []
	if not targets_party:
		for enemy in enemy_shit.get_children():
			if enemy.selection_area_sprite.visible:
				highlighted_entities.append(enemy)
	else:
		for player in player_container.get_children():
			if player.selection_area_sprite.visible:
				highlighted_entities.append(player)
			
	if highlighted_entities.size() == 1:
		return highlighted_entities[0]
	return highlighted_entities

func highlight_check(is_aoe, targets_party, targets_self):
	if is_aoe:
		unselect_all()
		if targets_party:
			select_all_players()
		else:
			select_all_enemies()
	else:
		unselect_all()
		if targets_party:
			if not targets_self:
				make_players_selectable()
			select_individual(true, active_player_turn)
		else:
			make_enemies_selectable()
			select_individual(false, 0)

func hide_everything():
	revert_to_default_UI()

func set_health_bar_values(player_to_set_for):
	gui.get_player_portrait(player_to_set_for).get_node("HealthBar").value = get_player(player_to_set_for).stored_combatant.actual_stats.health
	gui.get_player_portrait(player_to_set_for).get_node("Health_Num").text = str(get_player(player_to_set_for).stored_combatant.actual_stats.health)
	

#endregion

#region Camera
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
	var camera_top_left = Vector2(-1,1.28)
	var camera_bottom_right = Vector2(1.8, -0.42)
	
	var person_spot
	if is_player:
		if what_entity != 4:
			person_spot = Vector2(player_container.position.x + get_player(what_entity).position.x, player_container.position.y + get_player(what_entity).position.y)
		else:
			person_spot = Vector2(player_container.position.x, player_container.position.y)
	else:
		if what_entity != 6:
			person_spot = Vector2(enemy_shit.position.x + enemy_shit.get_child(what_entity).position.x, enemy_shit.position.y + enemy_shit.get_child(what_entity).position.y)
		else:
			person_spot = Vector2(enemy_shit.position.x, enemy_shit.position.y)
	
	var midpoint = Vector2(((camera_bottom_right.x + camera_top_left.x)/2), (camera_top_left.y + camera_bottom_right.y)/2)
	
	var zoom = 8
	if what_entity == 6 or what_entity == 4:
		zoom = 10
		
	var offset = Vector2(midpoint.x - person_spot.x, midpoint.y - person_spot.y)
	
	return [-1 * offset.x, -1 *  offset.y, zoom, 1.0]

func revert_camera():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(camera, "h_offset", 0.0, 1)
	tween.tween_property(camera, "v_offset", 0.0, 1)
	tween.tween_property(camera, "fov", original_fov, 1)

#endregion

# Helper Functions

#region DAMAGE

func check_if_critical_hit(current_individual: combat_template, attacking: combat_template) -> bool:
	var chance_of_crit_hit = rng.randf_range(0.0, 1.0)
	
	var current_cc = current_individual.obtain_stat(current_individual.stats.CRIT_CHANCE)
	var attacker_cc = attacking.obtain_stat(attacking.stats.CRIT_CHANCE)
	print()
	print(current_cc - attacker_cc)
	print(((current_cc - attacker_cc) * 0.005) + 0.05)
	var crit_threshold = 0.05 + ((float(current_individual.obtain_stat(current_individual.stats.CRIT_CHANCE)) - float(attacking.obtain_stat(attacking.stats.CRIT_CHANCE))) * 0.005)
	return chance_of_crit_hit <= crit_threshold


func get_skill_boost(skill_used: moves) -> float:
	if skill_used.does_heal_party:
		match skill_used.amount_healed:
			0: return 1.0
			1: return 1.5
			2: return 999.0
	match skill_used.attack_power:
		0: return 1.25
		1: return 1.5
		2: return 2
	return 1.0

func calculate_damage(attacker: combat_template, skill_power: float, target: combat_template, is_magic: bool, can_crit: bool = true) -> Array:
	var atk = float(attacker.obtain_stat(
		attacker.stats.MAGIC if is_magic else attacker.stats.ATTACK
	))
	var def = float(target.obtain_stat(
		target.stats.RESISTANCE if is_magic else target.stats.DEFENSE
	))
	var level = float(attacker.stored_combatant.actual_stats.level)

	var level_factor = 5.0 + (level * 2.0)

	var base = (atk * level_factor) / max(def, 1.0)
	var damage = base * skill_power
	
	var is_crit = check_if_critical_hit(attacker, target)
	if can_crit:
		if is_crit:
			var crit_multiplier = float(1.5) + float(attacker.stored_combatant.actual_stats.crit_damage)
			damage *= crit_multiplier
	else:
		is_crit = 0

	damage *= rng.randf_range(0.95, 1.05)
	return [ceili(damage), 1 if is_crit else 0]


func calculate_evasion(entity_being_attacked: combat_template, attack_hit_chance: float = 90.0) -> float:
	var attacker_evasion = float(entity_being_attacked.obtain_stat(entity_being_attacked.stats.EVASION)) + 200.0
	var defender_evasion = float(entity_being_attacked.obtain_stat(entity_being_attacked.stats.EVASION)) + 200.0
	var accuracy_mod = entity_being_attacked.obtain_stat_alteration(entity_being_attacked.stats.ACCURACY)
	
	var base_hit_chance = (attacker_evasion / defender_evasion) * (attack_hit_chance / 100.0) * accuracy_mod
	
	if entity_being_attacked.stored_combatant.is_combatant_enemy:
		var equip_evasion = 0.0
		if entity_being_attacked.stored_combatant.stored_equipment and entity_being_attacked.stored_combatant.stored_equipment.equipment_stats:
			equip_evasion = float(entity_being_attacked.stored_combatant.stored_equipment.equipment_stats.evasion) * entity_being_attacked.obtain_stat_alteration(entity_being_attacked.stats.EVASION)
		var equipment_factor = attacker_evasion / ((equip_evasion / 2.0) + 200.0)
		return base_hit_chance * equipment_factor
	
	return base_hit_chance

func deal_damage(entity_attacking: combat_template, entity_being_attacked: combat_template, was_a_skill_used: bool, what_skill_was_used: moves) -> void:
	if not was_a_skill_used:
		var damage_result = calculate_damage(entity_attacking, 1.0, entity_being_attacked, false)
		await entity_being_attacked.update_health(damage_result[0], "DAMAGE" if damage_result[1] == 0 else "CRIT")
		return
		
	var portrait = gui.get_player_portrait(entity_being_attacked.child_number) if entity_attacking.stored_combatant.is_combatant_enemy else null
	
	if what_skill_was_used.multi_hit:
		await calculate_multi_hit(what_skill_was_used, entity_being_attacked, entity_attacking, get_skill_boost(what_skill_was_used))
	else:
		var damage_result = calculate_damage(entity_attacking, get_skill_boost(what_skill_was_used), entity_being_attacked, what_skill_was_used.is_magic_skill)
		await entity_being_attacked.update_health(damage_result[0], "DAMAGE" if damage_result[1] == 0 else "CRIT")

func calculate_multi_hit(skill_used: moves, target: combat_template, attacker: combat_template, skill_power: float):
	var check_evasion = calculate_evasion(target, float(skill_used.accuracy))
	var total_damage = []

	for hit in range(skill_used.max_hit_count):
		if hit < skill_used.guaranteed_hit_count:
			var damage_result = calculate_damage(attacker, skill_power, target, skill_used.is_magic_skill)
			total_damage.append(damage_result[0])
		else:
			var chance = rng.randf_range(0.0, 1.0)
			if chance < check_evasion:
				var damage_result = calculate_damage(attacker, skill_power, target, skill_used.is_magic_skill)

				total_damage.append(damage_result[0])
			else:
				total_damage.append("MISS")
	await target.update_health(total_damage, "MULTI")
#endregion

func execute_player_auto_turn(player_to_act, _turn_number, testing):
	if player_to_act.is_dead:
		return
	rng = RandomNumberGenerator.new()
	var possible_player_actions: Array[player_weighting] = []
	
	var enemy_to_attack_idx = rng.randi_range(0, enemy_shit.get_child_count() - 1)
	while(not enemy_shit.get_child(enemy_to_attack_idx).visible or enemy_shit.get_child(enemy_to_attack_idx).stored_combatant.is_dead):
		enemy_to_attack_idx = rng.randi_range(0, enemy_shit.get_child_count() - 1)
	
	var attacking_player: combat_template
	for player in player_container.get_children():
		if player_to_act == player.stored_combatant:
			attacking_player = player_container.get_child(player.get_index())
			
	for action in range(attacking_player.stored_combatant.combatant_skills.size() + 1):
		for enemy in enemy_shit.get_children():
			if not enemy.visible or not _is_living_combatant(enemy):
				continue
			if action == 0:
				var new_action = player_weighting.new(enemy_shit, player_container, attacking_player, enemy)
				possible_player_actions.append(new_action)
			elif attacking_player.stored_combatant.combatant_skills[action - 1].is_skill_aoe and enemy.get_index() > 0:
				continue
			else:
				var new_action = player_weighting.new(enemy_shit, player_container, attacking_player, enemy, true, attacking_player.stored_combatant.combatant_skills[action - 1])
				possible_player_actions.append(new_action)
				
		if action != 0:
			var skill = attacking_player.stored_combatant.combatant_skills[action - 1]
			if not skill.targets_party and not skill.targets_self:
				continue  # offensive skill, skip player targets entirely
			for player in player_container.get_children():
				if not _is_living_combatant(player):
					continue
				if attacking_player.stored_combatant.combatant_skills[action - 1].is_skill_aoe and player.get_index() > 0:
					continue
				var new_action = player_weighting.new(enemy_shit, player_container, attacking_player, player, false, attacking_player.stored_combatant.combatant_skills[action - 1])
				possible_player_actions.append(new_action)

	var finalized_player_actions: Array[player_weighting] = []
	for action: player_weighting in possible_player_actions:
		if action == null:
			continue
		if action.action_weight != 0:
			finalized_player_actions.append(action)
			
	for action: player_weighting in finalized_player_actions:
		action.set_action_weight(gather_player_action_weights(action))
		
	finalized_player_actions = sort_player_actions(finalized_player_actions)
	
	var total_weight_count = 0
	for action: player_weighting in finalized_player_actions:
		total_weight_count += action.action_weight
		
	var selected_action: player_weighting
	if finalized_player_actions.size() > 0:
		selected_action = finalized_player_actions[0]
		
		if total_weight_count > 0.0:
			var chance = rng.randf_range(0.0, total_weight_count)
			var current_sum = 0.0
			for action: player_weighting in finalized_player_actions:
				current_sum += action.action_weight
				if chance < current_sum:
					selected_action = action
					break
	
	await attacking_player.take_turn(gui.get_player_portrait(attacking_player.child_number))
		
	var action_sequence: Array[Callable]
	if selected_action.is_base_attack:
		var target_enemy = selected_action.targetting_who
		var damage_to_deal = calculate_damage(attacking_player, 1.0, target_enemy, false)
		var random_attack = rng.randi_range(0, 1)
		
		if not testing:
			action_sequence.append(func(): await attacking_player.walk_animation())
			action_sequence.append(func(): await attacking_player.walk_towards_entity(target_enemy.global_position))
			
			match random_attack:
				0:
					action_sequence.append(func(): await attacking_player.attack_animation(0))
				1:
					action_sequence.append(func(): await attacking_player.attack_animation(1))
	
		action_sequence.append(func(): await target_enemy.update_health(damage_to_deal, false))
		if not testing:
			action_sequence.append(func(): await attacking_player.walk_animation())

			action_sequence.append(func(): await attacking_player.walk_towards_entity(attacking_player.base_location))
			action_sequence.append(func(): await attacking_player.idle_animation())
		
		await action_queue(action_sequence)
	else:
		if not testing:
			action_sequence.append(func(): await attacking_player.walk_animation())
		if selected_action.skill_type.targets_party:
			action_sequence.append(func(): await execute_enemy_skills(selected_action))
		else:
			if not testing:
				action_sequence.append(func(): await attacking_player.walk_towards_entity(enemy_shit.get_child(enemy_to_attack_idx).global_position))
			action_sequence.append(func(): await execute_enemy_skills(selected_action))
			
		if not testing:
			var random_attack = rng.randi_range(0, 1)
			match random_attack:
				0:
					action_sequence.append(func(): await attacking_player.attack_animation(0))
				1:
					action_sequence.append(func(): await attacking_player.attack_animation(1))
			
			action_sequence.append(func(): await attacking_player.walk_animation())
			action_sequence.append(func(): await attacking_player.walk_towards_entity(attacking_player.base_location))
			action_sequence.append(func(): await attacking_player.idle_animation())
		
		await action_queue(action_sequence)

	turn_ended.emit()

class player_weighting:
	var is_base_attack: bool
	var skill_type 
	var targetting_enemy: bool
	var targetting_who
	var action_weight: float = 0.0
	var action_name: String
	var person_acting
	
	func _init(enemy_container, player_container, person_acting_node, target = null, targetting_enemy_param = true, skill_type_ref = null, initial_weight: int = 1):
		var opp_container
		var p_container
		
		opp_container = enemy_container
		p_container = player_container

		self.skill_type = skill_type_ref
		self.person_acting = person_acting_node
		self.targetting_enemy = targetting_enemy_param
		
		if target == null:
			self.action_weight = 0
			return
			
		if skill_type_ref != null:
			self.is_base_attack = false
			if skill_type_ref.mana_cost > person_acting.current_mana:
				self.action_weight = 0
				return
			if (skill_type_ref.targets_party or skill_type_ref.targets_self) and target.stored_combatant.is_combatant_enemy:
				self.action_weight = 0
				return
			if skill_type_ref.removes_status != null:
				if skill_type_ref.does_remove_status and not target.check_if_status_is_there(skill_type_ref.removes_status):
					self.action_weight = 0
					return
			if skill_type_ref.status_type != null:
				if skill_type_ref.does_status and skill_type_ref.status_type <= combat_template.statuses.AGRO and not target.check_if_status_is_there(skill_type_ref.status_type):
					self.action_weight = 0
					return
				
			if skill_type_ref.is_skill_aoe:
				if skill_type_ref.targets_party and not targetting_enemy_param:
					self.targetting_who = player_container.get_child_count()	
				elif not skill_type_ref.targets_party and target.stored_combatant.is_combatant_enemy:
					self.targetting_who = enemy_container.get_child_count()
				else:
					self.action_weight = 0
					return
					
				var should_do_status = 0
				if skill_type_ref.does_status or skill_type_ref.removes_status:
					if not skill_type_ref.targets_party:
						for enemy in enemy_container.get_children():
							if enemy.stored_combatant == null or not enemy.visible or enemy.stored_combatant.is_dead:
								continue
							if skill_type_ref.does_remove_status and enemy.check_if_status_is_there(skill_type_ref.removes_status):
								should_do_status += 1
							if skill_type_ref.does_status and skill_type_ref.status_type <= combat_template.statuses.AGRO and not enemy.check_if_status_is_there(skill_type_ref.status_type):
								should_do_status += 1
					else:
						for player in player_container.get_children():
							if player.stored_combatant == null or player.stored_combatant.is_dead:
								continue
							if skill_type_ref.does_remove_status and player.check_if_status_is_there(skill_type_ref.removes_status):
								should_do_status += 1
							if skill_type_ref.does_status and skill_type_ref.status_type <= combat_template.statuses.AGRO and player.check_if_status_is_there(skill_type_ref.removes_status):
								should_do_status += 1
				if should_do_status < 1:
					self.action_weight = 0
					return
			else:
				self.targetting_enemy = not skill_type_ref.targets_party
				self.targetting_who = target
				if self.targetting_who.stored_combatant.is_dead:
					self.action_weight = 0
					return
				if skill_type_ref.targets_party and skill_type_ref.does_heal_party:
					match skill_type_ref.amount_healed:
						0:
							if target.stored_combatant.actual_stats.health > (0.8 * target.stored_combatant.actual_stats.max_health):
								self.action_weight = 0
								return
						1:
							if target.stored_combatant.actual_stats.health > (0.6 * target.stored_combatant.actual_stats.max_health):
								self.action_weight = 0
								return
						2:
							if target.stored_combatant.actual_stats.health > (0.5 * target.stored_combatant.actual_stats.max_health):
								self.action_weight = 0
								return
			self.action_name = skill_type_ref.move_name
			self.is_base_attack = false
			self.action_weight += initial_weight
		else:
			self.is_base_attack = true
			self.targetting_enemy = true
			self.targetting_who = target
			self.action_name = "Base Attack"
			self.action_weight = initial_weight
			
	func set_action_weight(new_weight):
		self.action_weight = new_weight

class enemy_weighting:
	var is_base_attack: bool
	var skill_type: moves
	var targetting_player: bool
	var targetting_who
	var action_weight: float = 0.0
	var action_name : String
	var person_acting: combat_template
	# Mana cost, Adding status, Removing Status, Targets Party, Targets Self, Is Aoe, healing
	
	func _init(enemy_container, player_container, person_acting: combat_template, target = null, targetting_player = true, skill_type: moves= null, action_weight: int = 1):
		var opp_container
		var p_container
		if person_acting.stored_combatant.is_combatant_enemy:
			opp_container = player_container
			p_container = enemy_container
		else:
			opp_container = enemy_container
			p_container = player_container
		
		self.skill_type = skill_type
		self.person_acting = person_acting
		if target == null and not (skill_type != null and skill_type.does_summon):
			self.action_weight = 0
			return
		if skill_type != null:
			self.action_name = skill_type.move_name
			self.is_base_attack = false
			if skill_type.mana_cost > person_acting.current_mana:
				self.action_weight = 0
				return
			if not skill_type.does_summon:
				if (skill_type.targets_party or skill_type.targets_self) and not target.stored_combatant.is_combatant_enemy:
					self.action_weight = 0
					return
				if skill_type.removes_status != null:
					if skill_type.does_remove_status and not target.check_if_status_is_there(skill_type.removes_status):
						self.action_weight = 0
						return
				if skill_type.status_type != null:
					if skill_type.does_status and skill_type.status_type <= person_acting.statuses.AGRO and target.check_if_status_is_there(skill_type.status_type):
						self.action_weight = 0
						return
				if skill_type.is_skill_aoe:
					if skill_type.targets_party and not targetting_player:
						targetting_who = enemy_container.get_child_count()	
						self.targetting_player = false
					elif not skill_type.targets_party and not target.stored_combatant.is_combatant_enemy:
						targetting_who = player_container.get_child_count()
						self.targetting_player = true
					else:
						self.action_weight = 0
						return
					var should_do_status = 0
					if skill_type.does_status or skill_type.removes_status:
						if not skill_type.targets_party:
							for player in player_container.get_children():
								if player.stored_combatant == null or player.stored_combatant.is_dead:
									continue
								if skill_type.does_remove_status and player.check_if_status_is_there(skill_type.removes_status):
									should_do_status += 1
								if skill_type.does_status and skill_type.status_type <= person_acting.statuses.AGRO and not player.check_if_status_is_there(skill_type.status_type):
									should_do_status += 1
						else:
							for enemy in enemy_container.get_children():
								if enemy.stored_combatant == null or not enemy.visible:
									continue
								if enemy.stored_combatant.is_dead:
									continue
								if skill_type.does_remove_status and enemy.check_if_status_is_there(skill_type.removes_status):
									should_do_status += 1
								if skill_type.does_status and skill_type.status_type <= person_acting.statuses.AGRO and enemy.check_if_status_is_there(skill_type.removes_status):
									should_do_status += 1
						if should_do_status < 1 :
							self.action_weight = 0
							return
				else:
					self.targetting_player = not skill_type.targets_party
					self.targetting_who = target
					if targetting_who.stored_combatant.is_dead:
						self.action_weight = 0
						return
					if skill_type.targets_party and skill_type.does_heal_party:
						match skill_type.amount_healed:
							0:
								if target.stored_combatant.actual_stats.health > (0.8 * target.stored_combatant.actual_stats.max_health):
									self.action_weight = 0
									return
							1:
								if target.stored_combatant.actual_stats.health > (0.6 * target.stored_combatant.actual_stats.max_health):
									self.action_weight = 0
									return
							2:
								if target.stored_combatant.actual_stats.health > (0.5 * target.stored_combatant.actual_stats.max_health):
									self.action_weight = 0
									return
			else:
				if skill_type.summon_count_range.y + enemy_container.get_child_count() - 1 >= MAX_AMOUNT_OF_ENEMIES:
					self.action_weight = 0
					return
			action_name = skill_type.move_name
			is_base_attack = false
			self.action_weight += action_weight
		else:
			self.is_base_attack = true
			self.targetting_player = true
			targetting_who = target
			action_name = "Base Attack"
			self.action_weight = action_weight
	
	func set_action_weight(new_weight):
		self.action_weight = new_weight
		
func gather_true_action_weights(action_to_test: enemy_weighting):
	var new_weighting = 0
	if not action_to_test.is_base_attack:
		var skill_used = action_to_test.skill_type
		if skill_used.does_summon:
			var random_summon_count = randi_range(skill_used.summon_count_range.x, skill_used.summon_count_range.y)
			new_weighting += summon_importance * random_summon_count
			print()
		else:
			if skill_used.is_skill_aoe:
				if skill_used.targets_party:
					for enemy in enemy_shit.get_children():
						if not enemy.visible or not _is_living_combatant(enemy):
							continue
						if skill_used.does_remove_status and enemy.check_if_status_is_there(skill_used.removes_status):
							new_weighting += remove_status_weight
						if skill_used.does_status and not enemy.check_if_status_is_there(skill_used.status_type):
							new_weighting += give_self_status_weight
						if skill_used.aoe_heal:
							if get_skill_boost(skill_used) != 999:
								var amount_healted = action_to_test.person_acting.obtain_stat(action_to_test.person_acting.stats.MAGIC) + get_skill_boost(skill_used) * rng.randf_range(0.95, 1.05)
								new_weighting += (amount_healted / enemy.combatant_stats.max_health) * healing_importance_weight
							else:
								new_weighting += enemy.combatant_stats.max_health * healing_importance_weight
					new_weighting = new_weighting / (get_alive_player_or_enemy_count(not action_to_test.targetting_player))
				else:
					for player in player_container.get_children():
						if not _is_living_combatant(player):
							continue
						if skill_used.does_status and not player.check_if_status_is_there(skill_used.status_type):
							new_weighting += give_player_status_weight
						if skill_used.removes_status and  player.check_if_status_is_there(skill_used.removes_status):
							new_weighting += remove_players_status_weight
						var damage_done = calculate_damage(action_to_test.person_acting, get_skill_boost(skill_used), player, skill_used.is_magic_skill)
						if player.stored_combatant.actual_stats.health - damage_done[0] <= 0:
							new_weighting += kill_weight
						else:
							new_weighting += (damage_done[0] / player.stored_combatant.actual_stats.max_health) * damage_importance_weight
					new_weighting = new_weighting / (get_alive_player_or_enemy_count(action_to_test.targetting_player))
			else:
				var targetting_dude = action_to_test.targetting_who
				if skill_used.targets_party or skill_used.targets_self:
					if skill_used.does_heal_party:
						if get_skill_boost(skill_used) != 999:
							var amount_healted = action_to_test.person_acting.obtain_stat(action_to_test.person_acting.stats.MAGIC) + get_skill_boost(skill_used) * rng.randf_range(0.95, 1.05)
							new_weighting += (amount_healted / targetting_dude.stored_combatant.actual_stats.max_health) * healing_importance_weight
						else:
							new_weighting += targetting_dude.combatant_stats.max_health * healing_importance_weight

					if skill_used.does_status and not targetting_dude.check_if_status_is_there(skill_used.status_type):
						new_weighting += give_self_status_weight
					if skill_used.removes_status and targetting_dude.check_if_status_is_there(skill_used.removes_status): 
						new_weighting += remove_status_weight
				else:

					if skill_used.does_status and not targetting_dude.check_if_status_is_there(skill_used.status_type):
						new_weighting += give_player_status_weight
					if skill_used.removes_status and targetting_dude.check_if_status_is_there(skill_used.removes_status):
						new_weighting += remove_players_status_weight
					var damage_done = calculate_damage(action_to_test.person_acting, get_skill_boost(skill_used), targetting_dude, skill_used.is_magic_skill)
					if targetting_dude.stored_combatant.actual_stats.health - damage_done[0] <= 0:
						new_weighting += kill_weight
					else:
						new_weighting += (damage_done[0] / targetting_dude.stored_combatant.actual_stats.max_health) * (damage_importance_weight * 3)
		new_weighting += skill_importance
		print()

	else:
		var targetting_dude = action_to_test.targetting_who
		var damage_done = calculate_damage(action_to_test.person_acting, 1.0, targetting_dude, false)
		if targetting_dude.stored_combatant.actual_stats.health - damage_done[0] <= 0:
			new_weighting += kill_weight
		else:
			new_weighting += (damage_done[0] / targetting_dude.stored_combatant.actual_stats.max_health) * (damage_importance_weight * 3)
	return new_weighting + rng.randf_range(0.0, 2.0)

func gather_player_action_weights(action_to_test: player_weighting) -> float:
	var new_weighting: float = 0.0
	
	if not action_to_test.is_base_attack:
		var skill_used = action_to_test.skill_type
		new_weighting += p_skill_importance
		if skill_used.is_skill_aoe:
			if skill_used.targets_party:
				for player in player_container.get_children():
					if not _is_living_combatant(player):
						continue
					if skill_used.does_remove_status and ((skill_used.status_type <= action_to_test.person_acting.statuses.AGRO and player.check_if_status_is_there(skill_used.removes_status)) or (skill_used.status_type > action_to_test.person_acting.statuses.STUNIMMUNITY and player.check_if_status_is_there(skill_used.remove_status))):
						new_weighting += p_give_player_status_weight
					if skill_used.does_status and player.check_if_status_is_there(skill_used.does_status):
						new_weighting += p_remove_players_status_weight
					if skill_used.aoe_heal:
						if get_skill_boost(skill_used) != 999:
							var amount_healed = action_to_test.person_acting.obtain_stat(action_to_test.person_acting.stats.MAGIC) + get_skill_boost(skill_used) * rng.randf_range(0.95, 1.05)
							new_weighting += (amount_healed / player.stored_combatant.actual_stats.max_health) * p_healing_importance_weight
						else:
							new_weighting += player.stored_combatant.actual_stats.max_health * p_healing_importance_weight
				
				var divisor = get_alive_player_or_enemy_count(action_to_test.targetting_enemy)
				if divisor > 0:
					new_weighting = new_weighting / divisor
			else:
				for enemy in enemy_shit.get_children():
					if not enemy.visible or not _is_living_combatant(enemy):
						continue
					if skill_used.does_status:
						new_weighting += p_give_player_status_weight
					if skill_used.removes_status:
						new_weighting += p_remove_players_status_weight
					var damage_done = calculate_damage(action_to_test.person_acting, get_skill_boost(skill_used), enemy, skill_used.is_magic_skill)
					if enemy.stored_combatant.actual_stats.health - damage_done[0] <= 0:
						new_weighting += p_kill_weight
					else:
						new_weighting += (damage_done[0] / enemy.stored_combatant.actual_stats.max_health) * p_damage_importance_weight
				
				var divisor = get_alive_player_or_enemy_count(action_to_test.targetting_enemy)
				if divisor > 0:
					new_weighting = new_weighting / divisor
		else:
			var targetting_dude = action_to_test.targetting_who
			if skill_used.targets_party or skill_used.targets_self:
				if skill_used.does_heal_party:
					if get_skill_boost(skill_used) != 999:
						var amount_healed = action_to_test.person_acting.obtain_stat(action_to_test.person_acting.stats.MAGIC) + get_skill_boost(skill_used) * rng.randf_range(0.95, 1.05)
						new_weighting += (amount_healed / targetting_dude.stored_combatant.actual_stats.max_health) * p_healing_importance_weight
					else:
						new_weighting += targetting_dude.stored_combatant.actual_stats.max_health * p_healing_importance_weight

				if skill_used.does_status:
					new_weighting += p_give_self_status_weight
				if skill_used.removes_status:
					new_weighting += p_remove_status_weight
			else:
				if skill_used.does_status and targetting_dude.check_if_status_is_there(skill_used.status_type):
					new_weighting += p_give_player_status_weight
				if skill_used.removes_status and targetting_dude.check_if_status_is_there(skill_used.removes_status):
					new_weighting += p_remove_players_status_weight
				var damage_done = calculate_damage(action_to_test.person_acting, get_skill_boost(skill_used), targetting_dude, skill_used.is_magic_skill)
				if targetting_dude.stored_combatant.actual_stats.health - damage_done[0] <= 0:
					new_weighting += p_kill_weight
				else:
					new_weighting += (damage_done[0] / targetting_dude.stored_combatant.actual_stats.max_health) * p_damage_importance_weight
	else:
		var targetting_dude = action_to_test.targetting_who
		var damage_done = calculate_damage(action_to_test.person_acting, 1, targetting_dude, false)
		if targetting_dude.stored_combatant.actual_stats.health - damage_done[0] <= 0:
			new_weighting += p_kill_weight
		else:
			new_weighting += (damage_done[0] / targetting_dude.stored_combatant.actual_stats.max_health) * p_damage_importance_weight
			
	return new_weighting + rng.randf_range(0.0, 2.0)


func get_enemy_count():
	return enemy_shit.get_child_count()

func get_player_count():
	return player_container.get_child_count()

func can_select_things(what_thing):
	selecting_entity = true
	if what_thing is Items:
		if what_thing.is_aoe_item:
			if what_thing.does_what == 1:
				pass
			elif what_thing.does_what == 2:
				pass
		else:
			pass
	elif what_thing is moves:
		pass
	else:
		pass

func cant_select_stuff():
	selecting_entity = false
	for player in player_container.get_children():
		player.can_no_longer_be_selected()
	for enemy in enemy_shit.get_children():
		enemy.can_no_longer_be_selected()

func get_alive_player_or_enemy_count(is_player):
	var count = 0
	if is_player:
		for player in player_container.get_children():
			if not _is_living_combatant(player):
				continue
			count += 1
	else:
		for enemy in enemy_shit.get_children():
			if not enemy.visible or not _is_living_combatant(enemy):
				continue
			count += 1
	return count

func get_num_selected():
	var count = 0
	var player_ret_val = -1
	var enemy_ret_val = -1
	for player in player_container.get_children():
		if player.selection_area_sprite.visible:
			count += 1
	if count > 0:
		player_ret_val = count
	elif count == player_container.get_child_count() - 1:
		player_ret_val = 4
	count = 0
	for enemy in enemy_shit.get_children():
		if enemy.selection_area_sprite.visible:
			count += 1
	if count > 0:
		enemy_ret_val = enemy_shit.get_child_count() - 1
	elif count == enemy_shit.get_child_count() - 1:
		enemy_ret_val = 6
		
	if enemy_ret_val >= 0:
		return [enemy_ret_val, false]
	elif player_ret_val >= 0:
		return [player_ret_val, true]
		
		
func update_selected_enemy(what_direction):
	if gui.executing_skill:
		if gui.skill_menu.selected_item.targets_self:
			return
	
	AudioManager.play_ui_sound(AudioManager.SCROLL)
	var ret = get_num_selected()
	if ret[1]:
		if ret[0] == 4:
			return
		else:
			unselect_all()
			var updated_index = (current_selected_person + what_direction)
			var child_count = player_container.get_child_count() - 1
			var newly_selected_child = updated_index if updated_index < child_count and updated_index >= 0 else (0 if updated_index > child_count else child_count)
			while(not player_container.get_child(newly_selected_child).visible):
				updated_index += what_direction
				if updated_index > player_container.get_child_count():
					updated_index = 0
				elif updated_index < 0:
					updated_index = player_container.get_child_count() - 1
				newly_selected_child = updated_index if updated_index < child_count and updated_index >= 0 else (0 if updated_index > child_count else child_count)
			select_individual(true, newly_selected_child)
	else:
		if ret[0] == 6:
			return
		else:
			unselect_all()
			var updated_index = (current_selected_person + what_direction)
			var child_count = enemy_shit.get_child_count() - 1
			var newly_selected_child = updated_index if updated_index < child_count and updated_index >= 0 else (0 if updated_index > child_count else child_count)
			while(not enemy_shit.get_child(newly_selected_child).visible):
				updated_index += what_direction
				if updated_index > enemy_shit.get_child_count():
					updated_index = 0
				elif updated_index < 0:
					updated_index = enemy_shit.get_child_count() - 1
				newly_selected_child = updated_index if updated_index < child_count and updated_index >= 0 else (0 if updated_index > child_count else child_count)
			select_individual(false, newly_selected_child)
