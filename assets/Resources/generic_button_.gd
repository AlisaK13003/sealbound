extends TextureButton

@export var input_event_that_will_activate : String
@export var hide_key_hint: bool = true

@export var button_name: String
@export var show_panel_and_name : bool = true
@export var show_only_name: bool = false

@onready var hint_label = $HBoxContainer/Panel/Label
@onready var button_name_text = $HBoxContainer/Label2
@onready var fall_back = $HBoxContainer/Fall_back
@onready var box = $HBoxContainer

signal activated

func _ready():
	if show_panel_and_name:
		fall_back.visible = false
		$HBoxContainer/Panel.visible = true
		$HBoxContainer/Label2.visible = true
	elif show_only_name:
		fall_back.visible = false
		$HBoxContainer/Panel.visible = false
		$HBoxContainer/Label2.visible = true
	else:
		fall_back.visible = true
		$HBoxContainer/Panel.visible = false
		$HBoxContainer/Label2.visible = false
	button_name_text.text = button_name
	if input_event_that_will_activate != "":
		var event_to_check = InputMap.action_get_events(input_event_that_will_activate)[0]
		var incoming_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode
		hint_label.text = OS.get_keycode_string(incoming_key)
		fall_back.text = hint_label.text
		if hint_label.text == "Space":
			hint_label.text = "␣"
			fall_back.text = hint_label.text
	box.visible = not hide_key_hint

func update_name(new_name: String):
	button_name_text.text = new_name

func _input(event):
	if input_event_that_will_activate != "" and Input.is_action_just_pressed(input_event_that_will_activate):
		activated.emit()

func _gui_input(event):
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		activated.emit()
		print("PRESSED")
