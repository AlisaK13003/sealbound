extends Control

enum Mode { SAVE, LOAD }
var current_mode: Mode = Mode.SAVE
var selected_slot: int = -1

const SAVE_DIR = "user://saves/"
const SLOT_COUNT = 3

@onready var slot_container = $Main/SlotContainer
@onready var save_btn = $Main/ModeToggle/SaveBtn
@onready var load_btn = $Main/ModeToggle/LoadBtn
@onready var delete_btn = $Main/DeleteBtn

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	save_btn.pressed.connect(_set_mode.bind(Mode.SAVE))
	load_btn.pressed.connect(_set_mode.bind(Mode.LOAD))
	delete_btn.pressed.connect(_delete_selected)
	
	for i in SLOT_COUNT:
		slot_container.get_child(i).pressed.connect(_slot_pressed.bind(i))
	
	# Make sure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	
	_set_mode(Mode.SAVE)
	refresh_slots()

func _set_mode(mode: Mode):
	current_mode = mode
	save_btn.disabled = (mode == Mode.SAVE)
	load_btn.disabled = (mode == Mode.LOAD)

func refresh_slots():
	for i in SLOT_COUNT:
		var path = SAVE_DIR + "slot_%d.json" % i
		var btn = slot_container.get_child(i)
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.data
				var playtime = "%d:%02d:%02d" % [
					data.get("play_time_hours", 0),
					data.get("play_time_minutes", 0),
					data.get("play_time_seconds", 0)
				]
				btn.text = "Slot %d  |  %s  |  %s" % [i + 1, data.get("current_location", "???"), playtime]
			else:
				btn.text = "Slot %d  |  Corrupted" % (i + 1)
		else:
			btn.text = "Slot %d  |  Empty" % (i + 1)

func _slot_pressed(index: int):
	selected_slot = index
	if current_mode == Mode.SAVE:
		_save_to_slot(index)
	else:
		_load_from_slot(index)

func _save_to_slot(index: int):
	var data = Global.get_save_data()
	# Tack on playtime so the slot preview can show it
	data["play_time_hours"] = Global.play_time_hours
	data["play_time_minutes"] = Global.play_time_minutes
	data["play_time_seconds"] = Global.play_time_seconds
	
	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open(SAVE_DIR + "slot_%d.json" % index, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
	refresh_slots()

func _load_from_slot(index: int):
	var path = SAVE_DIR + "slot_%d.json" % index
	if not FileAccess.file_exists(path):
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		# Better approach — feed the dict straight in:
		_apply_save_data(json.data)

func _apply_save_data(data: Dictionary):
	# Same logic as your load_save_data but takes a dict directly
	Global.money = data["money"]
	Global.current_location = data["current_location"]
	Global.previous_coordinates = Vector2(data["previous_coordinates"]["x"], data["previous_coordinates"]["y"])
	
	Global.party_slot_1 = load(data["party_slots"][0]["path"])
	Global.party_slot_2 = load(data["party_slots"][1]["path"])
	Global.party_slot_3 = load(data["party_slots"][2]["path"])
	Global.party_slot_1.load_save_data(data["party_slots"][0])
	Global.party_slot_2.load_save_data(data["party_slots"][1])
	Global.party_slot_3.load_save_data(data["party_slots"][2])
	
	Global.item_list.clear()
	for path in data["item_list"]:
		Global.item_list.append(load(path))
	Global.equipment_list.clear()
	for path in data["equipment_list"]:
		Global.equipment_list.append(load(path))
	Global.weapon_list.clear()
	for path in data["weapon_list"]:
		Global.weapon_list.append(load(path))
	
	Global.progression_state.clear()
	for key in data["progression_state"]:
		Global.progression_state[int(key)] = data["progression_state"][key]
	
	Global.save_loaded.emit()
	Global.time_updated.emit()
	
	# Unpause and load the scene
	if data.has("player_position"):
		Global.saved_position = Vector2(data["player_position"]["x"], data["player_position"]["y"])
		Global.loading_from_save = true

	Global.current_loading_zone = ""
	get_tree().paused = false
	get_tree().change_scene_to_file(Global.location_paths.get(data["current_location"], "res://scenes/main/Hearthwynn.tscn"))

func _delete_selected():
	if selected_slot < 0:
		return
	var path = SAVE_DIR + "slot_%d.json" % selected_slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	refresh_slots()
