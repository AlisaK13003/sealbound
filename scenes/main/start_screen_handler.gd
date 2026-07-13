extends Control

const OPENING_FOREST_CUTSCENE_SCENE = "res://scenes/cutscenes/OpeningForestCutscene.tscn"
const FEMALE_PORTRAIT_SHEET = "res://GUI/dialogue_system/sprites/portraits/MCfemale_portraits.png"
const MALE_PORTRAIT_SHEET = "res://GUI/dialogue_system/sprites/portraits/MCmale_portraits.png"
const PORTRAIT_FRAME_NEUTRAL = 0
const PORTRAIT_FRAME_SMILE = 1
const SELECTION_BORDER_COLOR = Color(0.25, 0.12, 0.05, 1.0)
const SELECTION_BORDER_WIDTH = 2

var main_menu: Control
var setup_panel: Control
var load_panel: Control
var arrow: TextureRect
var gender_options: OptionButton
var selected_gender: String = ""
var new_game_button: BaseButton
var load_button: BaseButton
var settings_button: BaseButton
var exit_button: BaseButton
var credits_button: BaseButton
var female_choice_button: BaseButton
var male_choice_button: BaseButton
var female_choice_highlight: CanvasItem
var male_choice_highlight: CanvasItem
var female_portrait: TextureRect
var male_portrait: TextureRect
var start_button: BaseButton
var start_button_background: CanvasItem
var start_button_label: CanvasItem
var setup_title_back_button: BaseButton
var setup_back_button: BaseButton
var load_back_button: BaseButton
var save_load_menu: Node
var menu_buttons: Array[BaseButton] = []

func _ready() -> void:
	Fade.fade_out(0.0)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_editor_nodes()
	_configure_load_menu()
	_connect_editor_buttons()
	_setup_menu_arrow()
	_show_main_menu()
	Global.time_paused = true


func _on_button_pressed() -> void:
	_start_game_without_cutscene()

func _cache_editor_nodes() -> void:
	main_menu = get_node_or_null("UI/Menu") as Control
	setup_panel = get_node_or_null("SetupPanel") as Control
	load_panel = get_node_or_null("LoadPanel") as Control
	arrow = get_node_or_null("UI/Menu/Arrow") as TextureRect
	gender_options = get_node_or_null("SetupPanel/MarginContainer/SetupColumn/GenderOptions") as OptionButton
	new_game_button = get_node_or_null("UI/Menu/VBoxContainer/NewGameButton") as BaseButton
	load_button = get_node_or_null("UI/Menu/VBoxContainer/LoadButton") as BaseButton
	settings_button = get_node_or_null("UI/Menu/VBoxContainer/SettingsButton") as BaseButton
	exit_button = get_node_or_null("UI/Menu/VBoxContainer/ExitButton") as BaseButton
	credits_button = get_node_or_null("UI/Menu/VBoxContainer/CreditsButton") as BaseButton
	female_choice_button = _first_button([
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoices/FemaleChoiceButton",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoiceWrapper/CharacterChoices/FemaleChoiceButton",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoicesWrapper/CharacterChoices/FemaleChoiceButton"
	])
	male_choice_button = _first_button([
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoices/MaleChoiceButton",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoiceWrapper/CharacterChoices/MaleChoiceButton",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoicesWrapper/CharacterChoices/MaleChoiceButton"
	])
	female_choice_highlight = _first_canvas_item([
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoices/FemaleChoiceButton/SelectionBorder",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoiceWrapper/CharacterChoices/FemaleChoiceButton/SelectionBorder",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoicesWrapper/CharacterChoices/FemaleChoiceButton/SelectionBorder"
	])
	male_choice_highlight = _first_canvas_item([
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoices/MaleChoiceButton/SelectionBorder",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoiceWrapper/CharacterChoices/MaleChoiceButton/SelectionBorder",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoicesWrapper/CharacterChoices/MaleChoiceButton/SelectionBorder"
	])
	female_portrait = _first_texture_rect([
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoices/FemaleChoiceButton/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoices/FemaleChoiceButton/PortraitCenter/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoiceWrapper/CharacterChoices/FemaleChoiceButton/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoiceWrapper/CharacterChoices/FemaleChoiceButton/PortraitCenter/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoicesWrapper/CharacterChoices/FemaleChoiceButton/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoicesWrapper/CharacterChoices/FemaleChoiceButton/PortraitCenter/Portrait"
	])
	male_portrait = _first_texture_rect([
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoices/MaleChoiceButton/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoices/MaleChoiceButton/PortraitCenter/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoiceWrapper/CharacterChoices/MaleChoiceButton/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoiceWrapper/CharacterChoices/MaleChoiceButton/PortraitCenter/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoicesWrapper/CharacterChoices/MaleChoiceButton/Portrait",
		"SetupPanel/MarginContainer/SetupColumn/CharacterChoicesWrapper/CharacterChoices/MaleChoiceButton/PortraitCenter/Portrait"
	])
	start_button = get_node_or_null("SetupPanel/MarginContainer/SetupColumn/SetupButtons/StartButton") as BaseButton
	start_button_background = get_node_or_null("SetupPanel/MarginContainer/SetupColumn/SetupButtons/StartButton/Background") as CanvasItem
	start_button_label = get_node_or_null("SetupPanel/MarginContainer/SetupColumn/SetupButtons/StartButton/Label") as CanvasItem
	setup_title_back_button = _first_button([
		"SetupPanel/MarginContainer/SetupColumn/TitleRow/SetupBackButton",
		"SetupPanel/MarginContainer/SetupColumn/TitleRow/BackButton"
	])
	setup_back_button = _first_button([
		"SetupPanel/MarginContainer/SetupColumn/TitleRow/SetupBackButton",
		"SetupPanel/MarginContainer/SetupColumn/TitleRow/BackButton",
		"SetupPanel/MarginContainer/SetupColumn/TitleRow/Button",
		"SetupPanel/MarginContainer/SetupColumn/SetupButtons/SetupBackButton"
	])
	load_back_button = _first_button([
		"LoadPanel/MarginContainer/LoadRow/BackButton",
		"LoadPanel/MarginContainer/LoadRow/LoadBackButton",
		"LoadPanel/MarginContainer/LoadColumn/LoadBackButton"
	])
	save_load_menu = _first_node([
		"LoadPanel/MarginContainer/LoadRow/SaveLoadMenu",
		"LoadPanel/MarginContainer/LoadColumn/SaveLoadMenu"
	])
	menu_buttons = [
		new_game_button,
		load_button,
		settings_button,
		exit_button,
		credits_button
	]

func _configure_load_menu() -> void:
	if gender_options != null and gender_options.item_count == 0:
		gender_options.add_item("Female", 0)
		gender_options.add_item("Male", 1)
	if save_load_menu != null:
		save_load_menu.set("start_in_load_mode", true)
		save_load_menu.set("allow_saving", false)
		save_load_menu.set("show_delete", true)
		if save_load_menu.has_method("refresh_slots"):
			save_load_menu.refresh_slots()
	_configure_character_choices()

func _connect_editor_buttons() -> void:
	_connect_button(new_game_button, _show_new_game)
	_connect_button(load_button, _show_load_game)
	_connect_button(exit_button, _quit_game)
	_connect_button(female_choice_button, _select_character.bind("female"))
	_connect_button(male_choice_button, _select_character.bind("male"))
	_connect_button(start_button, _begin_new_game)
	_connect_button(setup_title_back_button, _show_main_menu)
	_connect_button(setup_back_button, _show_main_menu)
	_connect_button(load_back_button, _show_main_menu)

func _connect_button(button: BaseButton, callback: Callable) -> void:
	if button == null:
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _first_button(paths: Array[String]) -> BaseButton:
	for path in paths:
		var button = get_node_or_null(path) as BaseButton
		if button != null:
			return button
	return null

func _first_canvas_item(paths: Array[String]) -> CanvasItem:
	for path in paths:
		var item = get_node_or_null(path) as CanvasItem
		if item != null:
			return item
	return null

func _first_texture_rect(paths: Array[String]) -> TextureRect:
	for path in paths:
		var texture_rect = get_node_or_null(path) as TextureRect
		if texture_rect != null:
			return texture_rect
	return null

func _first_node(paths: Array[String]) -> Node:
	for path in paths:
		var node = get_node_or_null(path)
		if node != null:
			return node
	return null

func _configure_character_choices() -> void:
	_prepare_choice_button(female_choice_button)
	_prepare_choice_button(male_choice_button)
	_prepare_selection_border(female_choice_highlight)
	_prepare_selection_border(male_choice_highlight)
	_prepare_start_button()
	_set_character_choice_state("", false)
	_set_start_button_available(false)

func _prepare_start_button() -> void:
	if start_button == null:
		return
	start_button.disabled = false
	start_button.text = ""

func _prepare_choice_button(button: BaseButton) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _prepare_selection_border(border: CanvasItem) -> void:
	if border == null:
		return
	border.visible = false
	border.z_index = 10

	if border is Control:
		var border_control := border as Control
		border_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		border_control.offset_left = -2.0
		border_control.offset_top = -2.0
		border_control.offset_right = 2.0
		border_control.offset_bottom = 2.0

	if border is Panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0, 0, 0, 0)
		style_box.border_color = SELECTION_BORDER_COLOR
		style_box.set_border_width_all(SELECTION_BORDER_WIDTH)
		(border as Panel).add_theme_stylebox_override("panel", style_box)

func _select_character(gender: String) -> void:
	selected_gender = gender
	_set_character_choice_state(gender, true)
	_set_start_button_available(true)
	if start_button != null:
		start_button.grab_focus()

func _set_character_choice_state(gender: String, has_selection: bool) -> void:
	var female_selected = has_selection and gender == "female"
	var male_selected = has_selection and gender == "male"

	if female_choice_highlight != null:
		female_choice_highlight.visible = female_selected
	if male_choice_highlight != null:
		male_choice_highlight.visible = male_selected

	_set_portrait_frame(female_portrait, FEMALE_PORTRAIT_SHEET, PORTRAIT_FRAME_SMILE if female_selected else PORTRAIT_FRAME_NEUTRAL)
	_set_portrait_frame(male_portrait, MALE_PORTRAIT_SHEET, PORTRAIT_FRAME_SMILE if male_selected else PORTRAIT_FRAME_NEUTRAL)

func _set_start_button_available(is_available: bool) -> void:
	if start_button == null:
		return
	start_button.disabled = false
	start_button.focus_mode = Control.FOCUS_ALL if is_available else Control.FOCUS_NONE
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_available else Control.CURSOR_ARROW

	var alpha := 1.0 if is_available else 0.55
	if start_button_background != null:
		start_button_background.modulate.a = alpha
	if start_button_label != null:
		start_button_label.modulate.a = alpha

func _set_portrait_frame(portrait: TextureRect, sheet_path: String, frame_index: int) -> void:
	if portrait == null:
		return
	var sheet = load(sheet_path) as Texture2D
	if sheet == null:
		return

	var frame_width = sheet.get_width() / 4.0
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = sheet
	atlas_texture.region = Rect2(frame_width * frame_index, 0.0, frame_width, sheet.get_height())
	portrait.texture = atlas_texture

func _setup_menu_arrow() -> void:
	if arrow == null:
		return

	arrow.visible = false
	for button in menu_buttons:
		if button == null:
			continue
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_entered.connect(_move_arrow_to_button.bind(button))
		button.focus_entered.connect(_move_arrow_to_button.bind(button))

func _move_arrow_to_first_visible_button() -> void:
	for button in menu_buttons:
		if button != null and button.visible and button.is_inside_tree():
			_move_arrow_to_button(button)
			return
	if arrow != null:
		arrow.visible = false

func _move_arrow_to_button(button: Control) -> void:
	if arrow == null or button == null or not button.is_inside_tree():
		return

	var menu := arrow.get_parent() as Control
	if menu == null:
		return

	var button_position: Vector2 = menu.get_global_transform().affine_inverse() * button.global_position
	var arrow_position: Vector2 = Vector2(
		button_position.x - arrow.size.x + 8.0,
		button_position.y + button.size.y * 0.5 - arrow.size.y * 0.5
	)

	arrow.visible = true
	arrow.position = arrow_position

func _show_main_menu() -> void:
	if main_menu != null:
		main_menu.visible = true
	if setup_panel != null:
		setup_panel.visible = false
	if load_panel != null:
		load_panel.visible = false
	call_deferred("_move_arrow_to_first_visible_button")

func _show_new_game() -> void:
	selected_gender = ""
	_set_character_choice_state("", false)
	if main_menu != null:
		main_menu.visible = false
	if setup_panel != null:
		setup_panel.visible = true
	if load_panel != null:
		load_panel.visible = false
	if arrow != null:
		arrow.visible = false
	if start_button != null:
		_set_start_button_available(false)

func _show_load_game() -> void:
	if main_menu != null:
		main_menu.visible = false
	if setup_panel != null:
		setup_panel.visible = false
	if load_panel != null:
		load_panel.visible = true
	if arrow != null:
		arrow.visible = false

func _begin_new_game() -> void:
	var gender = selected_gender
	if gender.is_empty() and gender_options != null:
		gender = "male" if gender_options.selected == 1 else "female"
	if gender.is_empty():
		return
	Global.start_new_game("You", gender)
	if main_menu != null:
		main_menu.visible = false
	if setup_panel != null:
		setup_panel.visible = false
	if load_panel != null:
		load_panel.visible = false
	await Fade.change_scene(OPENING_FOREST_CUTSCENE_SCENE)

func _start_game_without_cutscene() -> void:
	if Global.current_region.is_empty():
		Global.current_region = "Buildings_Insides"
	if Global.current_loading_zone.is_empty():
		Global.current_loading_zone = "Infirmary"
	AreaStateManager._setup()
	AreaStateManager.swap_scene(self)

func _quit_game() -> void:
	get_tree().quit()
