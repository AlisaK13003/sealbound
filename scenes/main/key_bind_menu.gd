extends Control

@onready var awaiting_key_press_screen = $CanvasLayer/Control
@onready var button_container = $CanvasLayer/HBoxContainer/VBoxContainer2
@onready var confliction_screen = $CanvasLayer/NinePatchRect3
var waiting_for_input = false
var awaiting_confirmation = false

signal key_pressed(what_key)
signal confirmation_given

var actions_to_change = ["up", "down", "left", "right", "Interact", "Pause", "Confirm", "Cancel"]

func _ready():
	for child in range(button_container.get_child_count()):
		var event_to_check = InputMap.action_get_events(actions_to_change[child])[0]
		var incoming_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode
		button_container.get_child(child).text = OS.get_keycode_string(incoming_key)

func _input(event):
	if event is InputEventKey and waiting_for_input:
		key_pressed.emit(event)
		waiting_for_input = false
	if awaiting_confirmation and event.is_action_pressed("Confirm"):
		confirmation_given.emit(true)
	if awaiting_confirmation and event.is_action_pressed("Cancel"):
		confirmation_given.emit(false)

func setup_key_bind_swap(child_num, what_action_event):
	waiting_for_input = true
	awaiting_key_press_screen.visible = true
	var key_just_pressed = await key_pressed
	waiting_for_input = false
	var ret_val = await check_if_key_is_already_used(what_action_event, key_just_pressed)
	
	awaiting_key_press_screen.visible = false
	if ret_val is bool:
		var incoming_key = key_just_pressed.keycode if key_just_pressed.keycode != 0 else key_just_pressed.physical_keycode
		button_container.get_child(child_num).text = OS.get_keycode_string(incoming_key) 
		InputMap.action_erase_events(what_action_event)
		var new_key = key_just_pressed.duplicate()
		new_key.pressed = false
		InputMap.action_add_event(what_action_event, new_key)
	else:
		confliction_screen.visible = true
		confliction_screen.get_child(0).text = "Key "+ OS.get_keycode_string(ret_val) +  " is already in use, want to overwrite?"
		awaiting_confirmation = true
		var confirmation = await confirmation_given
		if confirmation:
			confliction_screen.visible = false
			var spot_to_delete
			for event in range(actions_to_change.size()):
				var event_to_check = InputMap.action_get_events(actions_to_change[event])[0]
				var outgoing_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode
				
				if event_to_check is InputEventKey:
					if outgoing_key == ret_val:
						spot_to_delete = event
						break
			var incoming_key = key_just_pressed.keycode if key_just_pressed.keycode != 0 else key_just_pressed.physical_keycode
			button_container.get_child(child_num).text = OS.get_keycode_string(incoming_key) 
			button_container.get_child(spot_to_delete).text = ""
			InputMap.action_erase_events(what_action_event)
			InputMap.action_erase_events(actions_to_change[spot_to_delete])
			var new_key = key_just_pressed.duplicate()
			new_key.pressed = false
			awaiting_key_press_screen.visible = false
			InputMap.action_add_event(what_action_event, new_key)
		else:
			print("Can't Swap to that")
			awaiting_key_press_screen.visible = false
			confliction_screen.visible = false

func check_if_key_is_already_used(what_action_event, key_event):
	var incoming_key = key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
	for event in range(actions_to_change.size()):
		if actions_to_change[event] == what_action_event:
			continue
		elif InputMap.action_get_events(actions_to_change[event]).size() == 0:
			return true
		
		var event_to_check = InputMap.action_get_events(actions_to_change[event])[0]
		var outgoing_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode
		
		if event_to_check is InputEventKey:
			if outgoing_key == incoming_key:
				return outgoing_key
	return true
