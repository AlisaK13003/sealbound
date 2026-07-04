extends Control

@export var key_name: String
@export var input_action: String
@export var is_keyboard: bool = true

@onready var keyboard_icon = $"Keyboard Icons"
@onready var controller_icon = $"Controller Icons"
@onready var label_main = $VBoxContainer/Label
@onready var label_prompt = $VBoxContainer/Label2
@onready var unmapped_label = $Label

var awaiting_new_key: bool = false
var came_from_me: bool = false
var held_event: InputEvent = null

var SAVE_PATH = "user://settings.cfg"

func _ready():
	label_main.text = key_name
	
	Global.stop_listening.connect(_reset)
	Global.new_key_placed.connect(_on_global_key_update)
	load_key_from_config()
	update_ui_from_inputmap()
	visibility_changed.connect(_reset_to_held)

func update_ui_from_inputmap():
	held_event = null
	var events = InputMap.action_get_events(input_action)
	
	for event in events:
		if is_keyboard and event is InputEventKey:
			held_event = event
			$"Keyboard Icons".frame = Global.key_sprite_map.get(event.physical_keycode, 99)
			update_unmapped_status(false)
			return
		elif not is_keyboard and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			held_event = event
			$"Controller Icons".frame = get_controller_sprite_index(event)
			update_unmapped_status(false)
			return
			
	if is_keyboard:
		$"Keyboard Icons".frame = 87 
	else:
		$"Controller Icons".frame = 42
	update_unmapped_status(true)

func _new_key_selected(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			came_from_me = true
			Global.stop_listening.emit() 
			update_unmapped_status(false)
			awaiting_new_key = true
			keyboard_icon.visible = false
			controller_icon.visible = false
			label_prompt.visible = true
			came_from_me = false

func update_unmapped_status(is_unmapped: bool) -> void:
	unmapped_label.visible = is_unmapped
	
	if is_keyboard:
		$"Keyboard Icons".visible = not is_unmapped
	else:
		$"Controller Icons".visible = not is_unmapped

func load_key_from_config():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
		
	if is_keyboard:
		var keycode = config.get_value("binds_keyboard", input_action, KEY_NONE)
		if keycode != KEY_NONE:
			var new_event = InputEventKey.new()
			new_event.physical_keycode = keycode
			update_input_map(new_event)
	else:
		var bind = config.get_value("binds_controller", input_action, {})
		if bind.keys().size() > 0:
			var new_event = null
			if bind["type"] == "button":
				new_event = InputEventJoypadButton.new()
				new_event.button_index = bind["index"]
			elif bind["type"] == "motion":
				new_event = InputEventJoypadMotion.new()
				new_event.axis = bind["axis"]
				new_event.axis_value = bind["value"]
			
			if new_event:
				update_input_map(new_event)
				
	update_ui_from_inputmap()

func _unhandled_input(event):
	if not awaiting_new_key: return

	var is_cancel = false
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		is_cancel = true
	elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
		is_cancel = true
		
	if is_cancel:
		get_viewport().set_input_as_handled()
		_reset_to_held() 
		return

	var is_valid_input = false

	if is_keyboard:
		if event is InputEventKey and event.pressed and not event.is_echo():
			is_valid_input = true
			
	else:
		if event is InputEventJoypadButton and event.pressed:
			is_valid_input = true
			held_event = event 
			
		elif event is InputEventJoypadMotion:
			if abs(event.axis_value) > 0.5:
				is_valid_input = true
				
				var clean_event = InputEventJoypadMotion.new()
				clean_event.axis = event.axis
				clean_event.axis_value = sign(event.axis_value)
				
				held_event = clean_event

	if is_valid_input:
		get_viewport().set_input_as_handled()
		awaiting_new_key = false
		
		save_key_to_config(held_event)
		update_input_map(held_event)
		
		if is_keyboard:
			$"Keyboard Icons".frame = Global.key_sprite_map.get(held_event.physical_keycode, 87)
			$"Keyboard Icons".visible = true
		else:
			$"Controller Icons".frame = get_controller_sprite_index(held_event)
			$"Controller Icons".visible = true
			
		$VBoxContainer/Label2.visible = false
		update_unmapped_status(false)
		came_from_me = true
		Global.new_key_placed.emit()
		came_from_me = false

func _reset_to_held():
	awaiting_new_key = false
	label_prompt.visible = false
	
	var is_unmapped = (held_event == null)
	update_unmapped_status(is_unmapped)
	update_unmapped_status(held_event == null)

func get_controller_sprite_index(event: InputEvent) -> int:
	if event is InputEventJoypadButton:
		return Global.joypad_button_map.get(event.button_index, 42)
		
	elif event is InputEventJoypadMotion:
		var direction = int(sign(event.axis_value)) 
		var axis_key = str(event.axis) + "," + str(direction)
		
		return Global.joypad_axis_map.get(axis_key, 42)
		
	return 42

func update_input_map(new_event: InputEvent):
	for action in InputMap.get_actions():
		if action.begins_with("ui_"): continue 
		
		var events = InputMap.action_get_events(action)
		for e in events:
			if is_keyboard and e is InputEventKey and new_event is InputEventKey:
				if e.physical_keycode == new_event.physical_keycode:
					InputMap.action_erase_event(action, e)
					
			elif not is_keyboard and is_same_controller_input(e, new_event):
				InputMap.action_erase_event(action, e)
	
	var current_events = InputMap.action_get_events(input_action)
	for e in current_events:
		if is_keyboard and e is InputEventKey:
			InputMap.action_erase_event(input_action, e)
		elif not is_keyboard and (e is InputEventJoypadButton or e is InputEventJoypadMotion):
			InputMap.action_erase_event(input_action, e)
	
	InputMap.action_add_event(input_action, new_event)


func is_same_controller_input(e1: InputEvent, e2: InputEvent) -> bool:
	if e1 is InputEventJoypadButton and e2 is InputEventJoypadButton:
		return e1.button_index == e2.button_index
	if e1 is InputEventJoypadMotion and e2 is InputEventJoypadMotion:
		return e1.axis == e2.axis and sign(e1.axis_value) == sign(e2.axis_value)
	return false

func _on_global_key_update():
	update_ui_from_inputmap()

func save_key_to_config(event: InputEvent):
	var config = ConfigFile.new()
	config.load(SAVE_PATH)
	
	if is_keyboard:
		if event is InputEventKey:
			config.set_value("binds_keyboard", input_action, event.physical_keycode)
	else:
		if event is InputEventJoypadButton:
			config.set_value("binds_controller", input_action, {
				"type": "button",
				"index": event.button_index
			})
		elif event is InputEventJoypadMotion:
			config.set_value("binds_controller", input_action, {
				"type": "motion",
				"axis": event.axis,
				"value": event.axis_value
			})
			
	config.save(SAVE_PATH)

func _reset():
	if not came_from_me:
		_reset_to_held()
