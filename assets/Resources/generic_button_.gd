extends TextureButton

@export var input_event_that_will_activate : String
@export var hide_key_hint: bool = true
@onready var hint_label = $Label

func _ready():
	var event_to_check = InputMap.action_get_events(input_event_that_will_activate)[0]
	var incoming_key = event_to_check.keycode if event_to_check.keycode != 0 else event_to_check.physical_keycode
	hint_label.text = OS.get_keycode_string(incoming_key)
	hint_label.visible = hide_key_hint

func _pressed():
	print("HELLO")

func _input(event):
	if Input.is_action_just_pressed(input_event_that_will_activate):
		pressed.emit()
	
