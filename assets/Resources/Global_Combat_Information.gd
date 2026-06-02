extends Node3D

var active_party_slots: Array[generic_combatants]
var all_party_slots: Array[generic_combatants]

var currency_held: int = 200

var all_held_equipment: Array[equipment]
var all_held_weapons: Array[weapon]
var all_held_items: Array[Items]

var dungeon_types: Array[dungeon_type]

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

	await get_tree().create_timer(0.5).timeout

	finished.emit()

func transition_to_dungeon(selected_dungeon):
	var dungeon_scene = await Fade.change_scene("res://assets/Resources/Dungeon Stuff/Dungeon_25D.tscn", 2)

	await dungeon_scene.setup(active_party_slots, null, all_held_items, selected_dungeon)
	await Fade.fade_out()
	var enemies_killed = await dungeon_scene.battle_loop()
	
	print("HELLO")
	
	var coins_gained: int = 0
	var experience_gained: int = 0
	var bond_gained: int = 0
	var stuff_gained
	
	for enemy in enemies_killed:
		coins_gained += int(randi_range(enemy.drop_table.coin_drop_range.x, enemy.drop_table.coin_drop_range.y) * randf_range(0.5, 1.5))
		experience_gained += int(pow(enemy.combatant_stats.level, enemy.experience_mult + 1) * randf_range(0.5, 1.2))
		bond_gained += int(randi_range(enemy.drop_table.bond_drop_range.x, enemy.drop_table.bond_drop_range.y) * randf_range(0.5, 1.2))
	
	for player: generic_combatants in active_party_slots:
		player.add_experience(int(float(experience_gained) / (active_party_slots.size() - 1)))
	currency_held += coins_gained
	print("Gained coins: ", coins_gained)
	print("Gained Experience: ", experience_gained)
	print("Gained Bond: ", bond_gained)
