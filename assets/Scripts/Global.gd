extends Node2D

# When these gain more functionality they will be added to their own areas
# --------------------------------------------------------------------------------------------------

var spawn_location

var current_weather : weather = weather.Normal

var entire_party : Array[PartyMember]

var money : int

var current_location: String = "Village"
var previous_coordinates : Vector2
var saved_position: Vector2 = Vector2.ZERO
var loading_from_save: bool = false

var current_encounter : encounters

var is_in_menu: bool = false

var planted_crops: Array[crops]

var player_head_sprite: Texture2D
var holding_item: inventory_items
var item_is_in_slot: int

const BOND_TIER_NAMES: Array[String] = [
	"Stranger",
	"Acquainted",
	"Warmed",
	"Kindred",
	"Bound",
	"True Bond"
]
const BOND_TIER_SIZE: int = 15
const DAILY_TALK_BOND_EXP: int = 5

var npc_bonds: Dictionary = {}

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

var current_loading_zone: String = ""
var current_region: String = ""

var location_paths = {
	"Village": "res://scenes/main/Hearthwynn.tscn",
	"Forest": "res://scenes/main/Forest.tscn",
	"Cliff Side": "res://scenes/main/Cliff Siude.tscn",
	"Buildings_Insides": "res://scenes/main/Building Insides.tscn"
}

enum dungeon_location {
	Dungeon1_1F,
	Dungeon1_2F,
	Dungeon1_3F,
	Dungeon1_4F,
}

var dungeon : Array[String]= ["Dungeon1_1F", "Dungeon1_2F", "Dungeon1_3F", "Dungeon1_4F"]

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

# Time related stuff
# --------------------------------------------------------------------------------------------------

var running_time: float
var play_time_seconds: int
var play_time_minutes: int
var play_time_hours: int

# This variable could be replaced with a check based on seconds in the day
var am_or_pm: bool
var current_day: int = 0
var current_year: int = 0
var current_hour: int = 6
var current_minute: int
var time_since_last_update: float
var seconds_since_day_started: float

var time_scale: int = 60

signal time_updated

# Updates the current time
func _physics_process(delta):
	mouse_texture.global_position = mouse_texture.get_viewport().get_mouse_position()
	
	if AreaStateManager.currently_transitioning:
		return
	
	running_time += delta
	if floor(running_time) == 1:
		update_time()
		running_time = 0

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
				player_advanced_day(true)
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

func debug_skip_day() -> void:
	player_advanced_day(false)
	print("[Debug] Skipped to day ", current_day, ", year ", current_year)

func debug_advance_time(minutes: int = 5) -> void:
	current_minute += minutes
	while current_minute >= 60:
		current_minute -= 60
		current_hour += 1
		if current_hour % 12 == 1:
			am_or_pm = true
		elif am_or_pm and current_hour % 12 == 0:
			player_advanced_day(true)
			am_or_pm = false
			return
	time_updated.emit()
	print("[Debug] Advanced time to day ", current_day, " ", current_hour, ":", "%02d" % current_minute)

func ensure_npc_bond(npc_id: String) -> Dictionary:
	if not npc_bonds.has(npc_id):
		npc_bonds[npc_id] = {
			"exp": 0,
			"last_talk_day": -1
		}
	return npc_bonds[npc_id]

func get_bond_tier_index(bond_exp: int) -> int:
	if bond_exp <= BOND_TIER_SIZE:
		return 0
	return clampi(int((bond_exp - 1) / BOND_TIER_SIZE), 0, BOND_TIER_NAMES.size() - 1)

func get_npc_bond_info(npc_id: String) -> Dictionary:
	var bond_data = ensure_npc_bond(npc_id)
	var bond_exp: int = int(bond_data.get("exp", 0))
	var tier_index: int = get_bond_tier_index(bond_exp)
	return {
		"exp": bond_exp,
		"tier_index": tier_index,
		"tier_name": BOND_TIER_NAMES[tier_index],
		"last_talk_day": int(bond_data.get("last_talk_day", -1))
	}

func add_npc_bond_exp(npc_id: String, amount: int, reason: String = "") -> Dictionary:
	var bond_data = ensure_npc_bond(npc_id)
	var old_exp: int = int(bond_data.get("exp", 0))
	var new_exp: int = max(0, old_exp + amount)
	bond_data["exp"] = new_exp
	var info = get_npc_bond_info(npc_id)
	print("[Bond] ", npc_id, " ", reason, " ", amount, " exp: ", old_exp, " -> ", new_exp, " tier: ", info["tier_name"])
	return info

func add_daily_talk_bond(npc_id: String) -> Dictionary:
	var bond_data = ensure_npc_bond(npc_id)
	if int(bond_data.get("last_talk_day", -1)) == current_day:
		var info = get_npc_bond_info(npc_id)
		print("[Bond] ", npc_id, " daily talk already claimed on day ", current_day, " exp: ", info["exp"], " tier: ", info["tier_name"])
		return info

	bond_data["last_talk_day"] = current_day
	return add_npc_bond_exp(npc_id, DAILY_TALK_BOND_EXP, "daily talk")

var controller_mapping: Dictionary = {
	"up": "Controller_Up",
	"down": "Controller_Down",
	"left": "Controller_Left",
	"right": "Controller_Right",
	"ui_right": "Controller_Dungeon_Targeting",
	"Dungeon_Attack": "Controller_Dungeon_Attack",
	"Dungeon_Skill": "Controller_Dungeon_Skill",
	"Dungeon_Defend": "Controller_Dungeon_Defend",
	"Dungeon_Items": "Controller_Dungeon_Items",
	"Cancel": "Controller_Cancel",
	"Confirm": "Controller_Confirm",
	"Quest_Menu": "Controller_Quest_Menu",
	"Open_Map": "Controller_Open_Map",
	"Camera_Zoom_In": "Controller_Right_Stick_Up",
	"Camera_Zoom_Out": "Controller_Right_Stick_Down"
}

var keyboard_mouse_icon_mapping: Dictionary = {
	"up": 88,
	"down": 89,
	"left": 90,
	"right": 91,
	"ui_right": 91,
	"Dungeon_Attack": 87,
	"Dungeon_Skill": 25,
	"Dungeon_Defend": 22,
	"Dungeon_Items": 8,
	"Cancel": 22,
	"Confirm": 2,
	"Quest_Menu": 16,
	"Open_Map": 12,
	"Camera_Zoom_In": 4,
	"Camera_Zoom_Out": 16,
}

var controller_icon_mapping: Dictionary = {
	"Controller_Up": 12,
	"Controller_Down": 13,
	"Controller_Left": 14,
	"Controller_Right": 15,
	"Controller_Dungeon_Attack": 2,
	"Controller_Dungeon_Skill": 3,
	"Controller_Dungeon_Defend": 1,
	"Controller_Dungeon_Items": 0,
	"Controller_Dungeon_Targeting": 34,
	"Controller_Cancel": 1,
	"Controller_Confirm": 2,
	"Controller_Quest_Menu": 0,
	"Controller_Open_Map": 41,
	"Controller_Right_Stick_Up": 27,
	"Controller_Right_Stick_Down": 27,
	"Controller_Right_Stick_Left": 0,
	"Controller_Right_Stick_Right": 0,
}

var using_controller: bool = false
const CONTROLLER_DEADZONE = 0.2
signal swapped_to_controller

const MOUSE_DEADZONE: float = 2.0 

func _input(event):
	if event.is_action_pressed("debug_advance_time"):
		if event is InputEventKey and event.echo:
			return
		if is_in_menu:
			get_viewport().set_input_as_handled()
			return
		debug_advance_time(5)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("test"):
		if event is InputEventKey and event.echo:
			return
		if is_in_menu:
			get_viewport().set_input_as_handled()
			return
		debug_skip_day()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventJoypadButton:
		set_using_controller(true)
		swapped_to_controller.emit(true)
		
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > CONTROLLER_DEADZONE:
			set_using_controller(true)
			swapped_to_controller.emit(true)
			
	elif event is InputEventMouseMotion:
		if event.relative.length() > MOUSE_DEADZONE:
			set_using_controller(false)
			swapped_to_controller.emit(false)
			
	elif event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			set_using_controller(false)
			swapped_to_controller.emit(false)
		
func set_using_controller(do_it):
	if do_it:
		using_controller = true
	else:
		using_controller = false
	swapped_to_controller.emit(do_it)

func get_input_mapping(input_string):
	if using_controller:
		return Input.is_action_just_pressed(controller_mapping[input_string])
	else:
		return Input.is_action_just_pressed(input_string)

func get_continuous_input_mapping(input_string):
	if using_controller:
		return Input.is_action_pressed(controller_mapping[input_string])
	else:
		return Input.is_action_pressed(input_string)

# Save data manager
# --------------------------------------------------------------------------------------------------

const SAVE_PATH = "user://save_game.dat"
var player_saves : Array[String]
signal save_loaded

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
		
		previous_coordinates = Vector2(data["previous_coordinates"]["x"], data["previous_coordinates"]["y"])
		
		item_list.clear()
		for path in data["item_list"]:
			item_list.append(load(path))
		equipment_list.clear()
		for path in data["equipment_list"]:
			equipment_list.append(load(path))
		weapon_list.clear()
		for path in data["weapon_list"]:
			weapon_list.append(load(path))
		
		npc_bonds = data.get("npc_bonds", {})
		
		progression_state.clear()
		for key in data["progression_state"]:
			progression_state[int(key)] = data["progression_state"][key]
		save_loaded.emit()
		time_updated.emit()
	else:
		print("Parse Error: ", json.get_error_message())

func get_save_data() -> Dictionary:
	var player_node = get_tree().get_first_node_in_group("Overworld_Player")
	var player_position = saved_position
	if player_node:
		player_position = player_node.global_position

	var save_region = current_region
	if not location_paths.has(save_region):
		save_region = current_location

	var save_dict = {
		"money": money,
		"current_location": save_region,
		"current_loading_zone": current_loading_zone,
		"current_region": save_region,
		"player_position": {
			"x": player_position.x,
			"y": player_position.y
		},
		"entire_party": _get_path_array(entire_party),
		"previous_coordinates": {
			"x": previous_coordinates.x,
			"y": previous_coordinates.y
		},
		"progression_state": progression_state,

		"item_list": _get_path_array(item_list),
		"equipment_list": _get_path_array(equipment_list),
		"weapon_list": _get_path_array(weapon_list),
		"npc_bonds": npc_bonds,
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

# Getters and Setters for inventory
# --------------------------------------------------------------------------------------------------

enum item_stack_limit {
	Potion = 1,
	Crop = 8, 
	Food = 8,
	Weapons = 1
}

var village_inventory: Array[inventory_items]

var item_list : Array[Items]
var equipment_list : Array[equipment]
var weapon_list : Array[weapon]

signal item_list_updated(index, item)
signal equipment_list_updated(index, equipment_)
signal weapon_list_updated(index, weapon_)
signal inventory_updated(slot_that_was_updated)
signal purse_updated

func spent_or_obtained_money(amount):
	money = money + amount
	purse_updated.emit()

func added_to_inventory(added_thing: inventory_items, where_was_it_added):
	var temp = 0
	var amount_that_can_be_added = added_thing.stack_amount
	
	if village_inventory[where_was_it_added] != null and village_inventory[where_was_it_added].amount_held >= amount_that_can_be_added and village_inventory[where_was_it_added].item_resource_path != added_thing.item_resource_path:
		return added_thing
	for i in range(added_thing.amount_held):
		if added_thing.amount_held == 0:
			village_inventory[where_was_it_added].amount_held = temp
			inventory_updated.emit(where_was_it_added)
			return null
		if village_inventory[where_was_it_added] != null and village_inventory[where_was_it_added].item_resource_path == added_thing.item_resource_path:
			if village_inventory[where_was_it_added].amount_held + 1 <= amount_that_can_be_added:
				village_inventory[where_was_it_added].amount_held += 1
				added_thing.amount_held -=1
				inventory_updated.emit(where_was_it_added)
			else:
				village_inventory[where_was_it_added] = added_thing.duplicate()
				village_inventory[where_was_it_added].amount_held = amount_that_can_be_added
				inventory_updated.emit(where_was_it_added)
				return added_thing
		elif village_inventory[where_was_it_added] == null:
			village_inventory[where_was_it_added] = added_thing.duplicate()
			if village_inventory[where_was_it_added].amount_held > amount_that_can_be_added:
				village_inventory[where_was_it_added].amount_held = amount_that_can_be_added
				added_thing.amount_held -= amount_that_can_be_added
				inventory_updated.emit(where_was_it_added)
				return added_thing
			break
		else:
			return added_thing
	inventory_updated.emit(where_was_it_added)

func added_just_one_item(added_thing: inventory_items, where_was_it_added):
	if village_inventory[where_was_it_added] != null and village_inventory[where_was_it_added].amount_held >= added_thing.stack_amount:
		return added_thing
	
	if village_inventory[where_was_it_added] == null:
		village_inventory[where_was_it_added] = added_thing
		village_inventory[where_was_it_added].amount_held = 1
		inventory_updated.emit(where_was_it_added)
		return null
	village_inventory[where_was_it_added].amount_held += 1
	inventory_updated.emit(where_was_it_added)

func add_to_first_open_slot(added_thing: inventory_items):
	for slot in range(village_inventory.size()):
		if added_to_inventory(added_thing, slot) == null:
			return true
		elif added_thing.amount_held == 0:
			return true	
	print("SENT TO STORAGE")
	return false

func remove_from_inventory(removed_at):
	if village_inventory[removed_at] != null:
		holding_item = null
		player_head_sprite = null
	village_inventory[removed_at] = null
	inventory_updated.emit(removed_at)

func remove_from_inventory_n_times(removed_at, amount_removed):
	village_inventory[removed_at].amount_held -= amount_removed
	if village_inventory[removed_at].amount_held == 0:
		village_inventory[removed_at] = null
	inventory_updated.emit(removed_at)

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

# --------------------------------------------------------------------------------------------------
var temp_canvas_layer: CanvasLayer
var mouse_texture: TextureRect

func _ready():
	# Temporarily populates the inventory
	village_inventory.resize(40)
	var temp = load("res://assets/Resources/Interactables/VillageInventory/temp.tres")
	# var temp2 = load("D:/sealbound/assets/Resources/Interactables/VillageInventory/temp_2.tres")
	# var temp3 = load("res://assets/Resources/Interactables/VillageInventory/Seed_Pack.tres")
	var temp4 = load("res://assets/Resources/Interactables/Shops/Shop Items/Milk.tres")
	for i in range(40):
		if i % 3 == 0:
			added_to_inventory(temp4.duplicate(true), i)
		elif i % 2 == 0:
			add_to_first_open_slot(temp.duplicate(true))
	temp_canvas_layer = CanvasLayer.new()
	temp_canvas_layer.layer = 100
	add_child(temp_canvas_layer)
	mouse_texture = TextureRect.new()
	# Maybe replace with this
	#     Input.set_custom_mouse_cursor(item_texture, Input.CURSOR_ARROW, Vector2(16, 16))
	mouse_texture.top_level = true
	
	temp_canvas_layer.add_child(mouse_texture)
	for flag in Progression_Flags.values():
		progression_state[flag] = false
	time_updated.emit()

	add_npc_bond_exp("lyra", 20, "YAY")

# Quest System
# --------------------------------------------------------------------------------------------------

var active_quest_list: Array[quest]

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

func can_take_quest(quest_: quest):
	if quest_.unlock_seal_requirement.size() == 0:
		return true
		
	for index in quest_.unlock_seal_requirement:
		if progression_state[index] == false:
			return false
	return true

# --------------------------------------------------------------------------------------------------
