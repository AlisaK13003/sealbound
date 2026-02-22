extends Node

var entire_party : Array[PartyMember]

var money : int

@onready var party_slot_1 : PartyMember = load("res://assets/Party Members/Dwarf.tres")
@onready var party_slot_2 : PartyMember = load("res://assets/Party Members/Dwarf.tres")
@onready var party_slot_3 : PartyMember = load("res://assets/Party Members/Dwarf.tres")

var current_location: String = "[Forest Dungeon: Floor 1]"
var previous_coordinates : Vector2

var item_list : Array[Items]
var equipment_list : Array[equipment]
var weapon_list : Array[weapon]

var current_encounter : encounters

signal item_list_updated(index, item)

enum Progression_Flags {
	SEAL_1,
	SEAL_2,
	SEAL_3,
	SEAL_4,
	SEAL_5,
	SEAL_6,
	SEAL_7,
	QUEST_1,
	QUEST_2,
	QUEST_3,
	QUEST_4,
	QUEST_5
}

var progression_state = {}

func add_item(item: Items):
	item_list.append(item)
	item_list_updated.emit(-1, item)

func remove_item(item_index):
	item_list.remove_at(item_index)
	item_list_updated.emit(item_index, null)

func _ready():
	for flag in Progression_Flags.values():
		progression_state[flag] = false

func unlock(flag: Progression_Flags) -> bool:
	return progression_state.get(flag, false)

func is_unlocked(flag: Progression_Flags) -> bool:
	return progression_state.get(flag, false)		

func has_all_requirements(req_list: Array[Progression_Flags]) -> bool:
	if req_list.is_empty():
		return true
	for flag in req_list:
		if not is_unlocked(flag):
			return false
	return true
