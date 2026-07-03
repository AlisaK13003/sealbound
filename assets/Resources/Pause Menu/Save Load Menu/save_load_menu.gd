extends Control

enum Mode { SAVE, LOAD }
@export var start_in_load_mode: bool = false
@export var allow_saving: bool = true
@export var show_delete: bool = true

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
	
	save_btn.visible = allow_saving
	delete_btn.visible = show_delete
	_set_mode(Mode.LOAD if start_in_load_mode else Mode.SAVE)
	refresh_slots()

func _set_mode(mode: Mode):
	if mode == Mode.SAVE and not allow_saving:
		mode = Mode.LOAD
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
				var saved_location = _get_saved_location(data)
				var playtime = "%d:%02d:%02d" % [
					data.get("play_time_hours", 0),
					data.get("play_time_minutes", 0),
					data.get("play_time_seconds", 0)
				]
				btn.text = "Slot %d  |  %s  |  %s" % [i + 1, saved_location, playtime]
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
		file.flush()
		file = null
	call_deferred("refresh_slots")

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
	var saved_location = _get_saved_location(data)
	Global.apply_loaded_player_profile(data)
	Global.money = data.get("money", Global.money)
	Global.current_location = saved_location
	Global.current_region = saved_location
	
	if data.has("previous_coordinates"):
		Global.previous_coordinates = Vector2(data["previous_coordinates"]["x"], data["previous_coordinates"]["y"])
	
	Global.item_list.clear()
	for path in data.get("item_list", []):
		Global.item_list.append(load(path))
	Global.equipment_list.clear()
	for path in data.get("equipment_list", []):
		Global.equipment_list.append(load(path))
	Global.weapon_list.clear()
	for path in data.get("weapon_list", []):
		Global.weapon_list.append(load(path))
	
	if data.has("npc_bonds"):
		Global.npc_bonds = data["npc_bonds"]
	
	if data.has("progression_state"):
		Global.progression_state.clear()
		for key in data["progression_state"]:
			Global.progression_state[key] = data["progression_state"][key]

	Global.save_loaded.emit()
	Global.time_updated.emit()
	
	# Unpause and load the scene
	if data.has("player_position"):
		Global.saved_position = Vector2(data["player_position"]["x"], data["player_position"]["y"])
		Global.loading_from_save = true

	Global.current_loading_zone = data.get("current_loading_zone", "")
	get_tree().paused = false
	get_tree().change_scene_to_file(Global.location_paths.get(saved_location, "res://scenes/main/Hearthwynn.tscn"))

func _get_saved_location(data: Dictionary) -> String:
	var region = data.get("current_region", "")
	if Global.location_paths.has(region):
		return region
	return data.get("current_location", "Village")

func _delete_selected():
	if selected_slot < 0:
		return
	var path = SAVE_DIR + "slot_%d.json" % selected_slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	refresh_slots()
