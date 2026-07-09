extends Control

@export var options: Array
@export var require_apply: bool = false

signal option_changed

var current_selection = 0

func _ready():
	if require_apply:
		$HBoxContainer/Label2.visible = true
	else:
		$HBoxContainer/Label2.visible = false
		

func _setup(start_option, new_options = null):
	if new_options != null:
		options = new_options
	current_selection = start_option
	
	if options.is_empty():
		$HBoxContainer/Label.text = "0"
		return
	
	if options[start_option] is Vector2i:
		$HBoxContainer/Label.text = str(options[start_option].x) + " x " + str(options[start_option].y)
	else:
		$HBoxContainer/Label.text = options[start_option]
	
func _on_left_pressed(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if options.is_empty():
				return
			current_selection = (current_selection - 1) % options.size()
			option_changed.emit(options, current_selection)
			
			if options[current_selection] is Vector2i:
				$HBoxContainer/Label.text = str(options[current_selection].x) + " x " + str(options[current_selection].y)
			else:
				$HBoxContainer/Label.text = options[current_selection]
			
func _on_right_pressed(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if options.is_empty():
				return
			current_selection = (current_selection + 1) % options.size()
			option_changed.emit(options, current_selection)
			#print("CURRENT OPTION ", options[current_selection])
			if options[current_selection] is Vector2i:
				$HBoxContainer/Label.text = str(options[current_selection].x) + " x " + str(options[current_selection].y)
			else:
				$HBoxContainer/Label.text = options[current_selection]
