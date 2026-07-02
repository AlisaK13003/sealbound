extends Node

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

var holding_boss_key: bool = false
var holding_basic_room_key: bool = false

signal finished

signal check_quest_progress

func load_items():
	var new_item = load("res://assets/Resources/Dungeon Stuff/temp_item.tres")
	for i in range(5):
		all_held_items.append(new_item.duplicate())

func add_item(item_to_add):
	if item_to_add is Array:
		for item in item_to_add:
			if item.what_is_it & 010:
				all_held_valuables.append(item)
			else:
				all_held_items.append(item)
		check_quest_progress.emit()
		return
	if item_to_add.what_is_it & 010:
		all_held_valuables.append(item_to_add)
	else:
		all_held_items.append(item_to_add)
	check_quest_progress.emit()
	
func add_equipment(player_index, equip, is_weapon):
	var ret_equipment = null
	if is_weapon:
		
		if all_party_slots[player_index].stored_weapon != null:
			all_held_weapons.append(all_party_slots[player_index].stored_weapon)
			ret_equipment = all_party_slots[player_index].stored_weapon
		all_held_weapons.erase(equip)
		all_party_slots[player_index].stored_weapon = equip
	else:
		var equip_: equipment = equip
		match equip_.equipment_type:
			# Helmet
			0:
				if all_party_slots[player_index].stored_equipment != null:
					all_held_equipment.append(all_party_slots[player_index].stored_equipment)
					ret_equipment = all_party_slots[player_index].stored_equipment
				all_held_equipment.erase(equip_)
				all_party_slots[player_index].stored_equipment = equip
				
			# Chestplate
			1:
				if all_party_slots[player_index].stored_chestplate != null:
					all_held_equipment.append(all_party_slots[player_index].stored_chestplate)
					ret_equipment = all_party_slots[player_index].stored_chestplate
				all_held_equipment.erase(equip_)
				all_party_slots[player_index].stored_chestplate = equip
			# Boots
			2:
				if all_party_slots[player_index].stored_boots != null:
					all_held_equipment.append(all_party_slots[player_index].stored_boots)
					ret_equipment = all_party_slots[player_index].stored_boots
				all_held_equipment.erase(equip_)
				all_party_slots[player_index].stored_boots = equip.duplicate()
			# Charm
			3:
				if all_party_slots[player_index].stored_charm != null:
					all_held_equipment.append(all_party_slots[player_index].stored_charm)
					ret_equipment = all_party_slots[player_index].stored_charm
				all_held_equipment.erase(equip_)
				all_party_slots[player_index].stored_charm = equip
	return ret_equipment
	
func _ready():
	active_party_slots.append(load("res://assets/characters/player/MC_Combatant_Information.tres"))
	active_party_slots.append(load("res://assets/characters/rowan/Rowan_Combatant_Information.tres"))
	active_party_slots.append(load("res://assets/characters/lyra/Lyra_Combatant_Information.tres"))
	
	all_party_slots.append(load("res://assets/characters/player/MC_Combatant_Information.tres"))
	all_party_slots.append(load("res://assets/characters/rowan/Rowan_Combatant_Information.tres"))
	all_party_slots.append(load("res://assets/characters/lyra/Lyra_Combatant_Information.tres"))

	dungeon_types.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Creepy_Dungeon.tres"))
	dungeon_types.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Forest_Dungeon.tres"))

	active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Gather Slime.tres"))
	active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Kill_Eyes.tres"))
	active_quests.append(load("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"))
	
	all_held_weapons.append(load("res://assets/Equipment/Training_Sword.tres"))
	all_held_weapons.append(load("res://assets/Equipment/Training_Dagger.tres"))

	all_held_equipment.append(load("res://assets/Equipment/Gold_Bracelet.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Ruby Necklace.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Plated_Boots.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Leather_Helmet.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Leather_Boots.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Iron_Helmet.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Iron_Chestplate.tres"))
	all_held_equipment.append(load("res://assets/Equipment/Lather_Chestplate.tres"))
	
	await get_tree().create_timer(0.5).timeout

	finished.emit()

var explorable_dungeon_scene# : explorable_dungeon
var dungeon_loop_scene #: dungeon_loop

var selected_dungeon_

func transition_to_dungeon(selected_dungeon):
	selected_dungeon_ = selected_dungeon
	current_dungeon = dungeon_types[selected_dungeon_]
	var dungeon_scene = await Fade.change_scene("res://scenes/Dungeon/Explorable_Dungeon_Test/Dungeon_Test.tscn")

	explorable_dungeon_scene = dungeon_scene
	
	var temp2 = load("res://assets/Resources/Dungeon Stuff/Dungeon_25D.tscn")
	dungeon_loop_scene = temp2.instantiate()

	for party_member in active_party_slots:
		max_BP += party_member.bond_level * 5
	bond_attack_fill = 2 * max_BP
	current_BP = max_BP
	await dungeon_scene._setup(dungeon_types[selected_dungeon])
		
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

var current_dungeon

func initiate_combat(encounter, node_id, is_boss: bool = false):
	if is_combat_active:
		return
	is_combat_active = true
	previous_enemy_encountered = node_id
	await Fade.fade_in(0.5)
	get_tree().root.call_deferred("remove_child", explorable_dungeon_scene)
	get_tree().root.call_deferred("add_child", dungeon_loop_scene)
	
	await get_tree().process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var output = await dungeon_loop_scene.setup(dungeon_types[selected_dungeon_], encounter, is_boss)
	var enemies_killed = output[0]
	var did_players_win = output[1]
	print("YOU KJILLED ", enemies_killed)
	# output[2] = [party_slot_1, party_slot_2, party_slot_3, current_bond_points, gui.bond_bar.value]
	
	active_party_slots[0] = output[2][0].duplicate()
	active_party_slots[1] = output[2][1].duplicate()
	active_party_slots[2] = output[2][2].duplicate()
	
	current_BP = output[2][3]
	cur_bond_attack_val = output[2][4]

	if did_players_win:
		should_remove_enemy = true
	else:
		print("Y'all dummies lost")
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
		var is_quest_target = enemies_to_check.any(func(e): return e.combatant_name == enemy.combatant_name)
		print("ARE YOU A QUEST TARGET ", is_quest_target )
		if is_quest_target:
			var chance = rng.randf()
			if chance < 1.0:
				var drop_num = rng.randi_range(1, 3)
				for i in range(drop_num):
					quest_items_gained.append(enemy.quest_item_drop.duplicate())
				
		coins_gained += int(randi_range(enemy.coin_drop_range.x, enemy.coin_drop_range.y) * randf_range(0.5, 1.5))
		experience_gained += clamp(int(pow(enemy.combatant_stats.level, enemy.experience_mult + 1) * randf_range(0.5, 1.2)), 1, enemy.experience_mult + 1 * 1.2)
		var returned_items = return_dropped_items(enemy.drop_table)
		if returned_items != null:
			stuff_gained.append(returned_items)
		bond_gained += int(randi_range(enemy.bond_drop_range.x, enemy.bond_drop_range.y) * randf_range(0.5, 1.2))
	
	for player: generic_combatants in active_party_slots:
		player.add_experience(int(float(experience_gained) / (active_party_slots.size() - 1)))
	currency_held += coins_gained
	check_quest_progress.emit()

	if stuff_gained == null and quest_items_gained != null: 
		stuff_gained = quest_items_gained
	elif stuff_gained != null and quest_items_gained != null:
		stuff_gained += quest_items_gained

	if is_boss:
		get_tree().quit()

	if stuff_gained != null:
		add_item(stuff_gained)

	await Fade.fade_in(1)
	get_tree().root.remove_child(dungeon_loop_scene)
	var temp_rewards = load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Dungeon_Reward_Screen.tscn")
	var rewards_scene = temp_rewards.instantiate()
	get_tree().root.add_child(rewards_scene)
	
	rewards_scene._setup(coins_gained, experience_gained, bond_gained, stuff_gained)
	rewards_scene_ = rewards_scene
	
var rewards_scene_
func bring_back_combat(_rewards_scene):
	get_tree().root.add_child(explorable_dungeon_scene)
	explorable_dungeon_scene.movement_locked = false
	if is_instance_valid(rewards_scene_):
		rewards_scene_.queue_free()
	
	if should_remove_enemy:
		var enemy_to_remove = instance_from_id(previous_enemy_encountered)
		explorable_dungeon_scene.enemy_container.remove_child(enemy_to_remove)
		enemy_to_remove.queue_free()
		#explorable_dungeon_scene.enemy_container.remove_child(previous_enemy_encountered)
	
	is_combat_active = false
	explorable_dungeon_scene.return_to_exploring()


func update_stored_combat_information():
	pass

func load_saved_data(data):
	for party_member in data["player_slots"]:
		var new_party_member: generic_combatants = load(party_member["path"])
		new_party_member.load_save(party_member)
		all_party_slots.append(new_party_member)
		
	for equipment_ in data["equipment_slots"]:
		all_held_equipment.append(load(equipment_["path"]))
		
	for weapon_ in data["weapon_slots"]:
		all_held_weapons.append(load(weapon_["path"]))
		
	for item_ in data["item_slots"]:
		all_held_items.append(load(item_["path"]))
		
	for a_quest in data["active_quests"]:
		active_quests.append(load(a_quest["path"]))
		
	for com_quest in data["com_quests"]:
		completed_quests.append(load(com_quest["path"]))
		
	for d_type in data["dungeon_types"]:
		var new_d_type: dungeon_type = load(d_type["path"])
		new_d_type.load_save_data(d_type)
		dungeon_types.append(new_d_type)
		
	currency_held = data["held_currency"]

func export_to_JSON():
	var ret_dict: Dictionary = {}
	var player_slots: Dictionary = {}
	var equipment_slots: Dictionary = {}
	var weapon_slots: Dictionary = {}
	var item_slots: Dictionary = {}
	var active_quest_slots: Dictionary = {}
	var completed_quest_list: Dictionary = {}
	var d_types: Dictionary = {}
	
	for party_member in range(all_party_slots.size()):
		var new_key = "slot_" + str(party_member)
		all_party_slots[party_member].current_stored_slot = party_member
		player_slots[new_key] = all_party_slots[party_member].export_to_JSON()

	for equipment_ in range(all_held_equipment.size()):
		var new_key = "slot_" + str(equipment_)
		equipment_slots[new_key] = all_held_equipment[equipment_].export_to_JSON()
		
	for weapon_ in range(all_held_weapons.size()):
		var new_key = "slot_" + str(weapon_)
		weapon_slots[new_key] = all_held_weapons[weapon_].export_to_JSON()
		
	for item_ in range(all_held_items.size()):
		var new_key = "slot_" + str(item_)
		item_slots[new_key] = all_held_items[item_].export_to_JSON()
	
	for quest_ in range(active_quests.size()):
		var new_key = "quest_" + str(quest_)
		active_quest_slots[new_key] = active_quests[quest_]
		
	for com_quest_ in range(completed_quests.size()):
		var new_key = "quest_" + str(com_quest_)
		completed_quest_list[new_key] = completed_quests[com_quest_]
	
	for d_type in range(dungeon_types.size()):
		var new_key = "dtype_" + str(d_type)
		d_types[new_key] = dungeon_types[d_type]
	
	ret_dict["player_slots"] = player_slots
	ret_dict["equipment_slots"] = equipment_slots
	ret_dict["weapon_slots"] = weapon_slots
	ret_dict["item_slots"] = item_slots
	ret_dict["active_quests"] = active_quest_slots
	ret_dict["com_quests"] = completed_quest_list
	ret_dict["dungeon_types"] = d_types
	ret_dict["held_currency"] = currency_held
	
	return JSON.stringify(ret_dict, "\t")
