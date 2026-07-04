extends TextureButton

@export var input_event_that_will_activate : String

@export var button_name: String

@onready var button_name_text = $HBoxContainer/Label2
@onready var box = $HBoxContainer
@onready var button_icon = $HBoxContainer/Container/Sprite2D

@onready var keyboard_mouse_icon_sprites = load("res://assets/tile sheets/Centered_Keyboard_Mouse_Inputs.png")
@onready var controller_icon_sprites = load("res://assets/tile sheets/Centered_Controller_Inputs.png")
signal activated

@export var disabled_: bool = false

func _ready():
	if disabled_:
		return
	button_name_text.text = button_name
	if input_event_that_will_activate != "":
		var event_to_check = InputMap.action_get_events(input_event_that_will_activate)[0]
		var _incoming_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode

	Global.swapped_to_controller.connect(swap_to_controller_icons)
	swap_to_controller_icons(Global.using_controller)

func update_name(new_name: String):
	button_name_text.text = new_name

# 10 x_frames 10 v_frames for keyboard
# 4 h_frames 11 v_frames for controller
func swap_to_controller_icons(do_it):
	if input_event_that_will_activate != "":
		if not do_it:
			var kb_event = get_input_for_action(input_event_that_will_activate, true)
			var position_to_get = Global.key_sprite_map[kb_event.physical_keycode]
			
			button_icon.hframes = 10
			button_icon.vframes = 10
			button_icon.texture = keyboard_mouse_icon_sprites
			button_icon.frame = position_to_get
		else:
			var ctrl_event = get_input_for_action(Global.controller_mapping[input_event_that_will_activate], false)
			var position_to_get = get_controller_sprite_index(ctrl_event)
			button_icon.hframes = 4
			button_icon.vframes = 11
			button_icon.texture = controller_icon_sprites
			button_icon.frame = position_to_get
			
func get_controller_sprite_index(event: InputEvent) -> int:
	if event is InputEventJoypadButton:
		return Global.joypad_button_map.get(event.button_index, 42)
		
	elif event is InputEventJoypadMotion:
		var direction = int(sign(event.axis_value)) 
		var axis_key = str(event.axis) + "," + str(direction)
		
		return Global.joypad_axis_map.get(axis_key, 42)
		
	return 42
	
func get_input_for_action(action_name: String, check_keyboard: bool) -> InputEvent:
	var events = InputMap.action_get_events(action_name)
	
	for event in events:
		if check_keyboard and event is InputEventKey:
			return event
			
		elif not check_keyboard and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			return event
			
	return null

func get_key_name_for_action(action_name: String) -> String:
	var keycode = get_input_for_action(action_name, true)
	
	if keycode != KEY_NONE:
		return OS.get_keycode_string(keycode)
		
	return "Unbound"

func _input(_event):
	if input_event_that_will_activate != "":
		if Global.get_input_mapping(input_event_that_will_activate):
			activated.emit()

func _gui_input(event):
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		activated.emit()
		print("PRESSED")
