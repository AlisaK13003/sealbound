extends Control

const SAVE_LOAD_MENU_SCENE = preload("res://assets/Resources/Pause Menu/Save Load Menu/Save_Load_Menu.tscn")
const CUTSCENE_RUNNER_SCRIPT = preload("res://assets/Scripts/cutscene_runner.gd")
const OPENING_CUTSCENE_PATH = "res://assets/Resources/Cutscenes/opening_tutorial.json"
const INFIRMARY_WAKEUP_CUTSCENE_PATH = "res://assets/Resources/Cutscenes/infirmary_wakeup.json"

var main_menu: VBoxContainer
var setup_panel: PanelContainer
var load_panel: PanelContainer
var gender_options: OptionButton
var cutscene_runner: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var legacy_button = get_node_or_null("Button")
	if legacy_button != null:
		legacy_button.visible = false
	_build_title_ui()
	_show_main_menu()

func _on_button_pressed() -> void:
	_start_game_without_cutscene()

func _build_title_ui() -> void:
	var background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.08, 0.11, 0.13, 1.0)
	add_child(background)
	move_child(background, 0)

	var root = CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title_column = VBoxContainer.new()
	title_column.custom_minimum_size = Vector2(420, 0)
	title_column.add_theme_constant_override("separation", 18)
	root.add_child(title_column)

	var title = Label.new()
	title.text = "Sealbound"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title_column.add_child(title)

	main_menu = VBoxContainer.new()
	main_menu.add_theme_constant_override("separation", 10)
	title_column.add_child(main_menu)

	_add_menu_button(main_menu, "New Game", _show_new_game)
	_add_menu_button(main_menu, "Load Game", _show_load_game)
	_add_menu_button(main_menu, "Quit", _quit_game)

	setup_panel = _build_setup_panel()
	title_column.add_child(setup_panel)

	load_panel = _build_load_panel()
	title_column.add_child(load_panel)

	cutscene_runner = CUTSCENE_RUNNER_SCRIPT.new()
	cutscene_runner.finished.connect(_on_opening_cutscene_finished)
	add_child(cutscene_runner)

func _add_menu_button(parent: Control, label_text: String, callback: Callable) -> void:
	var button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(280, 44)
	button.pressed.connect(callback)
	parent.add_child(button)

func _build_setup_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.visible = false

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var prompt = Label.new()
	prompt.text = "New Game"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 28)
	column.add_child(prompt)

	var appearance_label = Label.new()
	appearance_label.text = "Choose Appearance"
	appearance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(appearance_label)

	gender_options = OptionButton.new()
	gender_options.add_item("Female", 0)
	gender_options.add_item("Male", 1)
	column.add_child(gender_options)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)

	_add_menu_button(row, "Start", _begin_new_game)
	_add_menu_button(row, "Back", _show_main_menu)
	return panel

func _build_load_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.visible = false

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var load_menu = SAVE_LOAD_MENU_SCENE.instantiate()
	load_menu.start_in_load_mode = true
	load_menu.allow_saving = false
	load_menu.show_delete = false
	column.add_child(load_menu)

	_add_menu_button(column, "Back", _show_main_menu)
	return panel

func _show_main_menu() -> void:
	main_menu.visible = true
	setup_panel.visible = false
	load_panel.visible = false

func _show_new_game() -> void:
	main_menu.visible = false
	setup_panel.visible = true
	load_panel.visible = false
	gender_options.grab_focus()

func _show_load_game() -> void:
	main_menu.visible = false
	setup_panel.visible = false
	load_panel.visible = true

func _begin_new_game() -> void:
	var gender = "female"
	if gender_options.selected == 1:
		gender = "male"
	Global.start_new_game("Stranger", gender)
	main_menu.visible = false
	setup_panel.visible = false
	load_panel.visible = false
	cutscene_runner.play(OPENING_CUTSCENE_PATH)

func _on_opening_cutscene_finished() -> void:
	Global.pending_cutscene_path = INFIRMARY_WAKEUP_CUTSCENE_PATH
	Global.current_region = "Buildings_Insides"
	Global.current_loading_zone = "Infirmary"
	Global.set_pending_player_spawn_position(Vector2(2302, -749))
	_start_game_without_cutscene()

func _start_game_without_cutscene() -> void:
	if Global.current_region.is_empty():
		Global.current_region = "Buildings_Insides"
	if Global.current_loading_zone.is_empty():
		Global.current_loading_zone = "Infirmary"
	AreaStateManager._setup()
	AreaStateManager.swap_scene(self)

func _quit_game() -> void:
	get_tree().quit()
