@tool
@icon("res://assets/icons/star_bubble.svg")

class_name DialogueSystemNode extends CanvasLayer

signal dialogue_closed

var is_active : bool = false
var dialogue_data: Dictionary = {}
var dialogue_nodes: Dictionary = {}
var current_node_id: String = ""
var is_typing: bool = false
var typewriter_timer: float = 0.0
var typewriter_delay: float = 0.03
var current_text_character_count: int = 0
var current_node_has_choices: bool = false
var current_choices: Array = []

const PORTRAIT_EMOTION_FRAMES: Dictionary = {
	"neutral": 0,
	"smile": 1,
	"awkward": 2,
	"sad": 3,
}

@export var dialogue_file_path: String = "res://assets/Resources/NPC Stuff/Dialogue Stuff/Test_Dialogue.json"

@onready var dialog_ui : Control = $DialogueUI
@onready var speaker_label: Label = get_node_or_null("DialogueUI/NameLabel")
@onready var body_text: RichTextLabel = get_node_or_null("DialogueUI/TextBoxContainer/BodyText")
@onready var fallback_body_text: RichTextLabel = get_node_or_null("DialogueUI/PanelContainer/RichTextLabel")
@onready var portrait_node: Node = get_node_or_null("DialogueUI/Portrait")
@onready var fallback_portrait_node: Node = get_node_or_null("DialogueUI/Sprite2D")
@onready var choices_container: Control = get_node_or_null("DialogueUI/ChoicesContainer")
@onready var choice_buttons: Array[Button] = [
	get_node_or_null("DialogueUI/ChoicesContainer/Choice1"),
	get_node_or_null("DialogueUI/ChoicesContainer/Choice2"),
	get_node_or_null("DialogueUI/ChoicesContainer/Choice3"),
]

func _ready() -> void:
	if Engine.is_editor_hint():
		if get_viewport() is Window:
			get_parent().remove_child(self)
			return
		return

	if dialog_ui == null:
		push_error("DialogueSystemNode: Missing child node 'DialogueUI'.")
		return

	for index in range(choice_buttons.size()):
		var choice_button: Button = choice_buttons[index]
		if choice_button == null:
			continue
		choice_button.process_mode = Node.PROCESS_MODE_ALWAYS
		choice_button.mouse_filter = Control.MOUSE_FILTER_STOP
		choice_button.self_modulate = Color(1, 1, 1, 1)
		var callback := Callable(self, "_on_choice_button_pressed").bind(index)
		if not choice_button.pressed.is_connected(callback):
			choice_button.pressed.connect(callback)

		var hover_entered := Callable(self, "_on_choice_button_mouse_entered").bind(index)
		if not choice_button.mouse_entered.is_connected(hover_entered):
			choice_button.mouse_entered.connect(hover_entered)

		var hover_exited := Callable(self, "_on_choice_button_mouse_exited").bind(index)
		if not choice_button.mouse_exited.is_connected(hover_exited):
			choice_button.mouse_exited.connect(hover_exited)

		var gui_input_callback := Callable(self, "_on_choice_button_gui_input").bind(index)
		if not choice_button.gui_input.is_connected(gui_input_callback):
			choice_button.gui_input.connect(gui_input_callback)

	hide_dialog()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		if event.is_action_pressed("test"):
			show_dialog()
		return

	if event.is_action_pressed("Open Menu") or event.is_action_pressed("Mouse_Left_Click"):
		advance_dialogue()

func _process(delta: float) -> void:
	if not is_active or not is_typing:
		return

	typewriter_timer += delta
	if typewriter_timer < typewriter_delay:
		return

	typewriter_timer = 0.0
	var text_label := get_active_body_text()
	if text_label == null:
		is_typing = false
		return

	if text_label.visible_characters < current_text_character_count:
		text_label.visible_characters += 1

	if text_label.visible_characters >= current_text_character_count:
		finish_typewriter()

func show_dialog() -> void:
	if dialog_ui == null:
		return

	if not load_dialogue_file(dialogue_file_path):
		return

	is_active = true
	dialog_ui.visible = true
	dialog_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	Global.is_in_menu = true
	get_tree().paused = true
	show_node(dialogue_data.get("start", ""))

func hide_dialog() -> void:
	if dialog_ui == null:
		return

	is_active = false
	dialog_ui.visible = false
	dialog_ui.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	current_node_id = ""
	is_typing = false
	typewriter_timer = 0.0
	current_text_character_count = 0
	if speaker_label != null:
		speaker_label.text = ""
	var text_label := get_active_body_text()
	if text_label != null:
		text_label.text = ""
		text_label.visible_characters = -1
	set_choices_visible(false)
	Global.is_in_menu = false
	dialogue_closed.emit()

func load_dialogue_file(path: String) -> bool:
	if path.is_empty():
		push_error("DialogueSystemNode: dialogue_file_path is empty.")
		return false

	if not FileAccess.file_exists(path):
		push_error("DialogueSystemNode: Dialogue file not found: %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueSystemNode: Could not open dialogue file: %s" % path)
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("DialogueSystemNode: Dialogue file is not valid JSON: %s" % path)
		return false

	dialogue_data = parsed
	dialogue_nodes = dialogue_data.get("nodes", {})
	if typeof(dialogue_nodes) != TYPE_DICTIONARY:
		push_error("DialogueSystemNode: 'nodes' must be a dictionary in %s" % path)
		return false

	return true

func show_node(node_id: String) -> void:
	if node_id.is_empty():
		return

	if not dialogue_nodes.has(node_id):
		push_error("DialogueSystemNode: Missing dialogue node: %s" % node_id)
		hide_dialog()
		return

	current_node_id = node_id
	var node_data: Dictionary = dialogue_nodes[node_id]
	is_typing = false
	typewriter_timer = 0.0
	current_text_character_count = 0
	current_node_has_choices = false
	current_choices = []

	if speaker_label != null:
		speaker_label.text = str(node_data.get("speaker", ""))

	var text_label := get_active_body_text()
	if text_label != null:
		text_label.text = str(node_data.get("text", ""))
		text_label.visible_characters = 0
		current_text_character_count = text_label.get_total_character_count()
		is_typing = current_text_character_count > 0
		if not is_typing:
			text_label.visible_characters = -1

	update_portrait(node_data)
	update_choices(node_data)
	if not is_typing and current_node_has_choices:
		show_choices()

func advance_dialogue() -> void:
	if is_typing:
		finish_typewriter()
		return

	if current_node_has_choices:
		return

	if current_node_id.is_empty():
		hide_dialog()
		return

	var node_data: Dictionary = dialogue_nodes.get(current_node_id, {})
	if node_data.is_empty():
		hide_dialog()
		return

	var next_node: String = str(node_data.get("next", ""))
	if next_node.is_empty():
		hide_dialog()
		return

	show_node(next_node)

func finish_typewriter() -> void:
	is_typing = false
	typewriter_timer = 0.0
	var text_label := get_active_body_text()
	if text_label != null:
		text_label.visible_characters = -1

	if current_node_has_choices:
		show_choices()

func get_active_body_text() -> RichTextLabel:
	if body_text != null:
		return body_text
	return fallback_body_text

func update_portrait(node_data: Dictionary) -> void:
	var portrait_target: Node = portrait_node if portrait_node != null else fallback_portrait_node
	if portrait_target == null:
		return

	var portrait_name: String = str(node_data.get("portrait_frame", node_data.get("portrait", ""))).strip_edges().to_lower()
	if portrait_target is Sprite2D:
		if portrait_name.is_valid_int():
			portrait_target.frame = int(portrait_name)
		elif PORTRAIT_EMOTION_FRAMES.has(portrait_name):
			portrait_target.frame = int(PORTRAIT_EMOTION_FRAMES[portrait_name])

func set_choices_visible(is_visible: bool) -> void:
	if choices_container != null:
		choices_container.visible = is_visible

func update_choices(node_data: Dictionary) -> void:
	current_node_has_choices = false
	current_choices = []

	var choices = node_data.get("choices", [])
	if typeof(choices) != TYPE_ARRAY:
		set_choices_visible(false)
		return

	current_choices = choices
	current_node_has_choices = current_choices.size() > 0
	for index in range(choice_buttons.size()):
		var choice_button: Button = choice_buttons[index]
		if choice_button == null:
			continue

		if index < current_choices.size():
			var choice_data: Dictionary = current_choices[index]
			choice_button.text = str(choice_data.get("text", "Choice"))
			choice_button.visible = true
			choice_button.disabled = false
		else:
			choice_button.visible = false

	set_choices_visible(false)



func show_choices() -> void:
	set_choices_visible(true)

func _on_choice_button_pressed(choice_index: int) -> void:
	print("choice pressed:", choice_index)
	print("current choices:", current_choices)

	if choice_index < 0 or choice_index >= current_choices.size():
		print("choice index out of range")
		return

	var choice_data: Dictionary = current_choices[choice_index]
	var next_node: String = str(choice_data.get("next", ""))
	print("next node:", next_node)

	if next_node.is_empty():
		print("no next node, closing dialogue")
		hide_dialog()
		return

	set_choices_visible(false)
	show_node(next_node)

func _on_choice_button_mouse_entered(choice_index: int) -> void:
	var choice_button: Button = choice_buttons[choice_index]
	if choice_button == null:
		return

	choice_button.self_modulate = Color(1, 0.9, 0.55, 1)
	print("hover entered:", choice_button.name)

func _on_choice_button_mouse_exited(choice_index: int) -> void:
	var choice_button: Button = choice_buttons[choice_index]
	if choice_button == null:
		return

	choice_button.self_modulate = Color(1, 1, 1, 1)
	print("hover exited:", choice_button.name)

func _on_choice_button_gui_input(event: InputEvent, choice_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("button gui_input left click:", choice_buttons[choice_index].name)
