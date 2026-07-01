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

@onready var rng = RandomNumberGenerator.new()

enum bonds {STRANGER, ACQAINTED, WARMED, KINDRED, BOUND, TRUEBOND}

signal finished

func load_items():
	var new_item = load("res://assets/Resources/Dungeon Stuff/temp_item.tres")
	for i in range(5):
		all_held_items.append(new_item.duplicate())

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

	print(export_to_JSON())

	finished.emit()

func transition_to_dungeon(selected_dungeon):
	currency_held = Global.money
	var dungeon_scene = await Fade.change_scene("res://assets/Resources/Dungeon Stuff/Dungeon_25D.tscn")

	var max_BP = 5
	for party_member in active_party_slots:
		max_BP += party_member.bond_level * 5

	await dungeon_scene.setup(active_party_slots, dungeon_types[selected_dungeon], all_held_items, selected_dungeon, max_BP)
	var enemies_killed = await dungeon_scene.battle_loop()
	
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

func load_saved_data(data):
	# #2: wipe the _ready() seed data so we restore instead of stacking on top of it
	all_party_slots.clear()
	active_party_slots.clear()
	all_held_equipment.clear()
	all_held_weapons.clear()
	all_held_items.clear()
	active_quests.clear()
	completed_quests.clear()
	dungeon_types.clear()

	# BUG: these are Dictionaries keyed "slot_0"…, so iterate .values(), not the dict itself
	for party_member in data["player_slots"].values():
		var new_party_member: generic_combatants = load(party_member["path"])
		new_party_member.load_save(party_member)
		all_party_slots.append(new_party_member)

	for equipment_ in data["equipment_slots"].values():
		all_held_equipment.append(load(equipment_["path"]))

	for weapon_ in data["weapon_slots"].values():
		all_held_weapons.append(load(weapon_["path"]))

	for item_ in data["item_slots"].values():
		all_held_items.append(load(item_["path"]))

	for a_quest in data["active_quests"].values():
		active_quests.append(load(a_quest["path"]))

	for com_quest in data["com_quests"].values():
		completed_quests.append(load(com_quest["path"]))

	for d_type in data["dungeon_types"].values():
		var new_d_type: dungeon_type = load(d_type["path"])
		new_d_type.load_save_data(d_type)
		dungeon_types.append(new_d_type)

	currency_held = int(data["held_currency"])   # JSON numbers can come back as float

	# #4: rebuild active fighters as references into the freshly loaded all_party_slots
	if data.has("active_slots"):
		for idx in data["active_slots"]:
			var i = int(idx)
			if i >= 0 and i < all_party_slots.size():
				active_party_slots.append(all_party_slots[i])
				
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
		equipment_slots["slot_" + str(equipment_)] = all_held_equipment[equipment_].export_to_JSON()

	for weapon_ in range(all_held_weapons.size()):
		weapon_slots["slot_" + str(weapon_)] = all_held_weapons[weapon_].export_to_JSON()

	for item_ in range(all_held_items.size()):
		item_slots["slot_" + str(item_)] = all_held_items[item_].export_to_JSON()

	# #3: quests are Resources — JSON can't serialize them. Store a path dict.
	for quest_ in range(active_quests.size()):
		active_quest_slots["quest_" + str(quest_)] = {"path": active_quests[quest_].resource_path}

	for com_quest_ in range(completed_quests.size()):
		completed_quest_list["quest_" + str(com_quest_)] = {"path": completed_quests[com_quest_].resource_path}

	# #3: dungeon_types carry state, so use their own serializer (must include "path")
	for d_type in range(dungeon_types.size()):
		d_types["dtype_" + str(d_type)] = dungeon_types[d_type].export_to_JSON()

	# #4: record which all_party_slots indices are the active fighters
	var active_indices: Array = []
	for member in active_party_slots:
		active_indices.append(all_party_slots.find(member))

	ret_dict["player_slots"] = player_slots
	ret_dict["active_slots"] = active_indices
	ret_dict["equipment_slots"] = equipment_slots
	ret_dict["weapon_slots"] = weapon_slots
	ret_dict["item_slots"] = item_slots
	ret_dict["active_quests"] = active_quest_slots
	ret_dict["com_quests"] = completed_quest_list
	ret_dict["dungeon_types"] = d_types
	ret_dict["held_currency"] = currency_held

	return ret_dict   # #1: raw dict — the save menu stringifies the whole payload once
