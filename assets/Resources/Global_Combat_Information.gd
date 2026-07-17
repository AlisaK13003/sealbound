extends Node

var in_dungeon: bool = false

var active_party_slots: Array[generic_combatants]
var all_party_slots: Array[generic_combatants]

var currency_held: int = 200

var all_held_equipment: Array[equipment]
var all_held_weapons: Array[weapon]
var all_held_items: Array[Items]
var all_held_valuables: Array[Items]

var dungeon_types: Array[dungeon_type] = []

var active_quests: Array[quest]
var completed_quests: Array[quest]

var current_BP: int = 0
var max_BP: int = 0

@onready var rng = RandomNumberGenerator.new()

var bond_attack_fill 
var cur_bond_attack_val = 0

enum bonds {STRANGER, ACQAINTED, WARMED, KINDRED, BOUND, TRUEBOND}
enum dungeon_types_names {CREEPY, FOREST}
enum difficulty_multiplier {EASY, MEDIUM, DIFFICULT, REALLYHARD}

var holding_boss_key: int = 0
var holding_basic_room_key: int = 0

const FEMALE_MC_COMBATANT_PATH: String = "res://assets/characters/player/FMC_Combatant_Information.tres"
const MALE_MC_COMBATANT_PATH: String = "res://assets/characters/player/MMC_Combatant_Information.tres"

var all_character_information = [
	"res://assets/characters/sera/Sera_Combatant_Information.tres",
	"res://assets/characters/lyra/Lyra_Combatant_Information.tres",
	"res://assets/characters/rowan/Rowan_Combatant_Information.tres",
	"res://assets/characters/kaela/Kaela_Combatant_Information.tres",
	"res://assets/characters/cassian/Cassian_Combatant_Information.tres",
	"res://assets/characters/orion/Orion_dungeon_combatant.tres",
	FEMALE_MC_COMBATANT_PATH,
	MALE_MC_COMBATANT_PATH
]

signal finished

signal check_quest_progress
signal reached_end_of_dungeon
signal check_player_values

signal obtained_or_used_key

signal update_available_party_members

const MAX_PARTY_SIZE = 3

signal member_added
func new_members_available():
	for key in StateManager.party_member_unlocked:
		add_new_member(load(all_character_information[key]))
	member_added.emit()

func add_new_member(combatant: generic_combatants):
	var index = all_party_slots.find_custom(func(person: generic_combatants): return combatant.combatant_name == person.combatant_name)
	if index == -1:
		all_party_slots.append(combatant)
		combatant.gather_actual_stats()

func add_active_member(combatant: generic_combatants):
	if combatant == null:
		return
	var index = active_party_slots.find_custom(func(person: generic_combatants): return combatant.combatant_name == person.combatant_name)
	if index == -1:
		active_party_slots.append(combatant)
		check_player_values.emit()
		if active_party_slots.size() > MAX_PARTY_SIZE:
			Global.cant_leave_menu = true
	calculate_BP()

signal update_resonance
func resonate_with_a_member(which_member: generic_combatants, activated):
	for member in all_party_slots:
		if member.combatant_name == which_member.combatant_name and activated:
			member.resonated_with = true
		else:
			member.resonated_with = false
	resonance_updated(which_member.is_MC, activated)
	
func resonance_updated(is_mc = false, activated = false):
	var resonated_with_name
	if not is_mc and activated:
		for member in all_party_slots:
			if member.resonated_with:
				resonated_with_name = member.combatant_name
				break
	else:
		resonated_with_name = "Base"
			
	active_party_slots[0].update_moves(active_party_slots[0].resonance_skills_[resonated_with_name])
	update_resonance.emit()
	
func remove_active_member(combatant: generic_combatants):
	for combatant_ in range(active_party_slots.size()):
		if active_party_slots[combatant_].combatant_name == combatant.combatant_name:
			active_party_slots.remove_at(combatant_)
			break
	check_player_values.emit()
	if active_party_slots.size() <= MAX_PARTY_SIZE:
		Global.cant_leave_menu = false
	calculate_BP()

func calculate_BP():
	current_BP = 5
	max_BP = 5
	for member in active_party_slots:
		if not member.is_MC:
			current_BP += member.bond_level * 5
			max_BP += member.bond_level * 5

func apply_player_gender_to_combatant() -> void:
	var player_combatant: generic_combatants = _load_player_combatant_for_gender()
	if player_combatant == null:
		return
	var all_index: int = _find_mc_slot(all_party_slots)
	var active_index: int = _find_mc_slot(active_party_slots)
	var previous_combatant: generic_combatants = null
	if active_index != -1:
		previous_combatant = active_party_slots[active_index]
	elif all_index != -1:
		previous_combatant = all_party_slots[all_index]

	_copy_mc_progress(previous_combatant, player_combatant)
	player_combatant.is_MC = true
	player_combatant.gather_actual_stats()

	if all_index == -1:
		all_party_slots.insert(0, player_combatant)
	else:
		all_party_slots[all_index] = player_combatant

	if active_index == -1:
		active_party_slots.insert(0, player_combatant)
	else:
		active_party_slots[active_index] = player_combatant

	calculate_BP()
	check_player_values.emit()

func _load_player_combatant_for_gender() -> generic_combatants:
	var combatant_path: String = FEMALE_MC_COMBATANT_PATH
	var global_singleton = get_node_or_null("/root/Global")
	if global_singleton != null and Global.player_gender == "male":
		combatant_path = MALE_MC_COMBATANT_PATH
	var loaded_combatant = load(combatant_path)
	if loaded_combatant is generic_combatants:
		return loaded_combatant
	push_warning("Could not load player combatant at %s" % combatant_path)
	return null

func _find_mc_slot(slots: Array[generic_combatants]) -> int:
	for i in range(slots.size()):
		var member: generic_combatants = slots[i]
		if member == null:
			continue
		if member.is_MC or member.resource_path == FEMALE_MC_COMBATANT_PATH or member.resource_path == MALE_MC_COMBATANT_PATH:
			return i
	return -1

func _copy_mc_progress(previous_combatant: generic_combatants, new_combatant: generic_combatants) -> void:
	if previous_combatant == null or new_combatant == null or previous_combatant == new_combatant:
		return
	new_combatant.current_stored_slot = previous_combatant.current_stored_slot
	new_combatant.total_experience_points = previous_combatant.total_experience_points
	new_combatant.bond_points = previous_combatant.bond_points
	new_combatant.bond_level = previous_combatant.bond_level
	new_combatant.resonated_with = previous_combatant.resonated_with
	new_combatant.stored_weapon = previous_combatant.stored_weapon
	new_combatant.stored_equipment = previous_combatant.stored_equipment
	new_combatant.stored_charm = previous_combatant.stored_charm
	new_combatant.stored_boots = previous_combatant.stored_boots
	new_combatant.stored_chestplate = previous_combatant.stored_chestplate
	if previous_combatant.combatant_stats != null and new_combatant.combatant_stats != null:
		new_combatant.combatant_stats.level = previous_combatant.combatant_stats.level
		new_combatant.combatant_stats.health = clamp(
			previous_combatant.combatant_stats.health,
			0,
			new_combatant.combatant_stats.max_health
		)

signal did_something_with_BP
func do_something_with_BP(amount):
	current_BP = clamp(current_BP + amount, 0, max_BP)
	did_something_with_BP.emit()

signal did_something_with_money(old_amount, difference)
func update_currency(currency_change):
	var old_money_count = currency_held
	currency_held += currency_change
	did_something_with_money.emit(old_money_count, currency_change)

func _get_safe_combatant_level(combatant: generic_combatants) -> int:
	if combatant == null:
		return 1
	if combatant.combatant_stats != null:
		return max(1, int(combatant.combatant_stats.level))
	if combatant.actual_stats != null:
		return max(1, int(combatant.actual_stats.level))
	push_warning("Combatant '%s' has no stats resource for level rewards. Falling back to level 1." % combatant.combatant_name)
	return 1

func _ensure_combatant_stats_ready(combatant: generic_combatants) -> bool:
	if combatant == null or combatant.combatant_stats == null:
		return false
	if combatant.actual_stats == null:
		combatant.gather_actual_stats()
	return combatant.actual_stats != null

func check_if_member_is_active(combatant: generic_combatants):
	for combatant_ in active_party_slots:
		if combatant_.combatant_name == combatant.combatant_name:
			return true
	return false

func load_items():
	for i in range(15):
		add_item(load("res://assets/Resources/Dungeon Stuff/temp_item.tres"))
		add_item(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Health Potion.tres"))

func add_item(item_to_add):
	if item_to_add == null:
		return
	if item_to_add is Array:
		for item in item_to_add:
			if item.stack != 1: item.stack = 1
			if item.what_is_it & 010:
				if all_held_valuables.find(item) == -1:
					all_held_valuables.append(item.duplicate())
				else:
					all_held_valuables[all_held_valuables.find(item)].stack += 1
			else:
				if all_held_items.find(item) == -1:
					all_held_items.append(item.duplicate())
				else:
					all_held_items[all_held_items.find(item)].stack += 1
		check_quest_progress.emit()
		return
	if item_to_add.what_is_it & 010:
		if item_to_add.stack != 1: item_to_add.stack = 1
		if all_held_valuables.find(item_to_add) == -1:
			all_held_valuables.append(item_to_add)
		else:
			all_held_valuables[all_held_valuables.find(item_to_add)].stack += 1
	else:
		if item_to_add.stack != 1: item_to_add.stack = 1
		if all_held_items.find(item_to_add) == -1:
			all_held_items.append(item_to_add)
		else:
			all_held_items[all_held_items.find(item_to_add)].stack += 1
	check_quest_progress.emit()

func equipment_added_to_list(type, is_weapon):
	if is_weapon:
		all_held_weapons.append(type)
	else:
		all_held_equipment.append(type)
	equipment_added.emit()

signal equipment_added
signal stats_potentially_updated

func add_equipment_to_list(equip, is_weapon):
	if equip == null:
		return
	if equip.stack != 1: equip.stack = 1
	var index = search_for_index_of_thing(equip)
	if index != -1:
		if is_weapon:
			all_held_weapons[index].stack += 1
		else:
			all_held_equipment[index].stack += 1
	else:
		if is_weapon:
			all_held_weapons.append(equip.duplicate())
		else:
			all_held_equipment.append(equip.duplicate())
		if equip.stack == 0:
			equip.stack = 1
	equipment_added.emit()

func remove_thing(thing_to_remove, amount_to_remove):
	var index = search_for_thing(thing_to_remove)

	if index != null:
		var list_to_alter
		if thing_to_remove is equipment:
			list_to_alter = all_held_equipment
		if thing_to_remove is Items:
			if thing_to_remove.what_is_it & 010:
				list_to_alter = all_held_equipment
			elif thing_to_remove.what_is_it & 001:
				list_to_alter = all_held_items
			else:
				list_to_alter = all_held_equipment
		if thing_to_remove is weapon:
			list_to_alter = all_held_weapons
		
		index.stack -= amount_to_remove
		if index.stack <= 0:
			list_to_alter.erase(index)
		check_quest_progress.emit()
		equipment_added.emit()
		
func add_equipment(player_index, equip, is_weapon):
	var ret_equipment = null
	if is_weapon:
		if all_party_slots[player_index].stored_weapon != null:
			add_equipment_to_list(all_party_slots[player_index].stored_weapon, is_weapon)
			ret_equipment = all_party_slots[player_index].stored_weapon
		remove_thing(equip, 1)
		all_party_slots[player_index].stored_weapon = equip
	else:
		var equip_: equipment = equip
		match equip_.equipment_type:
			# Helmet
			0:
				if all_party_slots[player_index].stored_equipment != null:
					add_equipment_to_list(all_party_slots[player_index].stored_equipment, is_weapon)

					ret_equipment = all_party_slots[player_index].stored_equipment
				remove_thing(equip_, 1)
				all_held_equipment.erase(equip_)
				all_party_slots[player_index].stored_equipment = equip
				
			# Chestplate
			1:
				if all_party_slots[player_index].stored_chestplate != null:
					add_equipment_to_list(all_party_slots[player_index].stored_chestplate, is_weapon)
					ret_equipment = all_party_slots[player_index].stored_chestplate
				remove_thing(equip_, 1)
				all_party_slots[player_index].stored_chestplate = equip
			# Boots
			2:
				if all_party_slots[player_index].stored_boots != null:
					add_equipment_to_list(all_party_slots[player_index].stored_boots, is_weapon)
					ret_equipment = all_party_slots[player_index].stored_boots
				remove_thing(equip_, 1)
				all_party_slots[player_index].stored_boots = equip.duplicate()
			# Charm
			3:
				if all_party_slots[player_index].stored_charm != null:
					add_equipment_to_list(all_party_slots[player_index].stored_charm, is_weapon)
					ret_equipment = all_party_slots[player_index].stored_charm
				remove_thing(equip_, 1)
				all_party_slots[player_index].stored_charm = equip
	for member in all_party_slots:
		member.gather_actual_stats()
	equipment_added.emit()
	check_player_values.emit()
	return ret_equipment
	
func search_for_item(desired_item: Items):
	if all_held_items.find(desired_item) != -1:
		var found_index = all_held_items.find_custom(func(item: Items) -> bool: return item.item_name == desired_item.item_name)
		if found_index != -1:
			return all_held_items[found_index]
	if all_held_valuables.find(desired_item) != -1:
		var found_index = all_held_valuables.find_custom(func(item: Items) -> bool: return item.item_name == desired_item.item_name)
		if found_index != -1:
			return all_held_valuables[found_index]
	return null

func search_for_thing(desired_thing):
	if desired_thing is equipment:
		var found_index = all_held_equipment.find_custom(func(equip: equipment) -> bool: return equip.equipment_name == desired_thing.equipment_name)
		if found_index != -1:
			return all_held_equipment[found_index]
	elif desired_thing is weapon:
		var found_index = all_held_weapons.find_custom(func(equip: weapon) -> bool: return equip.weapon_name == desired_thing.weapon_name)
		if found_index != -1:
			return all_held_weapons[found_index]
	elif desired_thing is Items:
		return search_for_item(desired_thing)
	return null

func search_for_index_of_thing(desired_thing):
	if desired_thing is equipment:
		var found_index = all_held_equipment.find_custom(func(equip: equipment) -> bool: return equip.equipment_name == desired_thing.equipment_name)
		if found_index != -1:
			return found_index
	elif desired_thing is weapon:
		var found_index = all_held_weapons.find_custom(func(equip: weapon) -> bool: return equip.weapon_name == desired_thing.weapon_name)
		if found_index != -1:
			return found_index
	elif desired_thing is Items:
		if all_held_items.find(desired_thing) != -1:
			var found_index = all_held_items.find_custom(func(item: Items) -> bool: return item.item_name == desired_thing.item_name)
			if found_index != -1:
				return found_index
		if all_held_valuables.find(desired_thing) != -1:
			var found_index = all_held_valuables.find_custom(func(item: Items) -> bool: return item.item_name == desired_thing.item_name)
			if found_index != -1:
				return found_index
		return -1
	return -1

func add_quest(quest_: quest):
	active_quests.append(quest_)
	check_quest_progress.emit()

func complete_quest(quest_: quest):
	var quest_index = active_quests.find_custom(func(stored_quest: quest): return stored_quest.quest_name == quest_.quest_name)
	if quest_index != -1:
		completed_quests.append(quest_.duplicate())
		active_quests.remove_at(quest_index)

func _ready():	
	update_available_party_members.connect(new_members_available)
	var player_combatant: generic_combatants = _load_player_combatant_for_gender()
	if player_combatant != null:
		all_party_slots.append(player_combatant)
	#all_party_slots.append(load("res://assets/characters/rowan/Rowan_Combatant_Information.tres"))
	#all_party_slots.append(load("res://assets/characters/lyra/Lyra_Combatant_Information.tres"))
	#all_party_slots.append(load("res://assets/characters/orion/Orion_dungeon_combatant.tres"))
	#all_party_slots.append(load("res://assets/characters/sera/Sera_Combatant_Information.tres"))
	#all_party_slots.append(load("res://assets/characters/kaela/Kaela_Combatant_Information.tres"))
	for member in all_party_slots:
		member.gather_actual_stats()

	load_items()
	
	if not all_party_slots.is_empty():
		active_party_slots.append(all_party_slots[0])
	#active_party_slots.append(all_party_slots[1])
	#active_party_slots.append(all_party_slots[2])
	apply_player_gender_to_combatant()
	calculate_BP()
	dungeon_types.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Creepy_Dungeon.tres"))
	dungeon_types.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Forest_Dungeon.tres"))
	dungeon_types.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/First_Seal_Dungeon.tres"))
	
	#add_equipment_to_list(load("res://assets/Equipment/Training_Sword.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Dagger.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Sword.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Dagger.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Sword.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Dagger.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Sword.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Dagger.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Sword.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Dagger.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Sword.tres"), true)
	#add_equipment_to_list(load("res://assets/Equipment/Training_Dagger.tres"), true)

	
	#all_held_equipment.append(load("res://assets/Equipment/Gold_Bracelet.tres"))
	#all_held_equipment.append(load("res://assets/Equipment/Ruby Necklace.tres"))
	#all_held_equipment.append(load("res://assets/Equipment/Plated_Boots.tres"))
	#all_held_equipment.append(load("res://assets/Equipment/Leather_Helmet.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Leather_Boots.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Iron_Helmet.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Iron_Chestplate.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Lather_Chestplate.tres"))
	
	#active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"))
	#active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_Eyes.tres"))
	#active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"))
	#active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_Eyes.tres"))
	#active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"))
	#active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_Eyes.tres"))
	#active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"))
	#active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_Eyes.tres"))

	#completed_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_Eyes.tres"))
	#completed_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"))
	#completed_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_Eyes.tres"))
	#completed_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"))
	#completed_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_Eyes.tres"))

	await get_tree().create_timer(0.5).timeout	

	finished.emit()
	check_quest_progress.emit()
	
const amount_of_dungeons = 3

var explorable_dungeon_scene# : explorable_dungeon
var dungeon_loop_scene #: dungeon_loop

var selected_dungeon_

func transition_to_dungeon(selected_dungeon, quest_dungeon = null):
	AreaStateManager.currently_transitioning = true
	AudioManager.stop_bgm()
	selected_dungeon_ = selected_dungeon.type_of_dungeon
	current_dungeon = selected_dungeon
	
	match selected_dungeon_:
		0:
			AudioManager.play_bgm(AudioManager.CREEPY_DUNGEON_BGM)
		1:
			AudioManager.play_bgm(AudioManager.FOREST_DUNGEON_BGM)
	
	var dungeon_scene = await Fade.change_scene("res://scenes/Dungeon/Explorable_Dungeon_Test/Dungeon_Test.tscn")

	explorable_dungeon_scene = dungeon_scene

	for party_member in active_party_slots:
		max_BP += party_member.bond_level * 5
	bond_attack_fill = 2 * max_BP
	current_BP = max_BP
	AreaStateManager.currently_transitioning = false
	await dungeon_scene._setup(selected_dungeon, quest_dungeon)
		
func return_dropped_items(drops, player = null):
	drops.sort()
	var accumulated_chance: float = 0.0
	var drop_chances_: Array[float]
	for drop_chance in drops.values():
		drop_chances_.append(drop_chance)
		
	drop_chances_.sort_custom(func(a, b): return drop_chances_[a] < drop_chances_[b])
	var chance = rng.randf()
	var dropped_items
	for new_chance in drop_chances_:
		if chance < new_chance + accumulated_chance:
			GlobalCombatInformation.add_item(drops.find_key(new_chance))
			if player != null:
				player.display_obtained_items(drops.find_key(new_chance))
			dropped_items = drops.find_key(new_chance)
			break
		accumulated_chance += new_chance
	if player == null:
		return dropped_items
	
var is_combat_active: bool = false
var previous_enemy_encountered
var should_remove_enemy = false

func dungeon_over(passed_out: bool = false):
	await Fade.fade_in(1.0)
	holding_boss_key = 0
	holding_basic_room_key = 0
	
	for member in all_party_slots:
		member.restore_health()
	check_player_values.emit()
	if dungeon_loop_scene != null:
		dungeon_loop_scene.queue_free()
	if explorable_dungeon_scene != null:
		explorable_dungeon_scene.queue_free()
	Global.current_region = "Buildings_Insides"
	Global.current_loading_zone = "Bedroom"
	AreaStateManager._setup(passed_out)
	AreaStateManager.swap_scene()
		
	await get_tree().process_frame
	#await get_tree().physics_frame
	get_tree().current_scene.swap_to_me()
	await Fade.fade_out(1.0)
	Global.player_advanced_day(false)
	
	#AreaStateManager.swap_scene(null)
	
	in_dungeon = false
	

var current_dungeon

func initiate_combat(encounter, node_id, is_boss: bool = false):
	AudioManager.stop_bgm()
	if is_combat_active:
		return
	var temp2 = load("res://assets/Resources/Dungeon Stuff/Dungeon_25D.tscn")
	dungeon_loop_scene = temp2.instantiate()
	AudioManager.play_ui_sound(AudioManager.ENCOUNTER)
	is_combat_active = true
	previous_enemy_encountered = node_id
	await Fade.fade_in(0.5)
	get_tree().root.call_deferred("remove_child", explorable_dungeon_scene)
	get_tree().root.call_deferred("add_child", dungeon_loop_scene)
	#get_tree().current_scene = dungeon_loop_scene
	await get_tree().process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var output = await dungeon_loop_scene.setup(dungeon_types[selected_dungeon_], encounter, is_boss)
	var enemies_killed = output[0]
	var did_players_win = output[1]
	print("YOU KJILLED ", enemies_killed)
	# output[2] = [party_slot_1, party_slot_2, party_slot_3, current_bond_points, gui.bond_bar.value]
	
	var returned_party_slots: Array = output[2]
	var party_result_count: int = mini(3, active_party_slots.size())
	for i in range(party_result_count):
		if i >= returned_party_slots.size():
			continue
		if returned_party_slots[i] == null:
			continue
		active_party_slots[i] = returned_party_slots[i].duplicate()
	
	if returned_party_slots.size() > 3:
		current_BP = returned_party_slots[3]

	if did_players_win:
		should_remove_enemy = true
	else:
		dungeon_over(true)
		return
	
	var coins_gained: int = 0
	var experience_gained: int = 0
	var bond_gained: int = 0
	var stuff_gained = []
	var quest_items_gained = []
	
	var enemies_to_check = []
	for quest_: quest in active_quests:
		for thing in quest_.completion_requirements.keys():
			if thing is Items:
				break
			elif thing is generic_combatants:
				enemies_to_check.append(thing)
	
	for enemy: generic_combatants in enemies_killed:
		if enemy == null:
			continue
		var is_quest_target = enemies_to_check.any(func(e): return e.combatant_name == enemy.combatant_name)
		print("ARE YOU A QUEST TARGET ", is_quest_target )
		if is_quest_target and enemy.quest_item_drop != null:
			var chance = rng.randf()
			if chance < 1.0:
				var drop_num = rng.randi_range(1, 3)
				for i in range(drop_num):
					quest_items_gained.append(enemy.quest_item_drop.duplicate())
				
		coins_gained += int(randi_range(enemy.coin_drop_range.x, enemy.coin_drop_range.y) * randf_range(0.5, 1.5))
		var enemy_level: int = _get_safe_combatant_level(enemy)
		experience_gained += clamp(int(pow(enemy_level, enemy.experience_mult + 1) * randf_range(0.5, 1.2)), 1, enemy.experience_mult + 1 * 1.2)
		var returned_items = return_dropped_items(enemy.drop_table)
		if returned_items != null:
			stuff_gained.append(returned_items)
		bond_gained += int(randi_range(enemy.bond_drop_range.x, enemy.bond_drop_range.y) * randf_range(0.5, 1.2))
	
	var exp_divisor = max(1, active_party_slots.size() - 1)
	for player: generic_combatants in active_party_slots:
		if not _ensure_combatant_stats_ready(player):
			continue
		player.add_experience(int(float(experience_gained) / exp_divisor))
	
	for player: generic_combatants in active_party_slots:
		var index = all_party_slots.find_custom(func(person: generic_combatants): return player.combatant_name == person.combatant_name)
		if index != -1:
			all_party_slots[index] = player.duplicate()
			all_party_slots[index].gather_actual_stats()
		
	currency_held += coins_gained
	check_quest_progress.emit()

	if stuff_gained == null and quest_items_gained != null: 
		stuff_gained = quest_items_gained
	elif stuff_gained != null and quest_items_gained != null:
		stuff_gained += quest_items_gained

	if is_boss:
		dungeon_over()
		return

	if stuff_gained != null:
		add_item(stuff_gained)

	check_player_values.emit()
	await Fade.fade_in(1)
	get_tree().root.remove_child(dungeon_loop_scene)
	var temp_rewards = load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Dungeon_Reward_Screen.tscn")
	var rewards_scene = temp_rewards.instantiate()
	get_tree().root.add_child(rewards_scene)
	get_tree().current_scene = rewards_scene
	rewards_scene._setup(coins_gained, experience_gained, bond_gained, stuff_gained)
	rewards_scene_ = rewards_scene
	
var rewards_scene_
func bring_back_combat(_rewards_scene = null):
	AreaStateManager.currently_transitioning = true
	AudioManager.stop_bgm()
	match selected_dungeon_:
		0:
			AudioManager.play_bgm(AudioManager.CREEPY_DUNGEON_BGM)
		1:
			AudioManager.play_bgm(AudioManager.FOREST_DUNGEON_BGM)
	get_tree().root.add_child.call_deferred(explorable_dungeon_scene)
	
	explorable_dungeon_scene.set_deferred("movement_locked", false)
	
	if is_instance_valid(rewards_scene_):
		rewards_scene_.queue_free()
	
	if is_instance_valid(dungeon_loop_scene) and dungeon_loop_scene.is_inside_tree():
		dungeon_loop_scene.get_parent().remove_child.call_deferred(dungeon_loop_scene)
		dungeon_loop_scene.queue_free()
	
	if should_remove_enemy:
		var enemy_to_remove = instance_from_id(previous_enemy_encountered)
		explorable_dungeon_scene.enemy_container.remove_child(enemy_to_remove)
		enemy_to_remove.queue_free()
		#explorable_dungeon_scene.enemy_container.remove_child(previous_enemy_encountered)
	
	is_combat_active = false
	get_tree().set_deferred("current_scene", explorable_dungeon_scene)
	explorable_dungeon_scene.return_to_exploring()
	AreaStateManager.currently_transitioning = false

func update_stored_combat_information():
	pass

func load_saved_data(data):
	#all_party_slots.clear()
	active_party_slots.clear()
	all_held_equipment.clear()
	all_held_weapons.clear()
	all_held_items.clear()
	active_quests.clear()
	completed_quests.clear()

	for party_member in data["player_slots"].values():
		if not ResourceLoader.exists(party_member["path"], ""):
			continue
		var new_party_member: generic_combatants = load(party_member["path"])
		var index = all_party_slots.find_custom(func(member: generic_combatants): return new_party_member.combatant_name == member.combatant_name)
		if index != -1:
			continue
			
		
		new_party_member.load_save(party_member)
		new_party_member.gather_actual_stats()
		all_party_slots.append(new_party_member)

	for equipment_ in data["equipment_slots"].values():
		if not ResourceLoader.exists(equipment_["path"], ""):
			continue
		var new_equipment = load(equipment_["path"])
		if new_equipment == null:
			continue
		add_equipment_to_list(new_equipment, false)
		var index = search_for_index_of_thing(new_equipment)
		all_held_equipment[index].stack = equipment_["stack"]

	for weapon_ in data["weapon_slots"].values():
		if not ResourceLoader.exists(weapon_["path"], ""):
			continue
		var new_equipment = load(weapon_["path"])
		if new_equipment == null:
			continue
		add_equipment_to_list(new_equipment, true)

		var index = search_for_index_of_thing(new_equipment)
		all_held_equipment[index].stack = weapon_["stack"]

	for item_ in data["item_slots"].values():
		if not ResourceLoader.exists(item_["path"], ""):
			continue
		var new_item = load(item_["path"])
		if new_item == null:
			continue
		add_item(new_item)
		var index = search_for_index_of_thing(new_item)

		all_held_items[index].stack = item_["stack"]
		
	for a_quest in data["active_quests"].values():
		if not ResourceLoader.exists(a_quest["path"], ""):
			continue
		active_quests.append(load(a_quest["path"]))

	for com_quest in data["com_quests"].values():
		if not ResourceLoader.exists(com_quest["path"], ""):
			continue
		completed_quests.append(load(com_quest["path"]))

	currency_held = int(data["held_currency"])

	if data.has("active_slots"):
		for idx in data["active_slots"]:
			var i = int(idx)
			print("ACTGIVE PARTY SLOT SIZE: ", active_party_slots.size())
			if active_party_slots.size() >= MAX_PARTY_SIZE:
				break 
			if i >= 0 and i < all_party_slots.size():
				active_party_slots.append(all_party_slots[i])
			
	calculate_BP()
	for combatant in all_party_slots:
		combatant.gather_actual_stats()
	var dungeons = dungeon_types.duplicate()
	for dungeon in range(dungeons.size()):
		if dungeon > amount_of_dungeons:
			dungeon_types.erase(dungeons[dungeon])
	print()
	
func export_to_JSON():
	var ret_dict: Dictionary = {}
	var player_slots: Dictionary = {}
	var equipment_slots: Dictionary = {}
	var weapon_slots: Dictionary = {}
	var item_slots: Dictionary = {}
	var active_quest_slots: Dictionary = {}
	var completed_quest_list: Dictionary = {}

	for party_member in range(all_party_slots.size()):
		var new_key = "slot_" + str(party_member)
		all_party_slots[party_member].current_stored_slot = party_member
		player_slots[new_key] = all_party_slots[party_member].export_to_JSON()

	for equipment_ in range(all_held_equipment.size()):
		equipment_slots["slot_" + str(equipment_)] = all_held_equipment[equipment_].export_to_JSON()

	for weapon_ in range(all_held_weapons.size()):
		weapon_slots["slot_" + str(weapon_)] = all_held_weapons[weapon_].export_to_JSON()

	for item_ in range(all_held_items.size()):
		item_slots["slot_" + str(item_)] = all_held_items[item_].export_to_JSON()

	for quest_ in range(active_quests.size()):
		active_quest_slots["quest_" + str(quest_)] = active_quests[quest_].export_to_JSON()

	for com_quest_ in range(completed_quests.size()):
		completed_quest_list["quest_" + str(com_quest_)] = completed_quests[com_quest_].export_to_JSON()

	var active_indices: Array = []
	for member in active_party_slots:
		var exists = all_party_slots.find_custom(func(person: generic_combatants) -> bool: return member.combatant_name == person.combatant_name)
		if active_indices.size() > 2:
			break
		if exists != -1:
			active_indices.append(exists)

	ret_dict["player_slots"] = player_slots
	ret_dict["active_slots"] = active_indices
	ret_dict["equipment_slots"] = equipment_slots
	ret_dict["weapon_slots"] = weapon_slots
	ret_dict["item_slots"] = item_slots
	ret_dict["active_quests"] = active_quest_slots
	ret_dict["com_quests"] = completed_quest_list
	ret_dict["held_currency"] = currency_held

	return ret_dict
