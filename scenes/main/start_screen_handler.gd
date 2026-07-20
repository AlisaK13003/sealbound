extends Control

const OPENING_FOREST_CUTSCENE_SCENE = "res://scenes/cutscenes/OpeningForestCutscene.tscn"
const FEMALE_PORTRAIT_SHEET = "res://GUI/dialogue_system/sprites/portraits/MCfemale_portraits.png"
const MALE_PORTRAIT_SHEET = "res://GUI/dialogue_system/sprites/portraits/MCmale_portraits.png"
const PORTRAIT_FRAME_NEUTRAL = 0
const PORTRAIT_FRAME_SMILE = 1
const SELECTION_BORDER_COLOR = Color(0.25, 0.12, 0.05, 1.0)
const SELECTION_BORDER_WIDTH = 2
const SETTINGS_SAVE_PATH = "user://settings.cfg"
const TITLE_FPS_OPTIONS = [30, 60, 120]
const TITLE_WINDOW_MODE_OPTIONS = ["Windowed", "Fullscreen", "Borderless Fullscreen"]
const BASE_RESOLUTION = Vector2i(640, 360)
const SETTINGS_TITLE_ROW_DEFAULT_SPACING = 8
const SETTINGS_TITLE_ROW_KEY_CONFIG_SPACING = 20

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
var settings_panel: Control
var credits_panel: Control
var settings_back_button: BaseButton
var credits_back_button: BaseButton
var settings_subpanel_top_spacer: Control
var settings_title_row: HBoxContainer
var settings_buttons_panel: Control
var settings_video_button: BaseButton
var settings_audio_button: BaseButton
var settings_key_config_button: BaseButton
var video_settings_panel: Control
var audio_settings_panel: Control
var key_config_settings_panel: Control
var window_mode_setting_button: BaseButton
var fps_setting_button: BaseButton
var resolution_setting_button: BaseButton
var monitor_setting_button: BaseButton
var vsync_setting_button: BaseButton
var window_mode_setting_label: Label
var fps_setting_label: Label
var resolution_setting_label: Label
var monitor_setting_label: Label
var vsync_setting_label: Label
var master_volume_slider: HSlider
var sfx_volume_slider: HSlider
var bgm_volume_slider: HSlider
var menu_buttons: Array[BaseButton] = []
var selected_title_resolution: Vector2i = Vector2i.ZERO

func _ready() -> void:
	Fade.reset_to_clear()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_editor_nodes()
	_configure_load_menu()
	_configure_title_settings()
	_connect_editor_buttons()
	_setup_menu_arrow()
	_show_main_menu()
	Global.time_paused = true
	AudioManager.play_bgm(load("res://assets/Audio/BGM/Week 18 - Distant Skyline CITY LIGHTS.ogg"))


func _on_button_pressed() -> void:
	StateManager.clear()
	
	_start_game_without_cutscene()

func _cache_editor_nodes() -> void:
	main_menu = get_node_or_null("UI/Menu") as Control
	setup_panel = get_node_or_null("SetupPanel") as Control
	load_panel = get_node_or_null("LoadPanel") as Control
	settings_panel = get_node_or_null("SettingsPanel") as Control
	credits_panel = get_node_or_null("CreditsPanel") as Control
	settings_title_row = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow") as HBoxContainer
	settings_back_button = _first_button([
		"SettingsPanel/MarginContainer/SettingsColumn/TitleRow/BackColumn/BackButton",
		"SettingsPanel/MarginContainer/SettingsColumn/TitleRow/BackButton"
	])
	credits_back_button = get_node_or_null("CreditsPanel/MarginContainer/CreditsRow/BackButton") as BaseButton
	settings_subpanel_top_spacer = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/SettingsSubpanelTopSpacer") as Control
	settings_buttons_panel = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/SettingsButtons") as Control
	settings_video_button = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/SettingsButtons/VideoButton") as BaseButton
	settings_audio_button = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/SettingsButtons/AudioButton") as BaseButton
	settings_key_config_button = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/SettingsButtons/KeyConfigButton") as BaseButton
	video_settings_panel = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings") as Control
	audio_settings_panel = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/AudioSettings") as Control
	key_config_settings_panel = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/KeyConfigSettings") as Control
	window_mode_setting_button = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/WindowModeButton") as BaseButton
	fps_setting_button = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/FpsButton") as BaseButton
	resolution_setting_button = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/ResolutionButton") as BaseButton
	monitor_setting_button = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/MonitorButton") as BaseButton
	vsync_setting_button = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/VsyncButton") as BaseButton
	window_mode_setting_label = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/WindowModeButton/Label") as Label
	fps_setting_label = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/FpsButton/Label") as Label
	resolution_setting_label = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/ResolutionButton/Label") as Label
	monitor_setting_label = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/MonitorButton/Label") as Label
	vsync_setting_label = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/VideoSettings/VsyncButton/Label") as Label
	master_volume_slider = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/AudioSettings/GridContainer/MasterSlider") as HSlider
	sfx_volume_slider = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/AudioSettings/GridContainer/SFXSlider") as HSlider
	bgm_volume_slider = get_node_or_null("SettingsPanel/MarginContainer/SettingsColumn/TitleRow/SettingsContent/AudioSettings/GridContainer/BGMSlider") as HSlider
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
	_connect_button(settings_button, _show_settings)
	_connect_button(credits_button, _show_credits)
	_connect_button(exit_button, _quit_game)
	_connect_button(female_choice_button, _select_character.bind("female"))
	_connect_button(male_choice_button, _select_character.bind("male"))
	_connect_button(start_button, _begin_new_game)
	_connect_button(setup_title_back_button, _show_main_menu)
	_connect_button(setup_back_button, _show_main_menu)
	_connect_button(load_back_button, _show_main_menu)
	_connect_button(settings_back_button, _settings_back)
	_connect_button(credits_back_button, _show_main_menu)
	_connect_button(settings_video_button, _show_settings_subpanel.bind("video"))
	_connect_button(settings_audio_button, _show_settings_subpanel.bind("audio"))
	_connect_button(settings_key_config_button, _show_settings_subpanel.bind("key_config"))
	_connect_button(window_mode_setting_button, _cycle_window_mode)
	_connect_button(fps_setting_button, _cycle_fps)
	_connect_button(resolution_setting_button, _cycle_resolution)
	_connect_button(monitor_setting_button, _cycle_monitor)
	_connect_button(vsync_setting_button, _cycle_vsync)
	_connect_slider(master_volume_slider, "Master")
	_connect_slider(sfx_volume_slider, "SFX")
	_connect_slider(bgm_volume_slider, "BGM")

func _connect_button(button: BaseButton, callback: Callable) -> void:
	if button == null:
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _connect_slider(slider: HSlider, bus_name: String) -> void:
	if slider == null:
		return
	var callback := Callable(self, "_change_title_volume").bind(bus_name)
	if not slider.value_changed.is_connected(callback):
		slider.value_changed.connect(callback)

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

func _configure_title_settings() -> void:
	_load_title_settings()
	_show_settings_category_list()
	_update_video_setting_labels()
	_prepare_volume_slider(master_volume_slider, "Master")
	_prepare_volume_slider(sfx_volume_slider, "SFX")
	_prepare_volume_slider(bgm_volume_slider, "BGM")

func _prepare_volume_slider(slider: HSlider, bus_name: String) -> void:
	if slider == null:
		return
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = _get_bus_volume_linear(bus_name)

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
	if settings_panel != null:
		settings_panel.visible = false
	if credits_panel != null:
		credits_panel.visible = false
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
	if settings_panel != null:
		settings_panel.visible = false
	if credits_panel != null:
		credits_panel.visible = false
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
	if settings_panel != null:
		settings_panel.visible = false
	if credits_panel != null:
		credits_panel.visible = false
	if arrow != null:
		arrow.visible = false

func _show_settings() -> void:
	if main_menu != null:
		main_menu.visible = false
	if setup_panel != null:
		setup_panel.visible = false
	if load_panel != null:
		load_panel.visible = false
	if settings_panel != null:
		settings_panel.visible = true
	if credits_panel != null:
		credits_panel.visible = false
	_show_settings_category_list()
	if arrow != null:
		arrow.visible = false

func _show_credits() -> void:
	if main_menu != null:
		main_menu.visible = false
	if setup_panel != null:
		setup_panel.visible = false
	if load_panel != null:
		load_panel.visible = false
	if settings_panel != null:
		settings_panel.visible = false
	if credits_panel != null:
		credits_panel.visible = true
	if arrow != null:
		arrow.visible = false

func _settings_back() -> void:
	if settings_panel != null and settings_panel.visible and _is_settings_subpanel_open():
		_show_settings_category_list()
		return
	_show_main_menu()

func _show_settings_category_list() -> void:
	_set_settings_title_row_spacing(SETTINGS_TITLE_ROW_DEFAULT_SPACING)
	if settings_buttons_panel != null:
		settings_buttons_panel.visible = true
	if settings_subpanel_top_spacer != null:
		settings_subpanel_top_spacer.visible = false
	if video_settings_panel != null:
		video_settings_panel.visible = false
	if audio_settings_panel != null:
		audio_settings_panel.visible = false
	if key_config_settings_panel != null:
		key_config_settings_panel.visible = false

func _show_settings_subpanel(panel_name: String) -> void:
	_set_settings_title_row_spacing(SETTINGS_TITLE_ROW_KEY_CONFIG_SPACING if panel_name == "key_config" else SETTINGS_TITLE_ROW_DEFAULT_SPACING)
	if settings_buttons_panel != null:
		settings_buttons_panel.visible = false
	if settings_subpanel_top_spacer != null:
		settings_subpanel_top_spacer.visible = panel_name == "video" or panel_name == "key_config"
		settings_subpanel_top_spacer.custom_minimum_size = Vector2(0, 64 if panel_name == "key_config" else 48)
	if video_settings_panel != null:
		video_settings_panel.visible = panel_name == "video"
	if audio_settings_panel != null:
		audio_settings_panel.visible = panel_name == "audio"
	if key_config_settings_panel != null:
		key_config_settings_panel.visible = panel_name == "key_config"
	_update_video_setting_labels()

func _set_settings_title_row_spacing(spacing: int) -> void:
	if settings_title_row != null:
		settings_title_row.add_theme_constant_override("separation", spacing)

func _is_settings_subpanel_open() -> bool:
	return (
		(video_settings_panel != null and video_settings_panel.visible)
		or (audio_settings_panel != null and audio_settings_panel.visible)
		or (key_config_settings_panel != null and key_config_settings_panel.visible)
	)

func _load_title_settings() -> void:
	selected_title_resolution = DisplayServer.window_get_size()
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_SAVE_PATH) != OK:
		return

	var monitor_value: Variant = config.get_value("display", "desired_monitor", DisplayServer.window_get_current_screen())
	_apply_monitor(int(monitor_value), false)

	var resolution_value: Variant = config.get_value("display", "resolution", selected_title_resolution)
	if resolution_value is Vector2i:
		selected_title_resolution = resolution_value
	elif resolution_value is Vector2:
		selected_title_resolution = Vector2i(int(resolution_value.x), int(resolution_value.y))
	_apply_resolution(selected_title_resolution, false)

	var screen_mode: String = str(config.get_value("display", "screen_mode", "Windowed"))
	_apply_window_mode(screen_mode, false)

	var fps: int = int(config.get_value("display", "fps", 60))
	_apply_fps(fps, false)

	var vsync_state: String = str(config.get_value("display", "vsync", "Off"))
	_apply_vsync(vsync_state == "On", false)

func _cycle_window_mode() -> void:
	var current_index: int = TITLE_WINDOW_MODE_OPTIONS.find(_get_window_mode_label())
	if current_index == -1:
		current_index = 0
	var next_index: int = (current_index + 1) % TITLE_WINDOW_MODE_OPTIONS.size()
	_apply_window_mode(TITLE_WINDOW_MODE_OPTIONS[next_index])

func _cycle_fps() -> void:
	var current_index := TITLE_FPS_OPTIONS.find(Engine.max_fps)
	if current_index == -1:
		current_index = 1
	var next_index: int = (current_index + 1) % TITLE_FPS_OPTIONS.size()
	_apply_fps(int(TITLE_FPS_OPTIONS[next_index]))

func _cycle_resolution() -> void:
	var resolutions: Array[Vector2i] = _get_available_title_resolutions()
	if resolutions.is_empty():
		return
	var current_resolution: Vector2i = selected_title_resolution
	if current_resolution == Vector2i.ZERO:
		current_resolution = DisplayServer.window_get_size()
	var current_index: int = resolutions.find(current_resolution)
	if current_index == -1:
		current_index = 0
	var next_index: int = (current_index + 1) % resolutions.size()
	_apply_resolution(resolutions[next_index])

func _cycle_monitor() -> void:
	var screen_count: int = DisplayServer.get_screen_count()
	if screen_count <= 1:
		_update_monitor_label()
		return
	var next_monitor: int = (DisplayServer.window_get_current_screen() + 1) % screen_count
	_apply_monitor(next_monitor)

func _cycle_vsync() -> void:
	_apply_vsync(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED)

func _apply_fps(fps: int, should_save: bool = true) -> void:
	if not TITLE_FPS_OPTIONS.has(fps):
		fps = 60
	Engine.max_fps = fps
	if should_save:
		_save_title_setting("display", "fps", Engine.max_fps)
	_update_fps_label()

func _apply_resolution(resolution: Vector2i, should_save: bool = true) -> void:
	selected_title_resolution = resolution
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED and not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
		DisplayServer.window_set_size(selected_title_resolution)
		_center_title_window_on_current_screen()
	if should_save:
		_save_title_setting("display", "resolution", selected_title_resolution)
	_update_resolution_label()

func _apply_window_mode(mode_label: String, should_save: bool = true) -> void:
	if selected_title_resolution == Vector2i.ZERO:
		selected_title_resolution = DisplayServer.window_get_size()
	match mode_label:
		"Windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(selected_title_resolution)
			_center_title_window_on_current_screen()
		"Borderless Fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			_fill_current_title_screen()
		"Fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			_apply_window_mode("Windowed", should_save)
			return
	if should_save:
		_save_title_setting("display", "screen_mode", _get_window_mode_label())
	_update_window_mode_label()

func _apply_monitor(monitor_index: int, should_save: bool = true) -> void:
	var screen_count: int = DisplayServer.get_screen_count()
	if screen_count <= 0:
		return
	var clamped_monitor: int = clampi(monitor_index, 0, screen_count - 1)
	var current_mode: int = DisplayServer.window_get_mode()
	var was_borderless: bool = current_mode == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_current_screen(clamped_monitor)

	if was_borderless:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		_fill_current_title_screen()
	else:
		DisplayServer.window_set_mode(current_mode)
		if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			_center_title_window_on_current_screen()

	if should_save:
		_save_title_setting("display", "desired_monitor", DisplayServer.window_get_current_screen())
	_update_monitor_label()

func _apply_vsync(is_enabled: bool, should_save: bool = true) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if is_enabled else DisplayServer.VSYNC_DISABLED)
	if should_save:
		_save_title_setting("display", "vsync", "On" if is_enabled else "Off")
	_update_vsync_label()

func _update_video_setting_labels() -> void:
	_update_fps_label()
	_update_resolution_label()
	_update_window_mode_label()
	_update_monitor_label()
	_update_vsync_label()

func _update_window_mode_label() -> void:
	if window_mode_setting_label != null:
		window_mode_setting_label.text = "Mode: " + _get_window_mode_short_label()

func _update_fps_label() -> void:
	if fps_setting_label != null:
		fps_setting_label.text = "FPS: " + str(Engine.max_fps if Engine.max_fps > 0 else 60)

func _update_resolution_label() -> void:
	if resolution_setting_label != null:
		var resolution: Vector2i = selected_title_resolution
		if resolution == Vector2i.ZERO:
			resolution = DisplayServer.window_get_size()
		resolution_setting_label.text = "Res: " + str(resolution.x) + "x" + str(resolution.y)

func _update_monitor_label() -> void:
	if monitor_setting_label != null:
		monitor_setting_label.text = "Monitor: " + str(DisplayServer.window_get_current_screen())

func _update_vsync_label() -> void:
	if vsync_setting_label != null:
		vsync_setting_label.text = "VSync: " + ("On" if DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED else "Off")

func _get_window_mode_label() -> String:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		return "Fullscreen"
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
		return "Borderless Fullscreen"
	return "Windowed"

func _get_window_mode_short_label() -> String:
	if _get_window_mode_label() == "Borderless Fullscreen":
		return "Borderless"
	return _get_window_mode_label()

func _get_available_title_resolutions() -> Array[Vector2i]:
	var resolutions: Array[Vector2i] = []
	var screen_count: int = DisplayServer.get_screen_count()
	var usable_screen_size: Vector2i = Vector2i(1280, 720)
	if screen_count > 0:
		var current_screen: int = clampi(DisplayServer.window_get_current_screen(), 0, screen_count - 1)
		usable_screen_size = DisplayServer.screen_get_size(current_screen)
		if usable_screen_size.x <= 0 or usable_screen_size.y <= 0:
			usable_screen_size = Vector2i(1280, 720)

	var max_scale_x: int = int(usable_screen_size.x / BASE_RESOLUTION.x)
	var max_scale_y: int = int(usable_screen_size.y / BASE_RESOLUTION.y)
	var max_scale: int = max(1, min(max_scale_x, max_scale_y))
	for scale in range(1, max_scale + 1):
		resolutions.append(BASE_RESOLUTION * scale)
	return resolutions

func _center_title_window_on_current_screen() -> void:
	var screen_count: int = DisplayServer.get_screen_count()
	if screen_count <= 0:
		return
	var screen_id: int = clampi(DisplayServer.window_get_current_screen(), 0, screen_count - 1)
	var screen_pos: Vector2i = DisplayServer.screen_get_position(screen_id)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
	var window_size: Vector2i = DisplayServer.window_get_size()
	var new_pos: Vector2i = screen_pos + (screen_size / 2) - (window_size / 2)
	DisplayServer.window_set_position(new_pos)

func _fill_current_title_screen() -> void:
	var screen_count: int = DisplayServer.get_screen_count()
	if screen_count <= 0:
		return
	var screen_id: int = clampi(DisplayServer.window_get_current_screen(), 0, screen_count - 1)
	DisplayServer.window_set_size(DisplayServer.screen_get_size(screen_id))
	DisplayServer.window_set_position(DisplayServer.screen_get_position(screen_id))

func _change_title_volume(value: float, bus_name: String) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var clamped_value := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(clamped_value, 0.001)))
	match bus_name:
		"Master":
			_save_title_setting("audio", "master_vol", clamped_value)
		"SFX":
			_save_title_setting("audio", "sfx_vol", clamped_value)
		"BGM":
			_save_title_setting("audio", "music_vol", clamped_value)

func _get_bus_volume_linear(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return 0.7
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)

func _save_title_setting(section: String, key: String, value) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_SAVE_PATH)
	config.set_value(section, key, value)
	config.save(SETTINGS_SAVE_PATH)

func _begin_new_game() -> void:
	StateManager.clear()
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
	if settings_panel != null:
		settings_panel.visible = false
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
