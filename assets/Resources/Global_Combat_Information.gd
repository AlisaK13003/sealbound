extends Node3D

var active_party_slots: Array[generic_combatants]
var all_party_slots: Array[generic_combatants]

var currency_held: int = 200

var all_held_equipment: Array[equipment]
var all_held_weapons: Array[weapon]
var all_held_items: Array[Items]

signal finished

func _ready():
	active_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_1.tres"))
	active_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_2.tres"))
	active_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_3.tres"))
	
	all_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_1.tres"))
	all_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_2.tres"))
	all_party_slots.append(load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/temp_party_3.tres"))

	await get_tree().create_timer(0.5).timeout

	finished.emit()

func transition_to_dungeon(active_combatants, current_dungeon_type, current_item_list):
	var dungeon_scene = await Fade.change_scene("res://assets/Resources/Dungeon Stuff/Dungeon_25D.tscn")
	dungeon_scene.setup(active_combatants, current_dungeon_type, current_item_list)
	
