extends Control

enum Mode { SAVE, LOAD }
@export var start_in_load_mode: bool = false
@export var allow_saving: bool = true
@export var show_delete: bool = true

var current_mode: Mode = Mode.SAVE
var selected_slot: int = -1
var hovered_slot: int = -1

const SAVE_DIR = "user://saves/"
const SLOT_COUNT = 3
#const TEST_SELECTABLE_EMPTY_SLOT = 2
const DEFAULT_TEXT_COLOR = Color(0.36862746, 0.23137255, 0.13725491, 1.0)
const ACTIVE_TEXT_COLOR = Color(0.6, 0.36078432, 0.03529412, 1.0)
const DISABLED_ALPHA = 0.55

@onready var slot_container = get_node_or_null("Main/SlotContainer")
#@onready var save_btn = get_node_or_null("Main/ModeToggle/SaveBtn")
@onready var load_btn = get_node_or_null("Main/ModeToggle/LoadBtn")
@onready var delete_btn = _find_first_node([
	"Main/ModeToggle/DeleteBtn",
	"Main/DeleteBtn"
])

	
func _ready():
	#print("overworld player count: ", get_tree().get_nodes_in_group("Overworld_Player").size())
	process_mode = Node.PROCESS_MODE_ALWAYS
	#save_btn.pressed.connect(_set_mode.bind(Mode.SAVE))
	#load_btn.pressed.connect(_set_mode.bind(Mode.LOAD))
	#delete_btn.pressed.connect(_delete_selected)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_prepare_action_button(delete_btn)
	_prepare_action_button(load_btn)
	#_connect_button(save_btn, _set_mode.bind(Mode.SAVE))
	_connect_button(load_btn, _load_selected)
	#_connect_button(delete_btn, _delete_selected)
	visibility_changed.connect(refresh_slots)
	if slot_container:
		for i in min(SLOT_COUNT, slot_container.get_child_count()):
			if	FileAccess.file_exists(SAVE_DIR + "slot_%d.json" % i):
				var slot_button = slot_container.get_child(i)
				_prepare_slot_button(slot_button)
				_connect_button(slot_button, _slot_pressed.bind(i))
				_connect_hover(slot_button, _slot_hover_changed.bind(i, true), _slot_hover_changed.bind(i, false))
			else:
				var slot_button = slot_container.get_child(i)
				slot_button.visible = false
	# Make sure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	
	#if save_btn:
	#	save_btn.visible = allow_saving
	if delete_btn:
		delete_btn.visible = show_delete
	#if start_in_load_mode or not allow_saving or save_btn == null:
	#	_set_mode(Mode.LOAD)
	#else:
	#	_set_mode(Mode.SAVE)
	refresh_slots()
	_update_action_buttons()

func _set_mode(mode: Mode):
	if mode == Mode.SAVE and not allow_saving:
		mode = Mode.LOAD
	current_mode = mode
	#if save_btn:
	#	save_btn.disabled = (mode == Mode.SAVE)
	_update_action_buttons()

func refresh_slots():
	if slot_container == null:
		return
	for i in SLOT_COUNT:
		if i >= slot_container.get_child_count():
			return
		var path = SAVE_DIR + "slot_%d.json" % i
		var btn = slot_container.get_child(i)
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.data
				var saved_location = _get_saved_location(data)
				var playtime = "%d:%02d" % [
					data.get("play_time_hours", 0),
					data.get("play_time_minutes", 0),
				]
				_set_button_text(btn, "Slot %d  |  %s  |  %s" % [i + 1, saved_location, playtime])
			else:
				_set_button_text(btn, "Slot %d  |  Corrupted" % (i + 1))
		else:
			_set_button_text(btn, "Empty Save")
			btn.visible = false
			return false

	if selected_slot >= 0 and not _is_slot_selectable(selected_slot):
		selected_slot = -1
	_update_slot_states()
	_update_action_buttons()

func _slot_pressed(index: int):
	if not _is_slot_selectable(index):
		return
	selected_slot = index
	_update_slot_states()
	_update_action_buttons()

func _save_to_slot(index: int):
	var data = Global.get_save_data()
	data["play_time_hours"] = Global.play_time_hours
	data["play_time_minutes"] = Global.play_time_minutes
	data["play_time_seconds"] = Global.play_time_seconds
	data["combat"] = GlobalCombatInformation.export_to_JSON()
	
	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open(SAVE_DIR + "slot_%d.json" % index, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.flush()
		file.close()
		refresh_slots()
		file = null
	call_deferred("refresh_slots")

func _load_from_slot(index: int):
	var path = SAVE_DIR + "slot_%d.json" % index
	Global.CURRENT_SAVE_SLOT = path
	if not FileAccess.file_exists(path):
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_apply_save_data(json.data)

func _apply_save_data(data: Dictionary):
	Global.apply_loaded_player_profile(data)
	
	if data.has("npc_bonds"):
		Global.npc_bonds = data["npc_bonds"]
	
	if data.has("progression_state"):
		Global.progression_state.clear()
		for key in data["progression_state"]:
			Global.progression_state[key] = data["progression_state"][key]

	Global.save_loaded.emit()
	Global.time_updated.emit()
	
	if data.has("combat"):
		GlobalCombatInformation.load_saved_data(data["combat"]) 
		
	Global.current_loading_zone = "Bedroom"
	Global.current_region = "Buildings_Insides"
		
	get_tree().paused = false
	AreaStateManager._setup()
	AreaStateManager.swap_scene(get_tree().current_scene)

func _get_saved_location(data: Dictionary) -> String:
	var region = data.get("current_region", "")
	if Global.location_paths.has(region):
		return region
	return data.get("current_location", "Village")

func _delete_selected():
	print("HELLOOOOO")
	if selected_slot < 0:
		return
	var path = SAVE_DIR + "slot_%d.json" % selected_slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	selected_slot = -1
	refresh_slots()

func _connect_button(button: Node, callback: Callable):
	if button is BaseButton:
		if not button.pressed.is_connected(callback):
			button.pressed.connect(callback)

func _connect_hover(button: Node, enter_callback: Callable, exit_callback: Callable):
	if button is Control:
		if not button.mouse_entered.is_connected(enter_callback):
			button.mouse_entered.connect(enter_callback)
		if not button.mouse_exited.is_connected(exit_callback):
			button.mouse_exited.connect(exit_callback)

func _set_button_text(button: Node, text: String):
	var label = button.get_node_or_null("Label")
	if label is Label:
		label.text = text
		if button is Button:
			button.text = ""
	elif button is Button:
		button.text = text

func _load_selected():
	if selected_slot < 0:
		return
	_load_from_slot(selected_slot)

func _slot_hover_changed(index: int, is_hovered: bool):
	if is_hovered:
		hovered_slot = index
	elif hovered_slot == index:
		hovered_slot = -1
	_update_slot_states()

func _update_slot_states():
	if slot_container == null:
		return
	for i in min(SLOT_COUNT, slot_container.get_child_count()):
		var button = slot_container.get_child(i)
		var selectable = _is_slot_selectable(i)
		var active = selectable and (selected_slot == i or hovered_slot == i)
		if button is BaseButton:
			button.disabled = not selectable
			button.focus_mode = Control.FOCUS_ALL if selectable else Control.FOCUS_NONE
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if selectable else Control.CURSOR_ARROW
			button.set_pressed_no_signal(selected_slot == i)
		_set_button_alpha(button, 1.0)
		_set_button_font_color(button, ACTIVE_TEXT_COLOR if active else DEFAULT_TEXT_COLOR)

func _update_action_buttons():
	var has_selection = selected_slot >= 0
	_set_action_button_enabled(delete_btn, has_selection and show_delete)
	_set_action_button_enabled(load_btn, has_selection)

func _is_slot_selectable(index: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "slot_%d.json" % index)

func _prepare_slot_button(button: Node):
	_prepare_action_button(button)
	if button is BaseButton:
		button.toggle_mode = true

func _prepare_action_button(button: Node):
	if button is BaseButton:
		var base_button = button as BaseButton
		base_button.flat = true
		base_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		base_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		base_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		base_button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		base_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for child in button.get_children() if button != null else []:
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_action_button_enabled(button: Node, is_enabled: bool):
	if button is BaseButton:
		button.disabled = not is_enabled
		button.focus_mode = Control.FOCUS_ALL if is_enabled else Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_enabled else Control.CURSOR_ARROW
	_set_button_alpha(button, 1.0 if is_enabled else DISABLED_ALPHA)

func _set_button_alpha(button: Node, alpha: float):
	if button is CanvasItem:
		(button as CanvasItem).modulate.a = alpha
	var texture = button.get_node_or_null("TextureRect") if button != null else null
	if texture is CanvasItem:
		(texture as CanvasItem).modulate.a = alpha
	var label = button.get_node_or_null("Label") if button != null else null
	if label is CanvasItem:
		(label as CanvasItem).modulate.a = alpha

func _set_button_font_color(button: Node, color: Color):
	var label = button.get_node_or_null("Label") if button != null else null
	if label is Label:
		(label as Label).add_theme_color_override("font_color", color)

func _find_first_node(paths: Array) -> Node:
	for path in paths:
		var node = get_node_or_null(path)
		if node:
			return node
	return null
