@tool
@icon("res://GUI/dialogue_system/icons/star_bubble.svg")

class_name DialogueSystemNode extends CanvasLayer

signal dialogue_closed
signal choice_action_requested(action: String, choice_data: Dictionary)
signal dialogue_choice_selected(choice_index: int, choice_data: Dictionary)

var is_active : bool = false
var dialogue_data: Dictionary = {}
var dialogue_nodes: Dictionary = {}
var current_node_id: String = ""
var is_typing: bool = false
var typewriter_timer: float = 0.0
var typewriter_base_delay: float = 0.03
var typewriter_current_delay: float = 0.03
var punctuation_hard_pause: float = 0.6
var punctuation_soft_pause: float = 0.3
var current_text_character_count: int = 0
var current_node_has_choices: bool = false
var current_choices: Array = []
var ignore_next_input: bool = false
var dialogue_start_node_id: String = ""
var dialogue_context: Dictionary = {}
var is_cutscene_inline_mode: bool = false

const CHOICE_MIN_WIDTH: float = 96.0
const CHOICE_MAX_WIDTH: float = 379.0
const CHOICE_TEXT_PADDING: float = 56.0

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
	_find_choice_button(1),
	_find_choice_button(2),
	_find_choice_button(3),
]

func _find_choice_button(index: int) -> Button:
	var wrapped_path := "DialogueUI/ChoicesContainer/PanelContainer%d/Choice%d" % [index, index]
	var wrapped_button: Button = get_node_or_null(wrapped_path)
	if wrapped_button != null:
		return wrapped_button

	var legacy_path := "DialogueUI/ChoicesContainer/Choice%d" % index
	return get_node_or_null(legacy_path)

func _ready() -> void:
	if Engine.is_editor_hint():
		if get_viewport() is Window:
			get_parent().remove_child(self)
			return
		return
		
		process_mode = Node.PROCESS_MODE_ALWAYS  # add this line

	if dialog_ui == null:
		push_error("DialogueSystemNode: Missing child node 'DialogueUI'.")
		return

	for index in range(choice_buttons.size()):
		var choice_button: Button = choice_buttons[index]
		if choice_button == null:
			continue
		choice_button.process_mode = Node.PROCESS_MODE_ALWAYS
		choice_button.mouse_filter = Control.MOUSE_FILTER_STOP
		choice_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice_button.clip_text = true
		choice_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var callback := Callable(self, "_on_choice_button_pressed").bind(index)
		if not choice_button.pressed.is_connected(callback):
			choice_button.pressed.connect(callback)

	hide_dialog()
	

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if ignore_next_input and is_dialogue_input_event(event):
		ignore_next_input = false
		get_viewport().set_input_as_handled()
		return

	if is_close_dialogue_event(event):
		hide_dialog()
		get_viewport().set_input_as_handled()
		return

	if is_advance_dialogue_event(event):
		handle_dialogue_advance_input()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if ignore_next_input:
		ignore_next_input = false
		return

	if not is_active:
		if event.is_action_pressed("test"):
			show_dialog()
		return

	if is_close_dialogue_event(event):
		hide_dialog()
		get_viewport().set_input_as_handled()
		return

	if Global.get_input_mapping("confirm") or event.is_action_pressed("Mouse_Left_Click"):
		if current_node_has_choices and not is_typing:
			# Manually check if click hit a choice button
			var mouse_pos := get_viewport().get_mouse_position()
			for index in range(choice_buttons.size()):
				var btn: Button = choice_buttons[index]
				if btn != null and btn.visible and not btn.disabled and btn.get_global_rect().has_point(mouse_pos):
					_on_choice_button_pressed(index)
					get_viewport().set_input_as_handled()
					return
			# Clicked but missed all buttons — do nothing
			return
		advance_dialogue()

func is_close_dialogue_event(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel") or event.is_action_pressed("Pause") or event.is_action_pressed("Exit Menu")

func is_advance_dialogue_event(event: InputEvent) -> bool:
	return event.is_action_pressed("confirm") or event.is_action_pressed("Mouse_Left_Click") or event.is_action_pressed("ui_accept")

func is_dialogue_input_event(event: InputEvent) -> bool:
	return is_close_dialogue_event(event) or is_advance_dialogue_event(event)

func handle_dialogue_advance_input() -> void:
	if current_node_has_choices and not is_typing:
		var mouse_pos := get_viewport().get_mouse_position()
		for index in range(choice_buttons.size()):
			var btn: Button = choice_buttons[index]
			if btn != null and btn.visible and not btn.disabled and btn.get_global_rect().has_point(mouse_pos):
				_on_choice_button_pressed(index)
				return
		return
	advance_dialogue()

func _process(delta: float) -> void:
	if not is_active or not is_typing:
		return

	typewriter_timer += delta
	if typewriter_timer < typewriter_current_delay:
		return

	typewriter_timer = 0.0
	var text_label := get_active_body_text()
	if text_label == null:
		is_typing = false
		return

	if text_label.visible_characters < current_text_character_count:
		text_label.visible_characters += 1
		typewriter_current_delay = typewriter_base_delay + _get_character_pause(text_label, text_label.visible_characters - 1)

	if text_label.visible_characters >= current_text_character_count:
		finish_typewriter()

func show_dialog() -> bool:
	if dialog_ui == null:
		return false

	is_cutscene_inline_mode = false
	if not load_dialogue_file(dialogue_file_path):
		return false

	activate_dialogue_ui()
	var start_node = dialogue_start_node_id.strip_edges()
	if start_node.is_empty():
		start_node = str(dialogue_data.get("start", ""))
	show_node(start_node)
	return is_active

func show_cutscene_node(node_data: Dictionary) -> bool:
	if dialog_ui == null:
		return false

	is_cutscene_inline_mode = true
	dialogue_data = {
		"start": "__cutscene",
		"nodes": {
			"__cutscene": node_data
		}
	}
	dialogue_nodes = dialogue_data["nodes"]
	dialogue_start_node_id = "__cutscene"
	activate_dialogue_ui(false)
	show_node("__cutscene")
	return is_active

func activate_dialogue_ui(ignore_initial_input: bool = true) -> void:
	is_active = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_ui.visible = true
	dialog_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	Global.is_in_menu = true
	get_tree().paused = true
	ignore_next_input = ignore_initial_input

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
	typewriter_current_delay = typewriter_base_delay
	current_text_character_count = 0
	ignore_next_input = false
	dialogue_start_node_id = ""
	dialogue_context = {}
	is_cutscene_inline_mode = false
	if speaker_label != null:
		speaker_label.text = ""
	var text_label := get_active_body_text()
	if text_label != null:
		text_label.text = ""
		text_label.visible_characters = -1
	set_choices_visible(false)
	Global.is_in_menu = false
	dialogue_closed.emit()
	process_mode = Node.PROCESS_MODE_INHERIT

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

	var node_data: Dictionary = dialogue_nodes[node_id]
	var bond_random_next: Variant = node_data.get("bond_random_next", {})
	if typeof(bond_random_next) == TYPE_DICTIONARY:
		var bond_tier = str(dialogue_context.get("bond_tier", ""))
		var possible_next: Variant = bond_random_next.get(bond_tier, bond_random_next.get("default", []))
		if typeof(possible_next) == TYPE_ARRAY and possible_next.size() > 0:
			show_node(str(possible_next.pick_random()))
			return

	var random_next: Variant = node_data.get("random_next", [])
	if typeof(random_next) == TYPE_ARRAY and random_next.size() > 0:
		show_node(str(random_next.pick_random()))
		return

	current_node_id = node_id
	is_typing = false
	typewriter_timer = 0.0
	typewriter_current_delay = typewriter_base_delay
	current_text_character_count = 0
	current_node_has_choices = false
	current_choices = []

	var speaker_name := str(node_data.get("speaker", ""))
	if speaker_name == "MC":
		speaker_name = Global.player_name
	if speaker_label != null:
		speaker_label.text = speaker_name

	var text_label := get_active_body_text()
	if text_label != null:
		text_label.text = str(node_data.get("text", "")).replace("{player_name}", Global.player_name)
		text_label.visible_characters = 0
		current_text_character_count = text_label.get_total_character_count()
		typewriter_current_delay = typewriter_base_delay
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
	typewriter_current_delay = typewriter_base_delay
	var text_label := get_active_body_text()
	if text_label != null:
		text_label.visible_characters = -1

	if current_node_has_choices:
		show_choices()

func get_active_body_text() -> RichTextLabel:
	if body_text != null:
		return body_text
	return fallback_body_text

func _get_character_pause(text_label: RichTextLabel, character_index: int) -> float:
	if text_label == null or character_index < 0:
		return 0.0

	var parsed_text := text_label.get_parsed_text()
	if character_index >= parsed_text.length():
		return 0.0

	var character := parsed_text.substr(character_index, 1)
	if character == "." or character == "!" or character == "?":
		return punctuation_hard_pause
	if character == "," or character == "-":
		return punctuation_soft_pause

	return 0.0

func update_portrait(node_data: Dictionary) -> void:
	var portrait_target: Node = portrait_node if portrait_node != null else fallback_portrait_node
	if portrait_target == null:
		return

	if bool(node_data.get("hide_portrait", false)):
		if portrait_target is CanvasItem:
			portrait_target.visible = false
		return

	if portrait_target is CanvasItem:
		portrait_target.visible = true

	var portrait_sheet_path: String = str(node_data.get("portrait_sheet", "")).strip_edges()
	if str(node_data.get("speaker", "")) == "MC":
		portrait_sheet_path = Global.get_player_portrait_sheet()
	if portrait_sheet_path != "" and portrait_target is Sprite2D:
		var portrait_texture := load(portrait_sheet_path)
		if portrait_texture is Texture2D:
			portrait_target.texture = portrait_texture

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
			choice_button.disabled = is_choice_disabled(choice_data)
			if choice_button.disabled and bool(choice_data.get("daily_talk_bond", false)):
				choice_button.text = "%s (Done)" % choice_button.text
		else:
			choice_button.visible = false

	update_choice_container_width()
	set_choices_visible(false)

func is_choice_disabled(choice_data: Dictionary) -> bool:
	if bool(choice_data.get("daily_talk_bond", false)):
		return not bool(dialogue_context.get("can_daily_talk", true))
	return false

func update_choice_container_width() -> void:
	if choices_container == null:
		return

	var widest_text_width: float = 0.0
	for index in range(choice_buttons.size()):
		var choice_button: Button = choice_buttons[index]
		if choice_button == null or not choice_button.visible:
			continue

		var font := choice_button.get_theme_font("font")
		var font_size := choice_button.get_theme_font_size("font_size")
		if font != null:
			widest_text_width = max(widest_text_width, font.get_string_size(choice_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)

	var desired_width: float = clampf(widest_text_width + CHOICE_TEXT_PADDING, CHOICE_MIN_WIDTH, CHOICE_MAX_WIDTH)
	choices_container.offset_left = choices_container.offset_right - desired_width



func show_choices() -> void:
	set_choices_visible(true)

func _on_choice_button_pressed(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= current_choices.size():
		return
	if choice_index < choice_buttons.size():
		var choice_button: Button = choice_buttons[choice_index]
		if choice_button != null and choice_button.disabled:
			return

	var choice_data: Dictionary = current_choices[choice_index]
	dialogue_choice_selected.emit(choice_index, choice_data)
	var action: String = str(choice_data.get("action", "")).strip_edges()
	if not action.is_empty() or choice_data.has("bond_delta") or bool(choice_data.get("daily_talk_bond", false)):
		choice_action_requested.emit(action, choice_data)

	var next_node: String = str(choice_data.get("next", ""))

	if next_node.is_empty():
		hide_dialog()
		return

	set_choices_visible(false)
	show_node(next_node)
