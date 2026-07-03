class_name CutsceneRunner
extends CanvasLayer

signal finished

var beats: Array = []
var beat_index: int = -1
var waiting_for_input: bool = false
var waiting_for_name: bool = false
var name_entry_default: String = "MC"
var has_finished: bool = false
var panel: Panel
var speaker_label: Label
var text_label: Label
var fade_rect: ColorRect
var choice_container: VBoxContainer
var name_row: HBoxContainer
var name_input: LineEdit
var name_submit_button: Button
var sfx_label: Label
var sfx_player: AudioStreamPlayer
var selected_choice_index: int = -1
var pending_choice_beat: Dictionary = {}

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func play(cutscene_path: String) -> void:
	has_finished = false
	var file = FileAccess.open(cutscene_path, FileAccess.READ)
	if file == null:
		push_warning("CutsceneRunner: Could not open %s." % cutscene_path)
		_end()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		beats = parsed.get("beats", [])
	elif parsed is Array:
		beats = parsed
	else:
		beats = []
	beat_index = -1
	visible = true
	Global.is_in_menu = true
	_advance()

func _input(event: InputEvent) -> void:
	if not visible or has_finished:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_BRACKETRIGHT:
		get_viewport().set_input_as_handled()
		skip_cutscene()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or has_finished:
		return
	if waiting_for_name and (event.is_action_pressed("Confirm") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		_submit_name_entry()
		return
	if not waiting_for_input:
		return
	if event.is_action_pressed("Confirm") or event.is_action_pressed("Mouse_Left_Click") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()

func _advance() -> void:
	if has_finished:
		return
	if visible:
		Global.is_in_menu = true
	waiting_for_input = false
	waiting_for_name = false
	_clear_interactive_controls()
	panel.visible = false
	beat_index += 1
	if beat_index >= beats.size():
		_end()
		return
	var beat = beats[beat_index]
	if not (beat is Dictionary):
		_advance()
		return

	match str(beat.get("type", "dialogue")):
		"dialogue":
			_show_dialogue(beat)
		"choice":
			_show_choice(beat)
		"name_entry":
			_show_name_entry(beat)
		"sfx":
			_play_sfx(beat)
		"objective":
			Global.current_tutorial_objective = str(beat.get("text", ""))
			_advance()
		"action":
			_run_action(str(beat.get("name", beat.get("action", ""))))
			_advance()
		"flag":
			Global.set_story_flag(str(beat.get("key", "")), bool(beat.get("value", true)))
			_advance()
		"fade":
			_play_fade(beat)
		"wait":
			var seconds = float(beat.get("duration", 0.5))
			await get_tree().create_timer(seconds).timeout
			if has_finished:
				return
			_advance()
		"scene_transition":
			Global.current_region = str(beat.get("region", Global.current_region))
			Global.current_loading_zone = str(beat.get("loading_zone", Global.current_loading_zone))
			_advance()
		"camera_focus", "move":
			_advance()
		_:
			_show_dialogue(beat)

func _show_dialogue(beat: Dictionary) -> void:
	var dialogue_system = get_dialogue_system()
	if dialogue_system != null and dialogue_system.has_method("show_cutscene_node"):
		pending_choice_beat = {}
		_connect_dialogue_closed(dialogue_system)
		dialogue_system.show_cutscene_node(_make_dialogue_node(beat))
		return

	speaker_label.text = _format_speaker(str(beat.get("speaker", "")))
	text_label.text = _format_text(str(beat.get("text", "")))
	panel.visible = true
	waiting_for_input = true

func _show_choice(beat: Dictionary) -> void:
	var dialogue_system = get_dialogue_system()
	if dialogue_system != null and dialogue_system.has_method("show_cutscene_node"):
		selected_choice_index = -1
		pending_choice_beat = beat
		var callback = Callable(self, "_on_dialogue_system_choice_selected")
		if not dialogue_system.dialogue_choice_selected.is_connected(callback):
			dialogue_system.dialogue_choice_selected.connect(callback, CONNECT_ONE_SHOT)
		_connect_dialogue_closed(dialogue_system)
		dialogue_system.show_cutscene_node(_make_choice_dialogue_node(beat))
		return

	speaker_label.text = _format_speaker(str(beat.get("speaker", "")))
	text_label.text = _format_text(str(beat.get("text", "")))
	panel.visible = true
	choice_container.visible = true
	var options: Array = beat.get("options", [])
	for option in options:
		if not (option is Dictionary):
			continue
		var button = Button.new()
		button.text = str(option.get("text", ""))
		button.custom_minimum_size = Vector2(0, 36)
		button.pressed.connect(_choose_option.bind(option))
		choice_container.add_child(button)

func _choose_option(option: Dictionary) -> void:
	var inserted_beats: Array = option.get("beats", [])
	for index in range(inserted_beats.size() - 1, -1, -1):
		beats.insert(beat_index + 1, inserted_beats[index])
	_advance()

func _on_dialogue_system_choice_selected(choice_index: int, _choice_data: Dictionary) -> void:
	selected_choice_index = choice_index

func _connect_dialogue_closed(dialogue_system: Node) -> void:
	var callback = Callable(self, "_on_dialogue_system_dialogue_closed")
	if not dialogue_system.dialogue_closed.is_connected(callback):
		dialogue_system.dialogue_closed.connect(callback, CONNECT_ONE_SHOT)

func _on_dialogue_system_dialogue_closed() -> void:
	if has_finished:
		return
	if not pending_choice_beat.is_empty():
		_insert_selected_choice_beats(pending_choice_beat)
		pending_choice_beat = {}
	if visible:
		call_deferred("_advance")

func _insert_selected_choice_beats(beat: Dictionary) -> void:
	if selected_choice_index < 0:
		return
	var options: Array = beat.get("options", [])
	if selected_choice_index >= options.size():
		return
	var option = options[selected_choice_index]
	if not (option is Dictionary):
		return
	var inserted_beats: Array = option.get("beats", [])
	for index in range(inserted_beats.size() - 1, -1, -1):
		beats.insert(beat_index + 1, inserted_beats[index])

func _show_name_entry(beat: Dictionary) -> void:
	name_entry_default = str(beat.get("default", "MC"))
	speaker_label.text = _format_speaker(str(beat.get("speaker", "")))
	text_label.text = str(beat.get("text", "Enter your name:"))
	name_input.text = ""
	name_input.placeholder_text = name_entry_default
	panel.visible = true
	name_row.visible = true
	waiting_for_name = true
	name_input.grab_focus()

func _submit_name_entry() -> void:
	var entered_name = name_input.text.strip_edges()
	if entered_name.is_empty():
		entered_name = "MC"
	Global.set_player_identity(entered_name, Global.player_gender)
	_advance()

func _format_text(raw_text: String) -> String:
	return raw_text.replace("{player_name}", Global.player_name)

func _format_speaker(raw_speaker: String) -> String:
	if raw_speaker == "MC":
		return Global.player_name
	return raw_speaker

func _make_dialogue_node(beat: Dictionary) -> Dictionary:
	var node = {
		"speaker": _format_speaker(str(beat.get("speaker", ""))),
		"text": _format_text(str(beat.get("text", ""))),
		"next": ""
	}
	_apply_portrait_data(node, beat)
	return node

func _make_choice_dialogue_node(beat: Dictionary) -> Dictionary:
	var node = _make_dialogue_node(beat)
	var dialogue_choices: Array = []
	var options: Array = beat.get("options", [])
	for option_index in range(options.size()):
		var option = options[option_index]
		if not (option is Dictionary):
			continue
		dialogue_choices.append({
			"text": str(option.get("text", "Choice")),
			"action": "cutscene_choice_%d" % option_index,
			"next": ""
		})
	node["choices"] = dialogue_choices
	return node

func _apply_portrait_data(node: Dictionary, beat: Dictionary) -> void:
	if beat.has("portrait_sheet"):
		node["portrait_sheet"] = str(beat["portrait_sheet"])
	if beat.has("portrait_frame"):
		node["portrait_frame"] = str(beat["portrait_frame"])
	if beat.has("portrait"):
		node["portrait_frame"] = str(beat["portrait"])
	if node.has("portrait_sheet") or node.has("portrait_frame"):
		return

	var raw_speaker = str(beat.get("speaker", ""))
	match raw_speaker:
		"MC":
			node["portrait_sheet"] = "res://GUI/dialogue_system/sprites/portraits/MCmale_portraits.png" if Global.player_gender == "male" else "res://GUI/dialogue_system/sprites/portraits/MCfemale_portraits.png"
			node["portrait_frame"] = "neutral"
		"Villager Girl", "Sera", "???":
			node["portrait_sheet"] = "res://GUI/dialogue_system/sprites/portraits/Sera_portraits.png"
			node["portrait_frame"] = "neutral"
		_:
			node["hide_portrait"] = true

func get_dialogue_system() -> Node:
	return get_node_or_null("/root/DialogueSystem")

func _play_sfx(beat: Dictionary) -> void:
	var stream_path = str(beat.get("path", ""))
	if not stream_path.is_empty():
		var stream = load(stream_path)
		if stream is AudioStream:
			sfx_player.stream = stream
			sfx_player.play()
	var caption = str(beat.get("caption", beat.get("text", "")))
	if not caption.is_empty():
		_show_sfx_caption(caption, float(beat.get("caption_duration", 1.8)))
	if bool(beat.get("blocking", false)):
		await get_tree().create_timer(float(beat.get("duration", 0.5))).timeout
		if has_finished:
			return
	_advance()

func _play_fade(beat: Dictionary) -> void:
	var direction = str(beat.get("direction", "in"))
	var duration = float(beat.get("duration", 0.35))
	var target_alpha = 1.0 if direction == "in" else 0.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", target_alpha, duration)
	await tween.finished
	if has_finished:
		return
	_advance()

func skip_cutscene() -> void:
	if has_finished:
		return

	_apply_remaining_state_beats()
	has_finished = true
	waiting_for_input = false
	waiting_for_name = false
	pending_choice_beat = {}
	selected_choice_index = -1

	var dialogue_system = get_dialogue_system()
	if dialogue_system != null and dialogue_system.has_method("hide_dialog"):
		dialogue_system.hide_dialog()

	_clear_interactive_controls()
	panel.visible = false
	sfx_label.visible = false
	if sfx_player.playing:
		sfx_player.stop()
	Global.set_player_identity(Global.player_name, Global.player_gender)
	Global.is_in_menu = false
	visible = false
	finished.emit()

func _apply_remaining_state_beats() -> void:
	var start_index = max(beat_index, 0)
	for index in range(start_index, beats.size()):
		var beat = beats[index]
		if not (beat is Dictionary):
			continue

		match str(beat.get("type", "dialogue")):
			"flag":
				Global.set_story_flag(str(beat.get("key", "")), bool(beat.get("value", true)))
			"objective":
				Global.current_tutorial_objective = str(beat.get("text", ""))
			"action":
				_run_action(str(beat.get("name", beat.get("action", ""))))
			"scene_transition":
				Global.current_region = str(beat.get("region", Global.current_region))
				Global.current_loading_zone = str(beat.get("loading_zone", Global.current_loading_zone))
			"name_entry":
				if Global.player_name.strip_edges().is_empty():
					Global.set_player_identity("MC", Global.player_gender)

func _run_action(action_name: String) -> void:
	match action_name:
		"start_lyra_axe_quest":
			Global.start_lyra_axe_quest()

func _end() -> void:
	if has_finished:
		return
	has_finished = true
	Global.is_in_menu = false
	visible = false
	finished.emit()

func _clear_interactive_controls() -> void:
	for child in choice_container.get_children():
		child.queue_free()
	choice_container.visible = false
	name_row.visible = false

func _show_sfx_caption(caption: String, duration: float) -> void:
	sfx_label.text = caption
	sfx_label.visible = true
	await get_tree().create_timer(duration).timeout
	if sfx_label.text == caption:
		sfx_label.visible = false

func _build_ui() -> void:
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 0)
	add_child(fade_rect)

	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

	sfx_label = Label.new()
	sfx_label.visible = false
	sfx_label.anchor_left = 0.08
	sfx_label.anchor_top = 0.0
	sfx_label.anchor_right = 0.92
	sfx_label.anchor_bottom = 0.0
	sfx_label.offset_left = 0
	sfx_label.offset_top = 28
	sfx_label.offset_right = 0
	sfx_label.offset_bottom = 64
	sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sfx_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sfx_label.add_theme_font_size_override("font_size", 16)
	add_child(sfx_label)

	panel = Panel.new()
	panel.anchor_left = 0.06
	panel.anchor_top = 1.0
	panel.anchor_right = 0.94
	panel.anchor_bottom = 1.0
	panel.offset_left = 0
	panel.offset_top = -170
	panel.offset_right = 0
	panel.offset_bottom = -24
	panel.visible = false
	add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 22)
	column.add_child(speaker_label)

	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 18)
	column.add_child(text_label)

	choice_container = VBoxContainer.new()
	choice_container.visible = false
	choice_container.add_theme_constant_override("separation", 6)
	column.add_child(choice_container)

	name_row = HBoxContainer.new()
	name_row.visible = false
	name_row.add_theme_constant_override("separation", 8)
	column.add_child(name_row)

	name_input = LineEdit.new()
	name_input.max_length = 16
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_input)

	name_submit_button = Button.new()
	name_submit_button.text = "OK"
	name_submit_button.pressed.connect(_submit_name_entry)
	name_row.add_child(name_submit_button)
