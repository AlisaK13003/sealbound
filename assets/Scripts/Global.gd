extends Node

# --------------------------------------------------------------------------------------------------

signal menu_opened
signal menu_closed
signal update_stock

var cant_leave_menu: bool = false

var CURRENT_SAVE_SLOT
var is_paused: bool = false

var spawn_location

var current_weather : weather = weather.Normal

var current_location: String = "Village"
var previous_coordinates : Vector2
var saved_position: Vector2 = Vector2.ZERO
var loading_from_save: bool = false

var current_encounter : encounters

var is_in_menu: bool = false

var player_head_sprite: Texture2D
var player_name: String = "You"
var player_gender: String = "female"
var tutorial_flags: Dictionary = {}
var current_tutorial_objective: String = ""
var pending_cutscene_path: String = ""
var has_pending_player_spawn_position: bool = false
var pending_player_spawn_position: Vector2 = Vector2.ZERO

const LYRA_AXE_QUEST_PATH: String = "res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve Axe.tres"
const LYRA_TAVERN_CUTSCENE_PATH: String = "res://assets/Resources/Cutscenes/lyra_tavern_room_quest.json"
const LYRA_AXE_RETURN_CUTSCENE_PATH: String = "res://assets/Resources/Cutscenes/lyra_axe_return.json"
const SERA_QUEST_BOARD_CUTSCENE_PATH: String = "res://assets/Resources/Cutscenes/sera_quest_board_intro.json"

signal player_identity_changed

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
const LYRA_TAVERN_PLAYER_POSITION: Vector2 = Vector2(-2536.0, -3077.0)
const LYRA_FIRST_OBJECTIVE_TEXT: String = "Sera mentioned I should talk to Lyra. I can find her at the tavern."

var npc_bonds: Dictionary = {}

enum locations {
	Apothecary,
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

enum weather {
	Normal,
	Sunny,
	Rainy,
	Windy,
	Snowy,
}

# Time related stuff
# --------------------------------------------------------------------------------------------------

var running_time: float
var play_time_seconds: int
var play_time_minutes: int
var play_time_hours: int

var am_or_pm: bool
var current_day: int = 0
var current_year: int = 0
var current_hour: int = 6
var current_minute: int
var previous_day: int = 0
var previous_year: int = 0
var previous_hour: int = 6
var previous_minute: int = 0
var time_since_last_update: float
var seconds_since_day_started: float

var time_scale: int = 60
const TIME_STEP_MINUTES: int = 10
const TIME_STEP_SECONDS: int = TIME_STEP_MINUTES * 60

signal time_updated

func record_previous_time() -> void:
	previous_year = current_year
	previous_day = current_day
	previous_hour = current_hour
	previous_minute = current_minute

func get_time_total_minutes(day: int, hour: int, minute: int) -> int:
	return (day * 24 * 60) + (hour * 60) + minute

func did_time_reach(hour: int, minute: int) -> bool:
	if current_hour == hour and current_minute == minute:
		return true
	if previous_year != current_year:
		return false
	var previous_total = get_time_total_minutes(previous_day, previous_hour, previous_minute)
	var current_total = get_time_total_minutes(current_day, current_hour, current_minute)
	var target_total = get_time_total_minutes(current_day, hour, minute)
	return previous_total < target_total and target_total <= current_total

var time_paused: bool = false

# Updates the current time
func _physics_process(delta):	
	if AreaStateManager.currently_transitioning or GlobalCombatInformation.in_dungeon:
		return
	
	if time_paused:
		return
	running_time += delta
	if floor(running_time) == 1:
		update_time()
		running_time = 0

signal player_passed_out
func update_time():
	play_time_seconds += 1
	seconds_since_day_started += 1
	
	if (seconds_since_day_started * time_scale) - time_since_last_update >= TIME_STEP_SECONDS:
		record_previous_time()
		current_minute += TIME_STEP_MINUTES
		if current_minute >= 60:
			current_minute -= 60
			current_hour += 1
			if current_hour % 12 == 1:
				am_or_pm = true
			elif am_or_pm and current_hour % 12 == 0:
				player_advanced_day(true)
				am_or_pm = false
		time_since_last_update = (seconds_since_day_started * time_scale)
		time_updated.emit()
	if play_time_seconds == 60:
		play_time_minutes += 1
		play_time_seconds = 0
		time_since_last_update = 0
	if play_time_minutes == 60:
		play_time_hours += 1
		play_time_minutes = 0

signal day_passed
func player_advanced_day(did_they_pass_out):
	record_previous_time()
	current_day += 1
	
	if current_day == 366:
		current_year += 1
		current_day = 0
	
	current_hour = 6
	current_minute = 0
	
	time_since_last_update = 0
	seconds_since_day_started = 0
	
	time_updated.emit()
	_save_to_slot()
	if did_they_pass_out:
		spawn_location = null
	day_passed.emit(did_they_pass_out)

func set_calendar_time(year: int, day: int, hour: int, minute: int) -> void:
	record_previous_time()
	current_year = max(0, year)
	current_day = max(0, day)
	current_hour = clampi(hour, 0, 23)
	current_minute = clampi(minute, 0, 59)
	time_since_last_update = 0
	seconds_since_day_started = float((current_hour * 60) + current_minute) * 60.0 / float(time_scale)
	time_updated.emit()

func debug_skip_day() -> void:
	player_advanced_day(false)
	print("[Debug] Skipped to day ", current_day, ", year ", current_year)

func debug_advance_time(minutes: int = TIME_STEP_MINUTES) -> void:
	record_previous_time()
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

func get_default_player_name(gender: String = "") -> String:
	var normalized_gender = gender.to_lower()
	if normalized_gender.is_empty():
		normalized_gender = player_gender
	if normalized_gender == "male":
		return "Flynn"
	return "Elara"

func set_player_identity(new_name: String, new_gender: String) -> void:
	player_gender = new_gender.to_lower()
	if player_gender != "male":
		player_gender = "female"
	player_name = new_name.strip_edges()
	if player_name.is_empty():
		player_name = get_default_player_name(player_gender)
	var combat_info = get_node_or_null("/root/GlobalCombatInformation")
	if combat_info != null and combat_info.has_method("apply_player_gender_to_combatant"):
		combat_info.apply_player_gender_to_combatant()
	player_identity_changed.emit()

func start_new_game(new_name: String, new_gender: String) -> void:
	set_player_identity(new_name, new_gender)
	current_location = "Buildings_Insides"
	current_region = "Buildings_Insides"
	current_loading_zone = "Infirmary"
	saved_position = Vector2.ZERO
	loading_from_save = false
	has_pending_player_spawn_position = false
	npc_bonds.clear()
	tutorial_flags.clear()
	current_tutorial_objective = ""
	record_previous_time()
	current_year = 0
	current_day = 0
	current_hour = 6
	current_minute = 0
	play_time_seconds = 0
	play_time_minutes = 0
	play_time_hours = 0
	seconds_since_day_started = 0
	time_since_last_update = 0
	time_updated.emit()

func set_pending_player_spawn_position(spawn_position: Vector2) -> void:
	pending_player_spawn_position = spawn_position
	has_pending_player_spawn_position = true

func get_player_portrait_sheet() -> String:
	if player_gender == "male":
		return "res://GUI/dialogue_system/sprites/portraits/MCmale_portraits.png"
	return "res://GUI/dialogue_system/sprites/portraits/MCfemale_portraits.png"

func show_mc_thought(text: String) -> void:
	var dialogue_system = get_node_or_null("/root/DialogueSystem")
	if dialogue_system == null or not dialogue_system.has_method("show_cutscene_node"):
		return

	dialogue_system.show_cutscene_node({
		"speaker": player_name,
		"text": text,
		"portrait_sheet": get_player_portrait_sheet(),
		"portrait_frame": "neutral"
	})

func apply_loaded_player_profile(data: Dictionary) -> void:
	set_player_identity(data.get("player_name", player_name), data.get("player_gender", player_gender))
	current_tutorial_objective = data.get("current_tutorial_objective", current_tutorial_objective)
	current_day = int(data.get("current_day", current_day))
	current_year = int(data.get("current_year", current_year))
	current_hour = int(data.get("current_hour", current_hour))
	current_minute = int(data.get("current_minute", current_minute))
	play_time_hours = int(data.get("play_time_hours", play_time_hours))
	play_time_minutes = int(data.get("play_time_minutes", play_time_minutes))
	play_time_seconds = int(data.get("play_time_seconds", play_time_seconds))
	record_previous_time()

signal stop_listening
signal new_key_placed

var key_sprite_map = {
	# --- ALPHABET ---
	KEY_A: 0,
	KEY_B: 1,
	KEY_C: 2,
	KEY_D: 3,
	KEY_E: 4,
	KEY_F: 5,
	KEY_G: 6,
	KEY_H: 7,
	KEY_I: 8,
	KEY_J: 9,
	KEY_K: 10,
	KEY_L: 11,
	KEY_M: 12,
	KEY_N: 13,
	KEY_O: 14,
	KEY_P: 15,
	KEY_Q: 16,
	KEY_R: 17,
	KEY_S: 18,
	KEY_T: 19,
	KEY_U: 20,
	KEY_V: 21,
	KEY_X: 22, 
	KEY_W: 23,
	KEY_Y: 24,
	KEY_Z: 25,

	# --- NUMBERS ---
	KEY_0: 26,
	KEY_1: 27,
	KEY_2: 28,
	KEY_3: 29,
	KEY_4: 30,
	KEY_5: 31,
	KEY_6: 32,
	KEY_7: 33,
	KEY_8: 34,
	KEY_9: 35,

	# --- FUNCTION KEYS ---
	KEY_F1: 36,
	KEY_F2: 37,
	KEY_F3: 38,
	KEY_F4: 39,
	KEY_F5: 40,
	KEY_F6: 41,
	KEY_F7: 42,
	KEY_F8: 43,
	KEY_F9: 44,
	KEY_F10: 45,
	KEY_F11: 46,
	KEY_F12: 47,

	# --- NUMPAD ---
	KEY_KP_0: 26,
	KEY_KP_1: 27,
	KEY_KP_2: 28,
	KEY_KP_3: 29,
	KEY_KP_4: 30,
	KEY_KP_5: 31,
	KEY_KP_6: 32,
	KEY_KP_7: 33,
	KEY_KP_8: 34,
	KEY_KP_9: 35,
	KEY_KP_MULTIPLY: 51,  # Maps to *
	KEY_KP_DIVIDE: 53,    # Maps to /
	KEY_KP_SUBTRACT: 48,  # Maps to -
	KEY_KP_ADD: 49,       # Maps to +
	KEY_KP_PERIOD: 57,  
	KEY_KP_ENTER: 73,

	# --- SYMBOLS ---
	KEY_MINUS: 48,
	KEY_PLUS: 49,
	KEY_ASCIITILDE: 50, # ~
	KEY_ASTERISK: 51,   # *
	KEY_SEMICOLON: 52,  # ;
	KEY_SLASH: 53,      # /
	KEY_BRACKETLEFT: 54,  # [
	KEY_BRACKETRIGHT: 55, # ]
	KEY_QUOTEDBL: 56,   # "
	KEY_QUESTION: 57,   # ?
	KEY_LESS: 59,       # <
	KEY_GREATER: 60,    # >
	KEY_EXCLAM: 70,     # !

	# --- MODIFIERS & SPECIAL KEYS ---
	KEY_ALT: 58,
	KEY_ENTER: 73,      # 72 = Arrow Symbol, 73 = Text, 74 = Tall vertical Enter
	#KEY_KP_ENTER: 73,
	KEY_SHIFT: 76,      # 76 and 77 are both Shift keys
	KEY_BACKSPACE: 78,  # 78 = Text, 96 = Arrow Symbol
	KEY_CAPSLOCK: 79,
	KEY_ESCAPE: 80,
	KEY_CTRL: 81,
	KEY_END: 82,
	KEY_PAGEDOWN: 83,
	KEY_PAGEUP: 84,
	KEY_NUMLOCK: 85,
	KEY_DELETE: 86,
	KEY_SPACE: 87,
	KEY_UP: 88,
	KEY_DOWN: 89,
	KEY_LEFT: 90,
	KEY_RIGHT: 91,
	KEY_PRINT: 92,      # PrtScrn
	KEY_HOME: 93,
	KEY_TAB: 94,
	KEY_INSERT: 95
}

var joypad_button_map = {
	# --- FACE BUTTONS ---
	JOY_BUTTON_Y: 0, # Top Button -> Yellow Y
	JOY_BUTTON_B: 1, # Right Button -> Red B
	JOY_BUTTON_A: 2, # Bottom Button -> Green A
	JOY_BUTTON_X: 3, # Left Button -> Blue X
	
	# --- BUMPERS ---
	JOY_BUTTON_LEFT_SHOULDER: 8,  # LB
	JOY_BUTTON_RIGHT_SHOULDER: 9, # RB

	# --- D-PAD  ---
	JOY_BUTTON_DPAD_UP: 12,    # Flat edge on Top
	JOY_BUTTON_DPAD_DOWN: 13,  # Flat edge on Bottom
	JOY_BUTTON_DPAD_LEFT: 14,  # Flat edge on Left
	JOY_BUTTON_DPAD_RIGHT: 15, # Flat edge on Right

	# --- SYSTEM BUTTONS ---
	JOY_BUTTON_START: 39, # Plus symbol (Row 8)
	JOY_BUTTON_BACK: 40,  # Minus symbol (Row 8)
	
	# --- STICK CLICKS ---
	JOY_BUTTON_LEFT_STICK: 36,  # L3 (Arrow pushing down)
	JOY_BUTTON_RIGHT_STICK: 37  # R3 (Arrow pushing down)
}

var joypad_axis_map = {
	# --- TRIGGERS ---
	"4,1": 10, # LT (Left Trigger, Axis 4)
	"5,1": 11, # RT (Right Trigger, Axis 5)

	# --- LEFT JOYSTICK ---
	"0,-1": 22, # L-Stick Left  
	"1,-1": 20, # L-Stick Up   
	"0,1": 23,  # L-Stick Right 
	"1,1": 21,  # L-Stick Down  

	# --- RIGHT JOYSTICK ---
	"2,-1": 30, # R-Stick Left  
	"3,-1": 28, # R-Stick Up    
	"2,1": 31,  # R-Stick Right
	"3,1": 29,  # R-Stick Down 
}

var controller_mapping: Dictionary = {
	"up": "Controller_Up",
	"down": "Controller_Down",
	"left": "Controller_Left",
	"right": "Controller_Right",
	#"ui_right": "Controller_Dungeon_Targeting",
	#"Dungeon_Attack": "Controller_Dungeon_Attack",
	"Dungeon_Skill": "Controller_Dungeon_Skill",
	#"Dungeon_Defend": "Controller_Dungeon_Defend",
	"Dungeon_Item": "Controller_Dungeon_Item",
	"cancel": "Controller_Cancel",
	"confirm": "Controller_Confirm",
	#"Quest_Menu": "Controller_Quest_Menu",
	#"Open_Map": "Controller_Open_Map",
	#"Camera_Zoom_In": "Controller_Right_Stick_Up",
	#"Camera_Zoom_Out": "Controller_Right_Stick_Down"
	"Pause": "Controller_Pause",
}

enum key_options {
	UP = 0,
	DOWN = 1,
	LEFT = 2, 
	RIGHT = 3,
	CONFIRM = 4,
	CANCEL = 5,
	DUNGEON_ITEM = 6,
	DUNGEON_SKILL = 7,
	PAUSE = 8
}

var keyboard_mouse_icon_mapping: Dictionary = {
	"up": 88,
	"down": 89,
	"left": 90,
	"right": 91,
	"confirm": 91,
	"cancel": 87,
	"Dungeon_Item": 25,
	"Dungeon_Skill": 22,
	"Pause": 16,
}

var controller_icon_mapping: Dictionary = {
	"Controller_Up": 12,
	"Controller_Down": 13,
	"Controller_Left": 14,
	"Controller_Right": 15,
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_BRACKETLEFT:
		StateManager.debug_unlock_cave_dungeon()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_MINUS:
		if is_in_menu or Fade.is_fading or AreaStateManager.currently_transitioning:
			return
		StateManager.debug_skip_to_lyra_axe_sleep_setup()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("debug_advance_time"):
		if event is InputEventKey and event.echo:
			return
		if is_in_menu:
			get_viewport().set_input_as_handled()
			return
		debug_advance_time()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("test"):
		#if event is InputEventKey and event.echo:
		#	return
		#if is_in_menu:
		#	get_viewport().set_input_as_handled()
		#	return
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
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		using_controller = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	swapped_to_controller.emit(do_it)

func get_input_mapping(input_string: String, event: InputEvent = null) -> bool:
	if input_string == "Open_Map" or input_string == "Quest_Menu":
		return false
	
	var target_action = input_string
	if using_controller:
		target_action = controller_mapping[input_string]
	
	if event != null:
		return event.is_action_pressed(target_action)
	else:
		return Input.is_action_just_pressed(target_action)

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
		
		apply_loaded_player_profile(data)
		
		previous_coordinates = Vector2(data["previous_coordinates"]["x"], data["previous_coordinates"]["y"])
		
		npc_bonds = data.get("npc_bonds", {})
		
		Global.current_region = "Buildings_Insides"
		Global.current_loading_zone = "Bedroom"
		AreaStateManager._setup()
		AreaStateManager.swap_scene(self)
		
		save_loaded.emit()
		time_updated.emit()
	else:
		print("Parse Error: ", json.get_error_message())

func get_save_data() -> Dictionary:
	var save_dict = {
		"player_name": player_name,
		"player_gender": player_gender,
		"current_day": current_day,
		"current_year": current_year,
		"current_hour": current_hour,
		"current_minute": current_minute,

		"npc_bonds": npc_bonds,
	}
	var player = get_tree().get_first_node_in_group("Overworld_Player")
	if player:
		save_dict["player_position"] = {
			"x": player.global_position.x,
			"y": player.global_position.y
		}
	return save_dict
	
const SAVE_DIR = "user://saves/"
func _save_to_slot():
	var data = get_save_data()
	data["play_time_hours"] = play_time_hours
	data["play_time_minutes"] = play_time_minutes
	data["play_time_seconds"] = play_time_seconds
	data["combat"] = GlobalCombatInformation.export_to_JSON()
	data["progression_states"] = StateManager.export_to_json()
	
	var json_string = JSON.stringify(data, "\t")
	if CURRENT_SAVE_SLOT != null:
		var file = FileAccess.open(CURRENT_SAVE_SLOT, FileAccess.WRITE)
		if file:
			file.store_string(json_string)
			file.flush()
			file.close()
			file = null
	else:
		var current_slot: int = 0
		while FileAccess.file_exists(SAVE_DIR + "slot_%d.json" % current_slot):
			current_slot += 1

		CURRENT_SAVE_SLOT = (SAVE_DIR + "slot_%d.json" % current_slot)
		var file = FileAccess.open(CURRENT_SAVE_SLOT, FileAccess.WRITE)
		file.store_string(json_string)
		file.flush()
		file.close()

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

# --------------------------------------------------------------------------------------------------

func _ready():
	time_updated.emit()
