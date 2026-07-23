extends Control

@onready var menu_tab = $MenuTabs
@onready var settings_tabs = $Settings_Windows

@onready var back_button = $Back_Button

@export var settings_menus: Array[String] = ["Video", "Audio", "Key Config", "Load Save", "Quit to Desktop"]

var SAVE_PATH = "user://settings.cfg"

func _ready():
	menu_tab._setup(settings_menus)
	menu_tab.selection_changed.connect(tab_changed)
	tab_changed(0)
	visibility_changed.connect(_reset)

	var saved_fps = Engine.max_fps
	match saved_fps:
		30:
			$"Settings_Windows/Display Settings/GridContainer/fps_cycle"._setup(0)
		60:
			$"Settings_Windows/Display Settings/GridContainer/fps_cycle"._setup(1)
		120:
			$"Settings_Windows/Display Settings/GridContainer/fps_cycle"._setup(2)
		_:
			$"Settings_Windows/Display Settings/GridContainer/fps_cycle"._setup(1)

	$"Settings_Windows/Display Settings/GridContainer/fps_cycle".option_changed.connect(_fps_updated)
	
	var resolutions = get_available_resolutions()
	
	$"Settings_Windows/Display Settings/GridContainer/resolution_cycle"._setup(resolutions.find(DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())), get_available_resolutions())
	$"Settings_Windows/Display Settings/GridContainer/resolution_cycle".option_changed.connect(apply_resolution)
	
	var current_window_mode = DisplayServer.window_get_mode()

	match current_window_mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
				$"Settings_Windows/Display Settings/GridContainer/screen_mode_cycle"._setup(0)
			else:
				$"Settings_Windows/Display Settings/GridContainer/screen_mode_cycle"._setup(0)
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			$"Settings_Windows/Display Settings/GridContainer/screen_mode_cycle"._setup(1)
		_:
			$"Settings_Windows/Display Settings/GridContainer/screen_mode_cycle"._setup(1)
	
	$"Settings_Windows/Display Settings/GridContainer/screen_mode_cycle".option_changed.connect(_screen_mode_changed)

	var vsync_active = DisplayServer.window_get_vsync_mode()
	$"Settings_Windows/Display Settings/GridContainer/vsync_toggle"._setup(1 if not vsync_active else 0)
	$"Settings_Windows/Display Settings/GridContainer/vsync_toggle".option_changed.connect(_vsync_changed)

	var screens = []
	for window in DisplayServer.get_screen_count():
		screens.append(str(window))
	#change_monitor(null, null, true)
	$"Settings_Windows/Display Settings/GridContainer/monitor_cycle"._setup(DisplayServer.window_get_current_screen(), screens)
	$"Settings_Windows/Display Settings/GridContainer/monitor_cycle".option_changed.connect(change_monitor)

	$"Settings_Windows/Key Config/MenuTabs"._setup(["Keyboard", "Controller"])
	$"Settings_Windows/Key Config/MenuTabs".selection_changed.connect(swap_between_controller)

	last_screen_id = DisplayServer.window_get_current_screen()
	
func swap_between_controller(index):
	if index == 0:
		$"Settings_Windows/Key Config/Keybinds/GridContainer".visible = true
		$"Settings_Windows/Key Config/Keybinds/GridContainer2".visible = false
	else:
		$"Settings_Windows/Key Config/Keybinds/GridContainer".visible = false
		$"Settings_Windows/Key Config/Keybinds/GridContainer2".visible = true
	
func _notification(what):
	if what == NOTIFICATION_WM_POSITION_CHANGED:
		var current_scene_id = DisplayServer.window_get_current_screen()
		
		if current_scene_id != last_screen_id:
			last_screen_id = current_scene_id
			var screens = []
			for window in DisplayServer.get_screen_count():
				screens.append(str(window))
			$"Settings_Windows/Display Settings/GridContainer/monitor_cycle"._setup(DisplayServer.window_get_current_screen(), screens)

func check_if_config_exists():
	if FileAccess.file_exists(SAVE_PATH):
		return true
	else:
		return false


	
func load_from_config():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	if error == OK:
		$"Settings_Windows/Sound Settings/GridContainer/Master_Slider".value = config.get_value("audio", "master_vol", 0.7)
		$"Settings_Windows/Sound Settings/GridContainer/SFX_Slider".value = config.get_value("audio", "sfx_vol", 0.7)
		$"Settings_Windows/Sound Settings/GridContainer/BGM_Slider".value = config.get_value("audio", "music_vol", 0.7)
		$"Settings_Windows/Sound Settings/GridContainer/Tile_Slider".value = config.get_value("audio", "tile_vol", 0.7)
		
		


		
func rebind_keyboard_only(action_name: String, new_keycode: int):
	var all_events = InputMap.action_get_events(action_name)
	
	for event in all_events:
		if event is InputEventKey:
			InputMap.action_erase_event(action_name, event)
	
	var new_event = InputEventKey.new()
	new_event.physical_keycode = new_keycode
	InputMap.action_add_event(action_name, new_event)
	

var last_screen_id
func _reset():
	menu_tab.visible = true
	for child in settings_tabs.get_children():
		child.visible = false
	back_button.visible = false

func _on_panel_3_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().quit()

func tab_changed(which_tab):
	if not Global.is_paused:
		return
	if which_tab == menu_tab.get_child_count() - 1:
		get_tree().quit()
		return
	if which_tab == menu_tab.get_child_count() - 2:
		get_tree().change_scene_to_file("res://scenes/main/TitleScreen.tscn")
		Global.is_in_menu = false
		Global.is_paused = false
		return
	menu_tab.visible = false
	back_button.visible = true
	for child in range(settings_tabs.get_child_count()):
		if which_tab == child:
			settings_tabs.get_child(child).visible = true
		else:
			settings_tabs.get_child(child).visible = false

func back_button_pressed(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			for child in settings_tabs.get_children():
				child.visible = false
			back_button.visible = false
			menu_tab.visible = true

func _change_volume(value, bus_name):
	var bus_index = AudioServer.get_bus_index(bus_name)
	var db_volume = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db_volume)
	SettingsManager.update_config_file()

func _fps_updated(options, current_selection):
	Engine.max_fps = int(options[current_selection])
	SettingsManager.update_config_file()

func _vsync_changed(options, current_selection):
	match options[current_selection]:
		"On":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		"Off":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	SettingsManager.update_config_file()


func change_monitor(options, current_selection, bypass = false) -> void:
	var monitor_index = 0
	if not bypass:
		monitor_index = int(options[current_selection])
		
		var total_monitors = DisplayServer.get_screen_count()
		if monitor_index < 0 or monitor_index >= total_monitors:
			return
	else:
		monitor_index = DisplayServer.window_get_current_screen()
		
	var current_mode = DisplayServer.window_get_mode()
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_current_screen(monitor_index)
	
	DisplayServer.window_set_mode(current_mode)
	
	if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		center_window_on_current_screen()
	SettingsManager.update_config_file()

func center_window_on_current_screen() -> void:
	var screen_id = DisplayServer.window_get_current_screen()
	var screen_pos = DisplayServer.screen_get_position(screen_id)
	var screen_size = DisplayServer.screen_get_size(screen_id)
	var window_size = DisplayServer.window_get_size()
	
	var new_pos = screen_pos + (screen_size / 2) - (window_size / 2)
	DisplayServer.window_set_position(new_pos)

var selected_resolution

func _screen_mode_changed(options, current_selection):
	match options[current_selection]:
		"Windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(selected_resolution)

		"Borderless Fullscreen":

			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			
			var current_screen = DisplayServer.window_get_current_screen()
			var screen_size = DisplayServer.screen_get_size(current_screen)
			var screen_pos = DisplayServer.screen_get_position(current_screen)
			
			DisplayServer.window_set_size(screen_size)
			DisplayServer.window_set_position(screen_pos)

		"Fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	SettingsManager.update_config_file()


const BASE_RESOLUTION = Vector2i(640, 360)

func get_available_resolutions() -> Array[Vector2i]:
	var resolutions: Array[Vector2i] = []
	
	var current_screen = DisplayServer.window_get_current_screen()
	
	var usable_screen_size = DisplayServer.screen_get_size(current_screen)
	
	var max_scale_x: int = int(usable_screen_size.x / BASE_RESOLUTION.x)
	var max_scale_y: int = int(usable_screen_size.y / BASE_RESOLUTION.y)
	
	var max_scale: int = min(max_scale_x, max_scale_y)
	
	if max_scale < 1:
		max_scale = 1
		
	for scale in range(1, max_scale + 1):
		var res = BASE_RESOLUTION * scale
		resolutions.append(res)
		
	return resolutions

func apply_resolution(options, current_selection) -> void:
	selected_resolution = options[current_selection]
	
	DisplayServer.window_set_size(selected_resolution)
	
	var screen_id = DisplayServer.window_get_current_screen()
	var screen_pos = DisplayServer.screen_get_position(screen_id)
	var screen_size = DisplayServer.screen_get_size(screen_id)
	
	var new_pos = screen_pos + (screen_size / 2) - (selected_resolution / 2)
	DisplayServer.window_set_position(new_pos)
	SettingsManager.update_config_file()
