extends Node

var active_party_slots: Array[generic_combatants]
var all_party_slots: Array[generic_combatants]

var currency_held: int = 200

signal finished

func _ready():
	print("HKKHJK")
	active_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_1.tres"))
	active_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_2.tres"))
	active_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_3.tres"))
	
	all_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_1.tres"))
	all_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_2.tres"))
	all_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_3.tres"))
	print(active_party_slots.size())
	await get_tree().create_timer(0.5).timeout

	finished.emit()
