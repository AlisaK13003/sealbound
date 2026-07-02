extends Node

class_name dungeon_loop

#region Variables
@export var party_slot_1 : generic_combatants
@export var party_slot_2: generic_combatants
@export var party_slot_3: generic_combatants

@export var temp_item_list : Array[Items]

@onready var gui: dungeon_gui = $UI/DungeonPlayerGui

@onready var slot_1: combat_template = $Player_Container/Player_Slot1
@onready var slot_2: combat_template = $Player_Container/Player_Slot2
@onready var slot_3: combat_template = $Player_Container/Player_Slot3

@onready var player_container: Node = $Player_Container

@onready var enemy_shit: Node = $Enemy_Container

@onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var floor_tiles: Node = $Background/Floor_Tiles
@onready var walls: Node = $Background/Walls

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
var skill_importance: float = 0

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

#region Initialization
var training: bool = false
var testing: bool = false
func _ready():
	return
	Fade.fade_thing.visible = false
	Fade.fade_thing_2.visible = false
	gui.hide_gui(false)
	if testing:
		gui._setup(self)
		
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
	
	slot_1.setup(party_slot_1.duplicate(true), self, 0)
	slot_2.setup(party_slot_2.duplicate(true), self, 1)
	slot_3.setup(party_slot_3.duplicate(true), self, 2)
	
	all_combatants.append(slot_1)
	all_combatants.append(slot_2)
	all_combatants.append(slot_3)
	
	gui.get_player_portrait(0)._setup(party_slot_1)
	gui.get_player_portrait(1)._setup(party_slot_2)
	gui.get_player_portrait(2)._setup(party_slot_3)
	
	#get_player(0).update_health([0, ""], false, get_player_portrait(0))
	#get_player(1).update_health([0, ""], false, get_player_portrait(1))
	#get_player(2).update_health([0, ""], false, get_player_portrait(2))
	
	#item_menu.setup(temp_item_list, self)
	if not training:
		await GlobalCombatInformation.load_items()
		temp_item_list = GlobalCombatInformation.all_held_items

func hide():
	self.visible = false
	gui.visible = false
	gui.get_child(0).visible = false

func setup(current_dungeon_type: dungeon_type, encounter: dungeon_wave, is_boss: bool ):
	#Fade.fade_thing.visible = false
	#Fade.fade_thing_2.visible = false
	gui.call_deferred("hide_gui", false)
	self.current_dungeon_run = current_dungeon_type
	temp_item_list = GlobalCombatInformation.all_held_items
	current_bond_points = GlobalCombatInformation.current_BP
	max_bond_points_ = GlobalCombatInformation.max_BP

	for child in floor_tiles.get_children():
		if child.get_index() == current_dungeon_type.type_of_dungeon:
			child.visible = true
		else:
			child.visible = false
			
	for wall in walls.get_children():
		wall._setup(current_dungeon_type.type_of_dungeon)

	gui.get_player_portrait(0)._setup(GlobalCombatInformation.active_party_slots[0])
	gui.get_player_portrait(1)._setup(GlobalCombatInformation.active_party_slots[1])
	gui.get_player_portrait(2)._setup(GlobalCombatInformation.active_party_slots[2])

	await gui._setup(self)
	slot_1.setup(GlobalCombatInformation.active_party_slots[0], self, 0)
	slot_2.setup(GlobalCombatInformation.active_party_slots[1], self, 1)
	slot_3.setup(GlobalCombatInformation.active_party_slots[2], self, 2)
	
	all_combatants.append(slot_1)
	all_combatants.append(slot_2)
	all_combatants.append(slot_3)
	
	await _reset()
	
	return await battle_loop(encounter, is_boss)
	
	#item_menu.setup(temp_item_list, self)

#endregion

#region CombatHelpers
func determine_order() -> void:
	all_combatants.clear()
	
	for slot in $Player_Container.get_children():
		all_combatants.append(slot)
	for enemy_slot in enemy_shit.get_children():
		if enemy_slot.visible:
			all_combatants.append(enemy_slot)
	
	all_combatants.sort_custom(func(a, b) -> int:
		return a.obtain_stat(5) > b.obtain_stat(5)
	)

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
			new_enemy_instance.position = Vector3(0.0, 0.0, 1.5)
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
	# Main battle loop, continues until every wave has been fought, or party dies
	for i in range(number_of_waves_to_fight):
		highest_wave_reached += 1
		turn_count = 0
		is_wave_over = false
		setup_encounter(encounter, is_boss)
		await Fade.fade_out(1)
		# Handles individual waves, continues until wave concludes
		while(not is_wave_over):
			turn_count += 1
			determine_order()
			for j in range(all_combatants.size()):
				if j >= all_combatants.size():
					continue
					
				# After each turn checks if all players or all enemies are dead
				var number_of_alive_enemies = 0
				var number_of_alive_players = 0
				
				if slot_1.stored_combatant.is_dead:
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
					if not player.stored_combatant.is_dead:
						number_of_alive_players += 1
				# Wait so all animations can finish
				if not training:
					await get_tree().create_timer(1).timeout
				
				
				if number_of_alive_enemies == 0:
					is_wave_over = true
					did_players_win = true
					break
				elif number_of_alive_players == 0:
					is_wave_over = true
					did_players_win = false
					break
					
				var current_combatant = all_combatants[j]
				if current_combatant.stored_combatant == null or current_combatant.stored_combatant.is_dead:
					all_combatants.remove_at(j)
					j -= 1
					continue
				# Enemy Turn
				elif current_combatant.stored_combatant.is_combatant_enemy:
					active_player_turn = current_combatant.child_number
					await execute_enemy_turn(current_combatant.stored_combatant, turn_count, training)
				# Player Turn
				else:	
					active_player_turn = current_combatant.child_number
					if training:
						print("HII")
						await execute_player_auto_turn(current_combatant.stored_combatant, turn_count, training)
					else:
						var thing = await handle_player_move_selection(current_combatant.stored_combatant)

						if thing == "RUN":
							return killed_enemies
				hidden_default()
				

				
				# If either are wiped then wave is over
				#if number_of_alive_enemies <= 0 or number_of_alive_players <= 0:
				#	is_wave_over = true
				#	for player in player_container.get_children():
				#		if player.stored_combatant.is_dead:
				#			number_of_killed_players += 1
				#		else:
				#			cum_player_health += player.stored_combatant.combatant_stats.health
#
				#	for enemy in enemy_shit.get_children():
				#		if enemy.stored_combatant == null:
				#			continue
				#		if enemy.stored_combatant.is_dead:
				#			number_of_killed_enemies += 1
				#	break
		if i != number_of_waves_to_fight - 1:
			gui.next_floor(i)
			await get_tree().create_timer(2).timeout
			
	party_slot_1 = get_player(0).stored_combatant.duplicate()
	party_slot_2 = get_player(1).stored_combatant.duplicate()
	party_slot_3 = get_player(2).stored_combatant.duplicate()
			
	var ret_val = [party_slot_1, party_slot_2, party_slot_3, current_bond_points, gui.bond_bar.value]
	print(current_bond_points)
	return [killed_enemies, did_players_win, ret_val]
	#return [number_of_killed_players, number_of_killed_enemies, player_container, highest_wave_reached, number_of_waves_to_fight, cum_player_health, skills_enemies_have_used]

#region EntityTurns

func execute_enemy_turn(enemy_to_attack, _turn_number, testing):
	if enemy_to_attack.is_dead:
		return
	
	rng = RandomNumberGenerator.new()
	var possible_enemy_actions: Array[enemy_weighting]
	
	var attacking_enemy: combat_template
	var doing_player = false
	for enemy in enemy_shit.get_children():
		if enemy_to_attack == enemy.stored_combatant:
			attacking_enemy = enemy
	for action in range(attacking_enemy.stored_combatant.combatant_skills.size() + 1):
		for player in player_container.get_children():
			if player.stored_combatant.is_dead:
				continue
			if action == 0:
				var new_action = enemy_weighting.new(enemy_shit, player_container, attacking_enemy, player)
				possible_enemy_actions.append(new_action)
				continue
			else:
				var new_action = enemy_weighting.new(enemy_shit, player_container, attacking_enemy, player, true, attacking_enemy.stored_combatant.combatant_skills[action - 1])
				possible_enemy_actions.append(new_action)
				continue
		if action != 0:
			if attacking_enemy.stored_combatant.combatant_skills[action - 1].targets_party:
				for enemy in enemy_shit.get_children():
					if not enemy.visible:
						continue
					var new_action = enemy_weighting.new(enemy_shit, player_container, attacking_enemy, enemy, false, attacking_enemy.stored_combatant.combatant_skills[action - 1])
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
	$AudioStreamPlayer3D.stream = load("res://assets/Resources/SFX/Eye-laser.wav")
	if selected_action.is_base_attack:
		if testing:
			action_sequence.append(func(): await deal_damage(attacking_enemy, selected_action.targetting_who, false, null))
		if not testing:
			#action_sequence.append(func(): await attacking_enemy.walk_animation())
			#action_sequence.append(func(): await attacking_enemy.walk_towards_entity(selected_action.targetting_who.global_position))
			action_sequence.append(func(): await attacking_enemy.attack_animation(0))
			action_sequence.append(func(): $AudioStreamPlayer3D.play())


			action_sequence.append(func(): deal_damage(attacking_enemy, selected_action.targetting_who, false, null))
		
		#set_health_bar_values(selected_action.targetting_who.child_number)
		await action_queue(action_sequence)
	else:
		#if not testing:
			#action_sequence.append(func(): await attacking_enemy.walk_animation())
			#if not selected_action.skill_type.targets_party and not selected_action.skill_type.is_skill_aoe:
			#	action_sequence.append(func(): await attacking_enemy.walk_towards_entity(selected_action.targetting_who.global_position))
			#elif selected_action.skill_type.targets_party:
			#	action_sequence.append(func(): await attacking_enemy.walk_towards_entity(selected_action.targetting_who.global_position))
			#else:
			#	action_sequence.append(func(): await attacking_enemy.walk_towards_entity(get_player(0).global_position))

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
	var acting_entity = enemy_shit if action.skill_type.targets_party else player_container
	var skill_used: moves = action.skill_type
	var person_acting = action.person_acting
	var person_recieving = action.targetting_who
	var action_sequence : Array[Callable]
	var parallel_tasks : Array[Callable]
	if skill_used.targets_party:
		if skill_used.is_skill_aoe:
			for enemy in enemy_shit.get_children():
				if not enemy.visible:
					continue
				if enemy.stored_combatant.is_dead:
					continue
				if skill_used.does_heal_party:
					if get_skill_boost(skill_used) != 999:
						parallel_tasks.append(func(): await enemy.update_health(-1 * (person_acting.obtain_stat(person_acting.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL"))
					else:
						parallel_tasks.append(func(): await enemy.update_health(-1 * enemy.stored_combatant.combatant_stats.max_health, "HEAL"))
				# Does this skill apply a status to every party member
				if skill_used.does_status:
					parallel_tasks.append(func(): await enemy.handle_status(skill_used.status_type))
				if skill_used.does_remove_status:
					parallel_tasks.append(func(): await enemy.remove_status(skill_used.removes_status))
		else:
			if skill_used.does_heal_party:
				if get_skill_boost(skill_used) != 999:
					parallel_tasks.append(func(): await person_recieving.update_health(-1 * (person_recieving.obtain_stat(person_recieving.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL"))
				else:
					parallel_tasks.append(func(): await person_recieving.update_health(-1 * person_recieving.stored_combatant.combatant_stats.max_health, "HEAL"))
			if skill_used.does_status:
				action_sequence.append(func(): await person_recieving.handle_status(skill_used.status_type))
			if skill_used.removes_status:
				action_sequence.append(func(): await person_recieving.remove_status(skill_used.removes_status))
	else:
		if skill_used.is_skill_aoe:
			for player in player_container.get_children():
				if player.stored_combatant.is_dead:
					continue
				var chance = rng.randf_range(0, 1)
				if skill_used.does_damage:
					parallel_tasks.append(func(): await deal_damage(person_acting, player, true, skill_used))
				if skill_used.does_status:
					chance = rng.randf_range(0, 1)
					if chance <= skill_used.chance_of_status_condition:
						parallel_tasks.append(func(): await player.handle_status(skill_used.status_type))
				if skill_used.removes_status:
					chance = rng.randf_range(0, 1)
					if chance <= skill_used.chance_of_status_condition:
						parallel_tasks.append(func(): await player.remove_status(skill_used.removes_status))
		else:
			var check_evasion = calculate_evasion(person_recieving, skill_used.accuracy)
			var chance = rng.randf_range(0, 1)
			if skill_used.does_status and chance <= skill_used.chance_of_status_condition:
				action_sequence.append(func(): await person_recieving.handle_status(skill_used.status_type))
			if skill_used.removes_status and chance <= skill_used.chance_of_status_condition:
				action_sequence.append(func(): await person_recieving.remove_status(skill_used.removes_status))
			if skill_used.multi_hit:
				if skill_used.does_damage:
					parallel_tasks.append(func(): await deal_damage(action.person_acting, person_recieving, true, skill_used))
			else:
				if skill_used.does_damage:
					chance = rng.randf_range(0, 1)
					if chance <= check_evasion:
						parallel_tasks.append(func(): await deal_damage(action.person_acting, person_recieving, true, skill_used))
					else:
						parallel_tasks.append(func(): await person_recieving.update_health(0, "MISS"))
	person_acting.current_mana = clamp(person_acting.current_mana - skill_used.mana_cost, 0, 3)

	action_sequence.insert(0, func(): await await_parallel(parallel_tasks))
	await action_queue(action_sequence)
	return

#region PARTY

func get_player(player_to_get: int):
	return $Player_Container.get_child(player_to_get)

func handle_player_move_selection(current_combatant):
	var what_action = null
	selecting_entity = false
	await gui.new_player_turn(temp_item_list)
	#gui.get_player_portrait(active_player_turn).position.y -=10
	make_enemies_selectable()
	select_individual(false, 0)
	what_action = await action_taken
	var action_sequence: Array[Callable]
	var current_player = get_player(active_player_turn)
	match what_action[0]:
		"BASIC_ATTACK":
			var target_node = enemy_shit.get_child(what_action[1])

			if testing:
				action_sequence.append(func(): await deal_damage(current_combatant, target_node, false, null))
			if not testing:
				action_sequence.append(func(): await current_player.attack_animation(0))
				action_sequence.append(func(): $AudioStreamPlayer3D.play())
				action_sequence.append(func(): await deal_damage(current_player, target_node, false, null))

		"BASIC_DEFEND":
			action_sequence.append(func(): await current_player.execute_defend())
		"SKILL":
			var action_on_who = what_action[2] if get_num_selected()[0] == 1 else 0
			
			var skill_index = 0
			for skill in range(current_player.stored_combatant.combatant_skills.size()):
				if current_player.stored_combatant.combatant_skills[skill] == what_action[1]:
					skill_index = skill
			
			if action_on_who != 6:
				var target_node = enemy_shit.get_child(action_on_who)

			action_sequence.append(func(): await current_player.attack_animation(skill_index + 1))
			action_sequence.append(func(): $AudioStreamPlayer3D.play())
			action_sequence.append(func(): await execute_skills(what_action))
		"ITEM":
			#action_sequence.append(func(): await sci_fi_enhance_zoom(get_camera_offset(what_action[1].targets_players, what_action[2] if what_action[2] < 5 else (6 if not what_action[1].targets_party else 4))))
			action_sequence.append(func(): await execute_item(what_action[1], what_action[3], what_action[2]))
		"RUN":
			return "RUN"
	#action_sequence.append(func(): await revert_camera())
	await action_queue(action_sequence)
	await get_player(active_player_turn).take_turn(gui.get_player_portrait(active_player_turn))
	gui.get_player_portrait(active_player_turn).update_statuses(get_player(active_player_turn))
	#gui.get_player_portrait(active_player_turn).position.y += 10
	selecting_entity = false

	turn_ended.emit()

func attack_button_pressed():
	if not selecting_entity:
		return
	for enemy in enemy_shit.get_children():
		if enemy.selection_area_sprite.visible:
			#sci_fi_enhance_zoom(get_camera_offset(false, enemy.get_index()))
			selecting_entity = false
			await no_one_can_be_selected()
			action_taken.emit("BASIC_ATTACK", enemy.get_index())

func defend_button_pressed():
	no_one_can_be_selected()
	var person_defending = get_player(active_player_turn).stored_combatant
	gui.setup_confirmation_button("Defend", person_defending.combatant_name, person_defending)
	var confirmed = await actual_confirmation
	if confirmed:
		action_taken.emit("BASIC_DEFEND", false)
		hidden_default()
	else:
		revert_to_default_UI()

func skill_selected(what_skill: moves):
	var action_on_who
	highlight_check(what_skill.is_skill_aoe, what_skill.targets_party, what_skill.targets_self)
	#sci_fi_enhance_zoom(get_camera_offset(what_skill.targets_party, 6 if not what_skill.targets_party else 4))
	gui.hide_gui(true)
	gui._executing_skill(true, what_skill)
	action_on_who = await confirmation
	if not action_on_who is bool:
		#await sci_fi_enhance_zoom(get_camera_offset(what_skill.targets_party, action_on_who if not what_skill.is_skill_aoe else (6 if not what_skill.targets_party else 4)))
		action_taken.emit("SKILL", what_skill, action_on_who)
		await no_one_can_be_selected()
		return
	else:
		if action_on_who:
			var count = 0
			var last_selectable_entity = 0
			if what_skill.targets_party:
				for player in player_container.get_children():
					if player.selection_area_sprite.visible:
						count += 1
						last_selectable_entity = player.get_index()
				if count < player_container.get_child_count() - 1:
					action_on_who = last_selectable_entity
				else:
					action_on_who = 4
			else:
				for enemy in enemy_shit.get_children():
					if enemy.selection_area_sprite.visible:
						count += 1
						last_selectable_entity = enemy.get_index()
				if count < enemy_shit.get_child_count() - 1:
					action_on_who = last_selectable_entity
				else:
					action_on_who = 6
			
			#sci_fi_enhance_zoom(get_camera_offset(what_skill.targets_party, action_on_who if not what_skill.is_skill_aoe else (6 if not what_skill.targets_party else 4)))
			action_taken.emit("SKILL", what_skill, action_on_who)
			await no_one_can_be_selected()
		else:
			revert_camera()
			no_one_can_be_selected()

func item_selected(item_used: Items, index_of_item_used):
	var action_on_who
	highlight_check(item_used.is_aoe_item, item_used.targets_players, false)
	#sci_fi_enhance_zoom(get_camera_offset(item_used.targets_players, 6 if not item_used.targets_players else 4))
	gui.hide_gui(true)
	gui._executing_item(true, item_used)
	selecting_entity = true
	action_on_who = await confirmation
	if not (action_on_who is bool):
		await no_one_can_be_selected()
		#await sci_fi_enhance_zoom(get_camera_offset(item_used.targets_players, action_on_who if not item_used.is_aoe_item else (6 if not item_used.targets_players else 4)))
		action_taken.emit("ITEM", item_used, action_on_who if not item_used.is_aoe_item else (6 if not item_used.targets_players else 4), index_of_item_used)
	else:
		if action_on_who:
			var count = 0
			var last_selectable_entity = 0
			if item_used.targets_players:
				for player in player_container.get_children():
					if player.selection_area_sprite.visible:
						count += 1
						last_selectable_entity = player.get_index()
				if count < player_container.get_child_count() - 1:
					action_on_who = last_selectable_entity
				else:
					action_on_who = 4
			else:
				for enemy in enemy_shit.get_children():
					if enemy.selection_area_sprite.visible:
						count += 1
						last_selectable_entity = enemy.get_index()
				if count < enemy_shit.get_child_count() - 1:
					action_on_who = last_selectable_entity
				else:
					action_on_who = 6
			await no_one_can_be_selected()
			#sci_fi_enhance_zoom(get_camera_offset(item_used.targets_players, action_on_who if not item_used.is_aoe_item else (6 if not item_used.targets_players else 4)))
			action_taken.emit("ITEM", item_used, action_on_who if not item_used.is_aoe_item else 4, index_of_item_used)
		else:
			revert_camera()
			no_one_can_be_selected()
	selecting_entity = false

# what_action[1] is the skill itself and what_action[2] is who it targets
func execute_skills(what_action):
	var skill_used: moves = what_action[1]
	var current_player = get_player(active_player_turn)
	var action_sequence : Array[Callable]
	var parallel_tasks : Array[Callable]
	#update_health(change_health_value, what_action)
	if skill_used.targets_party:
		if skill_used.is_skill_aoe:
			for player: combat_template in player_container.get_children():
				if player.stored_combatant.is_dead:
					continue
				var seq_task: Array[Callable] = []
				var par_task : Array[Callable] = []

				seq_task.append(func(): await get_tree().create_timer(0.25 * player.get_index()).timeout)
				if skill_used.does_heal_party:
					if get_skill_boost(skill_used) != 999:
						par_task.append(func(): await player.update_health(-1 * (current_player.obtain_stat(current_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL"))
					else:
						par_task.append(func(): await player.update_health(-1 * player.stored_combatant.combatant_stats.max_health, "HEAL"))
				# Does this skill apply a status to every party member
				if skill_used.does_status:
					par_task.append(func(): await player.handle_status(skill_used.status_type))
				if skill_used.does_remove_status:
					par_task.append(func(): await player.remove_status(skill_used.removes_status))
				seq_task.append(func(): await_parallel(par_task))
				parallel_tasks.append(func(): await action_queue(seq_task))
				
			action_sequence.append(func(): await await_parallel(parallel_tasks))
		else:
			var targetted_player: combat_template = player_container.get_child(what_action[2])
			if skill_used.does_heal_party:
				if get_skill_boost(skill_used) != 999:
					parallel_tasks.append(func(): await targetted_player.update_health(-1 * (current_player.obtain_stat(targetted_player.stats.MAGIC) + get_skill_boost(skill_used)) * rng.randf_range(0.95, 1.05), "HEAL"))
				else:
					parallel_tasks.append(func(): await targetted_player.update_health(-1 * targetted_player.stored_combatant.combatant_stats.max_health, "HEAL"))
			if skill_used.does_status:
				action_sequence.append(func(): await targetted_player.handle_status(skill_used.status_type))
			if skill_used.removes_status:
				action_sequence.append(func(): await targetted_player.remove_status(skill_used.removes_status))
	else:
		if skill_used.is_skill_aoe:
			for enemy: combat_template in enemy_shit.get_children():
				if not enemy.visible or enemy.stored_combatant.is_dead:
					continue
				var chance = rng.randf_range(0, 1)
				var seq_task: Array[Callable] = []
				var par_task : Array[Callable] = []

				seq_task.append(func(): await get_tree().create_timer(0.25 * enemy.get_index()).timeout)
				if skill_used.does_damage:
					par_task.append(func(): await deal_damage(current_player, enemy, true, skill_used))

				if skill_used.does_status:
					chance = rng.randf_range(0, 1)
					if chance <= skill_used.chance_of_status_condition:
						par_task.append(func(): await enemy.handle_status(skill_used.status_type))
				if skill_used.removes_status:
					chance = rng.randf_range(0, 1)
					if chance <= skill_used.chance_of_status_condition:
						par_task.append(func(): await enemy.remove_status(skill_used.removes_status))
				seq_task.append(func(): await await_parallel(par_task))
				parallel_tasks.append(func(): await action_queue(seq_task))
		else:
			var targetted_enemy = enemy_shit.get_child(what_action[2])
			var check_evasion = calculate_evasion(targetted_enemy, skill_used.accuracy)
			var chance = rng.randf_range(0, 1)
			if skill_used.does_status and chance <= skill_used.chance_of_status_condition:
				action_sequence.append(func(): await targetted_enemy.handle_status(skill_used.status_type))
			if skill_used.removes_status and chance <= skill_used.chance_of_status_condition:
				action_sequence.append(func(): await targetted_enemy.remove_status(skill_used.removes_status))
			if skill_used.multi_hit:
				if skill_used.does_damage:
					parallel_tasks.append(func(): await deal_damage(current_player, targetted_enemy, true, skill_used))
			else:
				if skill_used.does_damage:
					chance = rng.randf_range(0, 1)
					if chance <= check_evasion:
						parallel_tasks.append(func(): await deal_damage(current_player, targetted_enemy, true, skill_used))
					else:
						parallel_tasks.append(func(): await targetted_enemy.update_health(0, "MISS"))
	parallel_tasks.append(func(): await gui.update_mana_display(-1 * skill_used.mana_cost, false))
	action_sequence.insert(0, func(): await await_parallel(parallel_tasks))
	await action_queue(action_sequence)
	return


func execute_item(what_item: Items, item_index, targets_who):
	var action_sequence : Array[Callable]
	var parallel_tasks : Array[Callable]
	
	if what_item.targets_players:
		if what_item.is_aoe_item:
			for player_num in range(player_container.get_child_count()):
				var player = get_player(player_num)
				if player.stored_combatant.is_dead:
					continue
				
				var seq_task: Array[Callable] = []
				var par_task : Array[Callable] = []

				seq_task.append(func(): await get_tree().create_timer(0.25 * player.get_index()).timeout)
				
				if what_item.does_what == 2:
					par_task.append(func(): await player.update_health(-1 * what_item.amount_to_heal_or_deal, "HEAL"))
				if what_item.removes_status != null:
					par_task.append(func(): await player.remove_status(what_item.removes_status))
				if what_item.give_status != null:
					par_task.append(func(): await player.handle_status(what_item.give_status))
				
				seq_task.append(func(): await await_parallel(par_task))
				parallel_tasks.append(func(): await action_queue(seq_task))
		else:
			var targetted_player = get_player(targets_who)
			if what_item.does_what == 2:
				parallel_tasks.append(func(): await targetted_player.update_health(-1 * what_item.amount_to_heal_or_deal, "HEAL"))
			if what_item.removes_status != null:
				action_sequence.append(func(): await targetted_player.remove_status(what_item.removes_status))
			if what_item.give_status != null:
				action_sequence.append(func(): await targetted_player.handle_status(what_item.give_status))
	else:
		if what_item.is_aoe_item:
			for enemy in enemy_shit.get_children():
				if not enemy.visible or enemy.stored_combatant.is_dead:
					continue
				
				var seq_task: Array[Callable] = []
				var par_task : Array[Callable] = []

				seq_task.append(func(): await get_tree().create_timer(0.25 * enemy.get_index()).timeout)
				
				if what_item.does_what == 1:
					par_task.append(func(): await enemy.update_health(what_item.amount_to_heal_or_deal, "DAMAGE"))
				if what_item.removes_status != null:
					par_task.append(func(): await enemy.remove_status(what_item.removes_status))
				if what_item.give_status != null:
					par_task.append(func(): await enemy.handle_status(what_item.give_status))
				
				seq_task.append(func(): await await_parallel(par_task))
				parallel_tasks.append(func(): await action_queue(seq_task))
		else:
			var targetted_enemy = enemy_shit.get_child(targets_who)
			if what_item.does_what == 1:
				parallel_tasks.append(func(): await targetted_enemy.update_health(what_item.amount_to_heal_or_deal, "DAMAGE"))
			if what_item.removes_status != null:
				action_sequence.append(func(): await targetted_enemy.remove_status(what_item.removes_status))
			if what_item.give_status != null:
				action_sequence.append(func(): await targetted_enemy.handle_status(what_item.give_status))
				
	# Remove the item immediately from the inventory list
	temp_item_list.remove_at(item_index)
	
	action_sequence.insert(0, func(): await await_parallel(parallel_tasks))
	await action_queue(action_sequence)
	return

#endregion
	
#endregion

#region ENEMIES



#endregion

#region Actions

func get_who_skill_targets_aoe(skill_used: moves, person_using_skill: generic_combatants):
	if not person_using_skill.is_combatant_enemy:
		if skill_used.is_skill_aoe:
			if skill_used.targets_party:
				return 4
			else:
				var count = 0
				for enemy in enemy_shit.get_children():
					if enemy.visible:
						count += 1
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

func unselect_all(is_player):
	if is_player:
		for player in player_container.get_children():
			player.unselect()
	else:
		for enemy in enemy_shit.get_children():
			enemy.unselect()

# Puts the selection arrow over an individual
func select_individual(is_player, index):
	current_selected_person = index
	index -= 1
	while(true):
		index += 1
		if is_player:
			if index >= 3:
				break
			if get_player(index).stored_combatant.is_dead:
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

func make_players_selectable():
	selecting_entity = true
	for player in player_container.get_children():
		if player.stored_combatant.is_dead:
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
		if not player.stored_combatant.is_dead:
			player.selected(false)
	
func select_all_enemies():
	selecting_entity = false
	for enemy in enemy_shit.get_children():
		if not enemy.visible:
			continue
		if enemy.visible or not enemy.stored_combatant.is_dead:
			enemy.selected(false)

func highlight_check(is_aoe, targets_party, targets_self):
	if is_aoe:
		unselect_all(targets_party)
		if targets_party:
			select_all_players()
		else:
			select_all_enemies()
	else:
		unselect_all(targets_party)
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
	gui.get_player_portrait(player_to_set_for).get_node("HealthBar").value = get_player(player_to_set_for).stored_combatant.combatant_stats.health
	gui.get_player_portrait(player_to_set_for).get_node("Health_Num").text = str(get_player(player_to_set_for).stored_combatant.combatant_stats.health)
	

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

func check_if_critical_hit(current_individual: combat_template) -> bool:
	var chance_of_crit_hit = rng.randf_range(0.0, 1.0)
	var crit_threshold = 0.04 + (float(current_individual.obtain_stat(current_individual.stats.CRIT_CHANCE)) / 100.0)
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

func calculate_damage(attacker: combat_template, skill_power: float, target: combat_template, is_magic: bool) -> Array:
	var atk = float(attacker.obtain_stat(
		attacker.stats.MAGIC if is_magic else attacker.stats.ATTACK
	))
	var def = float(target.obtain_stat(
		target.stats.RESISTANCE if is_magic else target.stats.DEFENSE
	))
	var level = float(attacker.stored_combatant.combatant_stats.level)

	# Level curve: starts at 5, grows meaningfully
	var level_factor = 5.0 + (level * 2.0)

	var base = (atk * level_factor) / max(def, 1.0)
	var damage = base * skill_power

	var is_crit = check_if_critical_hit(attacker)
	if is_crit:
		var crit_multiplier = float(1.5)
		damage *= crit_multiplier

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
			if not enemy.visible or enemy.stored_combatant.is_dead:
				continue
			if action == 0:
				var new_action = await player_weighting.new(enemy_shit, player_container, attacking_player, enemy)
				possible_player_actions.append(new_action)
			elif attacking_player.stored_combatant.combatant_skills[action - 1].is_skill_aoe and enemy.get_index() > 0:
				continue
			else:
				var new_action = await player_weighting.new(enemy_shit, player_container, attacking_player, enemy, true, attacking_player.stored_combatant.combatant_skills[action - 1])
				possible_player_actions.append(new_action)
				
		if action != 0:
			var skill = attacking_player.stored_combatant.combatant_skills[action - 1]
			if not skill.targets_party and not skill.targets_self:
				continue  # offensive skill, skip player targets entirely
			for player in player_container.get_children():
				if player.stored_combatant.is_dead:
					continue
				if attacking_player.stored_combatant.combatant_skills[action - 1].is_skill_aoe and player.get_index() > 0:
					continue
				var new_action = await player_weighting.new(enemy_shit, player_container, attacking_player, player, false, attacking_player.stored_combatant.combatant_skills[action - 1])
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
							if not enemy.visible or enemy.stored_combatant.is_dead:
								continue
							if skill_type_ref.does_remove_status and enemy.check_if_status_is_there(skill_type_ref.removes_status):
								should_do_status += 1
							if skill_type_ref.does_status and skill_type_ref.status_type <= combat_template.statuses.AGRO and not enemy.check_if_status_is_there(skill_type_ref.status_type):
								should_do_status += 1
					else:
						for player in player_container.get_children():
							if player.stored_combatant.is_dead:
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
							if target.stored_combatant.combatant_stats.health > (0.8 * target.stored_combatant.combatant_stats.max_health):
								self.action_weight = 0
								return
						1:
							if target.stored_combatant.combatant_stats.health > (0.6 * target.stored_combatant.combatant_stats.max_health):
								self.action_weight = 0
								return
						2:
							if target.stored_combatant.combatant_stats.health > (0.5 * target.stored_combatant.combatant_stats.max_health):
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
		if target == null:
			self.action_weight = 0
			return
		if skill_type != null:
			self.action_name = skill_type.move_name
			self.is_base_attack = false
			if skill_type.mana_cost > person_acting.current_mana:
				self.action_weight = 0
				return
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
							if player.stored_combatant.is_dead:
								continue
							if skill_type.does_remove_status and player.check_if_status_is_there(skill_type.removes_status):
								should_do_status += 1
							if skill_type.does_status and skill_type.status_type <= person_acting.statuses.AGRO and not player.check_if_status_is_there(skill_type.status_type):
								should_do_status += 1
					else:
						for enemy in enemy_container.get_children():
							if not enemy.visible:
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
							if target.stored_combatant.combatant_stats.health > (0.8 * target.stored_combatant.combatant_stats.max_health):
								self.action_weight = 0
								return
						1:
							if target.stored_combatant.combatant_stats.health > (0.6 * target.stored_combatant.combatant_stats.max_health):
								self.action_weight = 0
								return
						2:
							if target.stored_combatant.combatant_stats.health > (0.5 * target.stored_combatant.combatant_stats.max_health):
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
		if skill_used.is_skill_aoe:
			if skill_used.targets_party:
				for enemy in enemy_shit.get_children():
					if not enemy.visible or enemy.stored_combatant.is_dead:
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
					if player.stored_combatant.is_dead:
						continue
					if skill_used.does_status and not player.check_if_status_is_there(skill_used.status_type):
						new_weighting += give_player_status_weight
					if skill_used.removes_status and  player.check_if_status_is_there(skill_used.removes_status):
						new_weighting += remove_players_status_weight
					var damage_done = calculate_damage(action_to_test.person_acting, get_skill_boost(skill_used), player, skill_used.is_magic_skill)
					if player.stored_combatant.combatant_stats.health - damage_done[0] <= 0:
						new_weighting += kill_weight
					else:
						new_weighting += (damage_done[0] / player.stored_combatant.combatant_stats.max_health) * damage_importance_weight
				new_weighting = new_weighting / (get_alive_player_or_enemy_count(action_to_test.targetting_player))
		else:
			var targetting_dude = action_to_test.targetting_who
			if skill_used.targets_party or skill_used.targets_self:
				if skill_used.does_heal_party:
					if get_skill_boost(skill_used) != 999:
						var amount_healted = action_to_test.person_acting.obtain_stat(action_to_test.person_acting.stats.MAGIC) + get_skill_boost(skill_used) * rng.randf_range(0.95, 1.05)
						new_weighting += (amount_healted / targetting_dude.stored_combatant.combatant_stats.max_health) * healing_importance_weight
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
				if targetting_dude.stored_combatant.combatant_stats.health - damage_done[0] <= 0:
					new_weighting += kill_weight
				else:
					new_weighting += (damage_done[0] / targetting_dude.stored_combatant.combatant_stats.max_health) * (damage_importance_weight * 3)
		new_weighting += skill_importance

	else:
		var targetting_dude = action_to_test.targetting_who
		var damage_done = calculate_damage(action_to_test.person_acting, 1.0, targetting_dude, false)
		if targetting_dude.stored_combatant.combatant_stats.health - damage_done[0] <= 0:
			new_weighting += kill_weight
		else:
			new_weighting += (damage_done[0] / targetting_dude.stored_combatant.combatant_stats.max_health) * (damage_importance_weight * 3)
	return new_weighting + rng.randf_range(0.0, 2.0)

func gather_player_action_weights(action_to_test: player_weighting) -> float:
	var new_weighting: float = 0.0
	
	if not action_to_test.is_base_attack:
		var skill_used = action_to_test.skill_type
		new_weighting += p_skill_importance
		if skill_used.is_skill_aoe:
			if skill_used.targets_party:
				for player in player_container.get_children():
					if player.stored_combatant.is_dead:
						continue
					if skill_used.does_remove_status and ((skill_used.status_type <= action_to_test.person_acting.statuses.AGRO and player.check_if_status_is_there(skill_used.removes_status)) or (skill_used.status_type > action_to_test.person_acting.statuses.STUNIMMUNITY and player.check_if_status_is_there(skill_used.remove_status))):
						new_weighting += p_give_player_status_weight
					if skill_used.does_status and player.check_if_status_is_there(skill_used.does_status):
						new_weighting += p_remove_players_status_weight
					if skill_used.aoe_heal:
						if get_skill_boost(skill_used) != 999:
							var amount_healed = action_to_test.person_acting.obtain_stat(action_to_test.person_acting.stats.MAGIC) + get_skill_boost(skill_used) * rng.randf_range(0.95, 1.05)
							new_weighting += (amount_healed / player.stored_combatant.combatant_stats.max_health) * p_healing_importance_weight
						else:
							new_weighting += player.stored_combatant.combatant_stats.max_health * p_healing_importance_weight
				
				var divisor = get_alive_player_or_enemy_count(action_to_test.targetting_enemy)
				if divisor > 0:
					new_weighting = new_weighting / divisor
			else:
				for enemy in enemy_shit.get_children():
					if not enemy.visible or enemy.stored_combatant.is_dead:
						continue
					if skill_used.does_status:
						new_weighting += p_give_player_status_weight
					if skill_used.removes_status:
						new_weighting += p_remove_players_status_weight
					var damage_done = calculate_damage(action_to_test.person_acting, get_skill_boost(skill_used), enemy, skill_used.is_magic_skill)
					if enemy.stored_combatant.combatant_stats.health - damage_done[0] <= 0:
						new_weighting += p_kill_weight
					else:
						new_weighting += (damage_done[0] / enemy.stored_combatant.combatant_stats.max_health) * p_damage_importance_weight
				
				var divisor = get_alive_player_or_enemy_count(action_to_test.targetting_enemy)
				if divisor > 0:
					new_weighting = new_weighting / divisor
		else:
			var targetting_dude = action_to_test.targetting_who
			if skill_used.targets_party or skill_used.targets_self:
				if skill_used.does_heal_party:
					if get_skill_boost(skill_used) != 999:
						var amount_healed = action_to_test.person_acting.obtain_stat(action_to_test.person_acting.stats.MAGIC) + get_skill_boost(skill_used) * rng.randf_range(0.95, 1.05)
						new_weighting += (amount_healed / targetting_dude.stored_combatant.combatant_stats.max_health) * p_healing_importance_weight
					else:
						new_weighting += targetting_dude.stored_combatant.combatant_stats.max_health * p_healing_importance_weight

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
				if targetting_dude.stored_combatant.combatant_stats.health - damage_done[0] <= 0:
					new_weighting += p_kill_weight
				else:
					new_weighting += (damage_done[0] / targetting_dude.stored_combatant.combatant_stats.max_health) * p_damage_importance_weight
	else:
		var targetting_dude = action_to_test.targetting_who
		var damage_done = calculate_damage(action_to_test.person_acting, 1, targetting_dude, false)
		if targetting_dude.stored_combatant.combatant_stats.health - damage_done[0] <= 0:
			new_weighting += p_kill_weight
		else:
			new_weighting += (damage_done[0] / targetting_dude.stored_combatant.combatant_stats.max_health) * p_damage_importance_weight
			
	return new_weighting + rng.randf_range(0.0, 2.0)

func get_enemy_count():
	return enemy_shit.get_child_count()

func get_player_count():
	return player_container.get_child_count()

func get_alive_player_or_enemy_count(is_player):
	var count = 0
	if is_player:
		for player in player_container.get_children():
			if player.stored_combatant.is_dead:
				continue
			count += 1
	else:
		for enemy in enemy_shit.get_children():
			if not enemy.visible or enemy.stored_combatant.is_dead:
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
	print(current_selected_person)
	
	var ret = get_num_selected()
	print(ret)
	if ret[1]:
		if ret[0] == 4:
			return
		else:
			unselect_all(true)
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
			unselect_all(false)
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
