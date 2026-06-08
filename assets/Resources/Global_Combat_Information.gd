extends Node3D

var active_party_slots: Array[generic_combatants]
var all_party_slots: Array[generic_combatants]

var currency_held: int = 200

var all_held_equipment: Array[equipment]
var all_held_weapons: Array[weapon]
var all_held_items: Array[Items]

var dungeon_types: Array[dungeon_type] = []

@onready var rng = RandomNumberGenerator.new()

enum bonds {STRANGER, ACQAINTED, WARMED, KINDRED, BOUND, TRUEBOND}

signal finished

func load_items():
	var new_item = load("res://assets/Resources/Dungeon Stuff/temp_item.tres")
	for i in range(5):
		all_held_items.append(new_item.duplicate())

func _ready():
	active_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_1.tres"))
	active_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_2.tres"))
	active_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_3.tres"))
	
	all_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_1.tres"))
	all_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_2.tres"))
	all_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_3.tres"))

	dungeon_types.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Creepy_Dungeon.tres"))
	dungeon_types.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Forest_Dungeon.tres"))


	await get_tree().create_timer(0.5).timeout

	finished.emit()

func transition_to_dungeon(selected_dungeon):
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
