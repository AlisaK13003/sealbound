@tool
@icon("res://assets/icons/star_bubble.svg")

class_name DialogueSystemNode extends CanvasLayer

var is_active : bool = false

@onready var dialog_ui : Control = $DialogueUI

func _ready() -> void:
	if Engine.is_editor_hint():
		if get_viewport() is Window:
			get_parent().remove_child(self)
			return
		return

	if dialog_ui == null:
		push_error("DialogueSystemNode: Missing child node 'DialogueUI'.")
		return

	hide_dialog()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		if is_active == false:
			show_dialog()
		else:
			hide_dialog()

func show_dialog() -> void:
	if dialog_ui == null:
		return

	is_active = true
	dialog_ui.visible = true
	dialog_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func hide_dialog() -> void:
	if dialog_ui == null:
		return

	is_active = false
	dialog_ui.visible = false
	dialog_ui.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
