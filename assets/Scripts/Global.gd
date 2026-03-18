extends Node2D

const SAVE_PATH = "user://save_game.dat"

var spawn_location

var current_weather : weather = weather.Normal

var temp_canvas_layer: CanvasLayer
var mouse_texture: TextureRect

var running_time: float
var play_time_seconds: int
var play_time_minutes: int
var play_time_hours: int

var active_quest_list: Array[quest]

var player_saves : Array[String]

var entire_party : Array[PartyMember]

var money : int

var village_inventory: Array[inventory_items]

@onready var party_slot_1 : PartyMember = load("res://assets/Party Members/Dwarf.tres")
@onready var party_slot_2 : PartyMember = load("res://assets/Party Members/Mage.tres")
@onready var party_slot_3 : PartyMember = load("res://assets/Party Members/Paladin.tres")

@onready var party_list = [party_slot_1, party_slot_2, party_slot_3]

var current_location: String = "[Forest Dungeon: Floor 1]"
var previous_coordinates : Vector2

var item_list : Array[Items]
var equipment_list : Array[equipment]
var weapon_list : Array[weapon]

var current_encounter : encounters

var is_in_menu: bool = false

signal item_list_updated(index, item)
signal equipment_list_updated(index, equipment_)
signal weapon_list_updated(index, weapon_)
signal save_loaded

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

enum locations {
	Potion_Shop,
	Weapon_Shop,
	Library,
	Infirmary,
	Infirmay2,
	Infirmary3,
}

enum weather {
	Normal,
	Sunny,
	Rainy,
	Windy,
	Snowy,
}

var progression_state = {
	"SEAL_1": true,
	"SEAL_2": false,
	"SEAL_3": false,
	"SEAL_4": false,
	"SEAL_5": false,
	"SEAL_6": false,
	"SEAL_7": false,
	"QUEST_1": false,
	"QUEST_2": false,
	"QUEST_3": true,
	"QUEST_4": false,
	"QUEST_5": false
}

func can_take_quest(quest_: quest):
	if quest_.unlock_seal_requirement.size() == 0:
		return true
		
	for index in quest_.unlock_seal_requirement:
		if progression_state[index] == false:
			return false
	return true

func _physics_process(delta):
	mouse_texture.global_position = mouse_texture.get_viewport().get_mouse_position()

	running_time += delta
	if floor(running_time) == 1:
		update_time()
		running_time = 0

# This variable could be replaced with a check based on seconds in the day
var am_or_pm: bool
var current_day: int
var current_year: int
var current_hour: int = 6
var current_minute: int
var time_since_last_update: float
var seconds_since_day_started: float

var time_scale: int = 60

signal time_updated

func update_time():
	play_time_seconds += 1
	seconds_since_day_started += 1
	
	if (seconds_since_day_started * time_scale) - time_since_last_update >= 300:
		time_updated.emit()
		current_minute += 5
		if current_minute >= 60:
			current_minute -= 60
			current_hour += 1
			if current_hour % 12 == 1:
				am_or_pm = true
			elif am_or_pm and current_hour % 12 == 0:
				Global.player_advanced_day(true)
				am_or_pm = false
		time_since_last_update = (seconds_since_day_started * time_scale)
	if play_time_seconds == 60:
		play_time_minutes += 1
		play_time_seconds = 0
		time_since_last_update = 0
	if play_time_minutes == 60:
		play_time_hours += 1
		play_time_minutes = 0

func player_advanced_day(did_they_pass_out):
	current_day += 1
	
	if current_day == 366:
		current_year += 1
		current_day = 0
	
	current_hour = 6
	current_minute = 0
	
	time_since_last_update = 0
	seconds_since_day_started = 0
	
	time_updated.emit()
	
	if did_they_pass_out:
		spawn_location = null

func load_save():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return ""

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		return content
	return ""

func load_save_data():
	var json_string = load_save()
	if json_string == "":
		return
		
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		var data = json.data
		
		money = data["money"]
		current_location = data["current_location"]
		
		previous_coordinates = Vector2(data["previous_coordinates"]["x"], data["previous_coordinates"]["y"])
		
		party_slot_1 = load(data["party_slots"][0]["path"])
		party_slot_2 = load(data["party_slots"][1]["path"])
		party_slot_3 = load(data["party_slots"][2]["path"])
				
		party_slot_1.load_save_data(data["party_slots"][0])
		party_slot_2.load_save_data(data["party_slots"][1])
		party_slot_3.load_save_data(data["party_slots"][2])
		
		item_list.clear()
		for path in data["item_list"]:
			item_list.append(load(path))
		
		for path in data["equipment_list"]:
			equipment_list.append(load(path))
		for path in data["weapon_list"]:
			weapon_list.append(load(path))
		
		progression_state.clear()
		for key in data["progression_state"]:
			progression_state[int(key)] = data["progression_state"][key]
		save_loaded.emit()
	else:
		print("Parse Error: ", json.get_error_message())
	
func get_save_data() -> Dictionary:
	var save_dict = {
		"money": money,
		"entire_party": _get_path_array(entire_party),
		"current_location": current_location, 
		"previous_coordinates": {
			"x": previous_coordinates.x,
			"y": previous_coordinates.y
		},
		"progression_state": progression_state,
		
		"party_slots": [
			party_slot_1.get_save_stats(),
			party_slot_2.get_save_stats(),
			party_slot_3.get_save_stats()
		],
		
		"item_list": _get_path_array(item_list),
		"equipment_list": _get_path_array(equipment_list),
		"weapon_list": _get_path_array(weapon_list),
	}
	return save_dict

func _get_path_array(arr: Array) -> Array[String]:
	var paths: Array[String] = []
	for item in arr:
		if item:
			paths.append(item.resource_path)
	return paths

func save_state_to_slot():
	var data = get_save_data()
	var json_string = JSON.stringify(data, "\t")
	create_save(json_string)

func create_save(content):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(content)
	else:
		print("Error: Could not open file for writing: ", FileAccess.get_open_error())

func add_armor(armor: equipment):
	equipment_list.append(armor)
	equipment_list_updated.emit(-1, armor)

func remove_armor(armor_index):
	equipment_list.remove_at(armor_index)
	equipment_list_updated.emit(armor_index, null)

func add_weapon(added_weapon: weapon):
	weapon_list.append(added_weapon)
	weapon_list_updated.emit(-1, added_weapon)

func remove_weapon(weapon_index):
	weapon_list.remove_at(weapon_index)
	weapon_list_updated.emit(weapon_index, null)

func add_item(item: Items):
	item_list.append(item)
	item_list_updated.emit(-1, item)

func remove_item(item_index):
	item_list.remove_at(item_index)
	item_list_updated.emit(item_index, null)

func _ready():
	village_inventory.resize(40)
	var temp = load("D:/sealbound/assets/Resources/Interactables/VillageInventory/temp.tres")
	var temp2 = load("D:/sealbound/assets/Resources/Interactables/VillageInventory/temp_2.tres")
	for i in range(40):
		if i % 2 == 0:
			village_inventory[i] = temp.duplicate(true)
		else:
			village_inventory[i] = temp2.duplicate(true)

	temp_canvas_layer = CanvasLayer.new()
	add_child(temp_canvas_layer)
	mouse_texture = TextureRect.new()
	
	temp_canvas_layer.add_child(mouse_texture)
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
