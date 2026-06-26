extends Node3D

var active_party_slots: Array[generic_combatants]
var all_party_slots: Array[generic_combatants]

var currency_held: int = 200

var all_held_equipment: Array[equipment]
var all_held_weapons: Array[weapon]
var all_held_items: Array[Items]

var dungeon_types: Array[dungeon_type] = []

var active_quests: Array[quest]
var completed_quests: Array[quest]

var current_BP: int = 0
var max_BP: int = 0

@onready var rng = RandomNumberGenerator.new()

var bond_attack_fill 
var cur_bond_attack_val = 0

enum bonds {STRANGER, ACQAINTED, WARMED, KINDRED, BOUND, TRUEBOND}

signal finished

func load_items():
	var new_item = load("res://assets/Resources/Dungeon Stuff/temp_item.tres")
	for i in range(5):
		all_held_items.append(new_item.duplicate())

func add_item(item_to_add: Items):
	all_held_items.append(item_to_add)

func _ready():
	active_party_slots.append(load("res://assets/characters/player/MC_Combatant_Information.tres"))
	active_party_slots.append(load("res://assets/characters/rowan/Rowan_Combatant_Information.tres"))
	active_party_slots.append(load("res://assets/characters/lyra/Lyra_Combatant_Information.tres"))
	
	all_party_slots.append(load("res://assets/characters/player/MC_Combatant_Information.tres"))
	all_party_slots.append(load("res://assets/characters/rowan/Rowan_Combatant_Information.tres"))
	all_party_slots.append(load("res://assets/characters/lyra/Lyra_Combatant_Information.tres"))

	dungeon_types.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Creepy_Dungeon.tres"))
	dungeon_types.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Forest_Dungeon.tres"))

	
	await get_tree().create_timer(0.5).timeout

	finished.emit()

var explorable_dungeon_scene: explorable_dungeon
var dungeon_loop_scene: dungeon_loop

var selected_dungeon_

func transition_to_dungeon(selected_dungeon):
	selected_dungeon_ = selected_dungeon
	var dungeon_scene = await Fade.change_scene("res://scenes/Dungeon/Explorable_Dungeon_Test/Dungeon_Test.tscn")

	#var temp = load("res://scenes/Dungeon/Explorable_Dungeon_Test/Dungeon_Test.tscn")
	explorable_dungeon_scene = dungeon_scene
	
	var temp2 = load("res://assets/Resources/Dungeon Stuff/Dungeon_25D.tscn")
	dungeon_loop_scene = temp2.instantiate()

	for party_member in active_party_slots:
		max_BP += party_member.bond_level * 5
	bond_attack_fill = 2 * max_BP
	#get_tree().root.add_child(explorable_dungeon_scene)
	current_BP = max_BP
	await dungeon_scene._setup(dungeon_types[selected_dungeon])

	if false:
		#await dungeon_scene.setup(active_party_slots, dungeon_types[selected_dungeon], all_held_items, selected_dungeon, max_BP)
		var enemies_killed = null #await dungeon_scene.battle_loop()
		
		var coins_gained: int = 0
		var experience_gained: int = 0
		var bond_gained: int = 0
		var stuff_gained: Array[Items]
		
		for enemy: generic_combatants in enemies_killed:
			coins_gained += int(randi_range(enemy.drop_table.coin_drop_range.x, enemy.drop_table.coin_drop_range.y) * randf_range(0.5, 1.5))
			experience_gained += int(pow(enemy.combatant_stats.level, enemy.experience_mult + 1) * randf_range(0.5, 1.2))
			bond_gained += int(randi_range(enemy.drop_table.bond_drop_range.x, enemy.drop_table.bond_drop_range.y) * randf_range(0.5, 1.2))
			for item in enemy.drop_table.item_drop_chances:
				var chance = rng.randf_range(0, 1)
				if chance > enemy.drop_table.item_drop_chances[item]:
					stuff_gained.append(item)
		
		for player: generic_combatants in active_party_slots:
			player.add_experience(int(float(experience_gained) / (active_party_slots.size() - 1)))
		currency_held += coins_gained
		var new_item = load("res://assets/Resources/Dungeon Stuff/temp_item.tres")
		stuff_gained.append(new_item.duplicate())
		
		await Fade.fade_in(1)
		var rewards_scene = await Fade.change_scene("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Dungeon_Reward_Screen.tscn")
		rewards_scene._setup(coins_gained, experience_gained, bond_gained, stuff_gained)
var is_combat_active: bool = false
var previous_enemy_encountered
var should_remove_enemy = false
func initiate_combat(encounter, node_id):
	if is_combat_active:
		return
	is_combat_active = true
	previous_enemy_encountered = node_id
	
	get_tree().root.call_deferred("remove_child", explorable_dungeon_scene)
	get_tree().root.call_deferred("add_child", dungeon_loop_scene)
	
	await get_tree().process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var output = await dungeon_loop_scene.setup(dungeon_types[selected_dungeon_], encounter)
	var enemies_killed = output[0]
	var did_players_win = output[1]
	
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
	var stuff_gained: Array[Items]
	
	for enemy: generic_combatants in enemies_killed:
		coins_gained += int(randi_range(enemy.drop_table.coin_drop_range.x, enemy.drop_table.coin_drop_range.y) * randf_range(0.5, 1.5))
		experience_gained += clamp(int(pow(enemy.combatant_stats.level, enemy.experience_mult + 1) * randf_range(0.5, 1.2)), 1, enemy.experience_mult + 1 * 1.2)
		bond_gained += int(randi_range(enemy.drop_table.bond_drop_range.x, enemy.drop_table.bond_drop_range.y) * randf_range(0.5, 1.2))
		for item in enemy.drop_table.item_drop_chances:
			var chance = rng.randf_range(0, 1)
			if chance > enemy.drop_table.item_drop_chances[item]:
				stuff_gained.append(item)
	
	for player: generic_combatants in active_party_slots:
		player.add_experience(int(float(experience_gained) / (active_party_slots.size() - 1)))
	currency_held += coins_gained
	var new_item = load("res://assets/Resources/Dungeon Stuff/temp_item.tres")
	stuff_gained.append(new_item.duplicate())
	
	await Fade.fade_in(1)
	get_tree().root.remove_child(dungeon_loop_scene)
	var temp_rewards = load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Dungeon_Reward_Screen.tscn")
	var rewards_scene = temp_rewards.instantiate()
	get_tree().root.add_child(rewards_scene)
	
	rewards_scene._setup(coins_gained, experience_gained, bond_gained, stuff_gained)
	rewards_scene_ = rewards_scene
	
var rewards_scene_
func bring_back_combat(rewards_scene):
	get_tree().root.add_child(explorable_dungeon_scene)
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
