extends Control

@export var key_name: String
@export var input_action: String

@onready var keyboard_icon = $"Keyboard Icons"
@onready var controller_icon = $"Controller Icons"
@onready var label_main = $VBoxContainer/Label
@onready var label_prompt = $VBoxContainer/Label2

var awaiting_new_key: bool = false
var came_from_me: bool = false
var held_key: int = KEY_NONE

var SAVE_PATH = "user://settings.cfg"

func _ready():
	label_main.text = key_name
	
	Global.stop_listening.connect(_reset)
	Global.new_key_placed.connect(_on_global_key_update)
	
	update_ui_from_inputmap()

func update_ui_from_inputmap():
	var events = InputMap.action_get_events(input_action)
	for event in events:
		if event is InputEventKey:
			held_key = event.physical_keycode
			keyboard_icon.frame = Global.key_sprite_map.get(held_key, 99)
			return
	
	held_key = KEY_NONE
	keyboard_icon.frame = 99

func _new_key_selected(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			came_from_me = true
			Global.stop_listening.emit() 
			
			awaiting_new_key = true
			keyboard_icon.visible = false
			label_prompt.visible = true
			came_from_me = false

func _unhandled_input(event):
	if awaiting_new_key and event is InputEventKey and event.pressed and not event.is_echo():
		get_viewport().set_input_as_handled()
		awaiting_new_key = false
		
		var new_keycode = event.physical_keycode
		
		update_input_map(new_keycode)
		
		held_key = new_keycode
		keyboard_icon.frame = Global.key_sprite_map.get(held_key, 99)
		keyboard_icon.visible = true
		label_prompt.visible = false
		
		came_from_me = true
		Global.new_key_placed.emit()
		came_from_me = false
		
		save_key_to_config(new_keycode)

func update_input_map(new_key: int):
	for action in InputMap.get_actions():		
		var events = InputMap.action_get_events(action)
		for e in events:
			if e is InputEventKey and e.physical_keycode == new_key:
				InputMap.action_erase_event(action, e)
	
	var current_events = InputMap.action_get_events(input_action)
	for e in current_events:
		if e is InputEventKey:
			InputMap.action_erase_event(input_action, e)
	
	var new_event = InputEventKey.new()
	new_event.physical_keycode = new_key
	InputMap.action_add_event(input_action, new_event)


func _on_global_key_update():
	update_ui_from_inputmap()

func save_key_to_config(keycode: int):
	var config = ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("binds", input_action, keycode)
	config.save(SAVE_PATH)

func _reset():
	if not came_from_me:
		awaiting_new_key = false
		keyboard_icon.visible = true
		label_prompt.visible = false
