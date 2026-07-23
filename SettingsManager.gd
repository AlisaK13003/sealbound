extends Node

var SAVE_PATH = "user://settings.cfg"

var selected_resolution

func _ready():
	if not check_if_config_exists():
		update_config_file()
	else:
		load_from_config()

func check_if_config_exists():
	if FileAccess.file_exists(SAVE_PATH):
		return true
	else:
		return false

func update_config_file():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	if error == OK:
		#fps, resolution, screenmode, desired monitor, vsync toggle
		# master volume, sfx volume, bgm slider
		# key binds
		
		config.set_value("display", "fps", Engine.max_fps)
		if selected_resolution == null:
			selected_resolution = DisplayServer.window_get_size()
		config.set_value("display", "resolution", selected_resolution)
		var current_mode = DisplayServer.window_get_mode()
		var mode_string = "Windowed"
		if current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			mode_string = "Fullscreen"
		elif current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
			if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
				mode_string = "Borderless Fullscreen"
			else:
				mode_string = "Windowed"
		config.set_value("display", "screen_mode", mode_string)
		config.set_value("display", "desired_monitor", DisplayServer.window_get_current_screen())
		config.set_value("display", "vsync", "On" if DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED else "Off")
		
		config.set_value("audio", "master_vol", db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))))
		config.set_value("audio", "sfx_vol", db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))))
		config.set_value("audio", "music_vol",db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM"))))
		config.set_value("audio", "tile_vol",db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("TILE"))))
	config.save(SAVE_PATH)

func load_from_config():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	if error == OK:
		var res = config.get_value("display", "resolution", Vector2i(640, 360))
		apply_resolution([res], 0)
		
		var screen_mode = config.get_value("display", "screen_mode", "Windowed")
		_screen_mode_changed([screen_mode], 0)
		
		var monitor = config.get_value("display", "desired_monitor", 0)
		change_monitor([monitor], 0)
		
		var fps = config.get_value("display", "fps", 60)
		_fps_updated([fps], 0)
		
		var vsync_state = config.get_value("display", "vscyn", "Off")
		_vsync_changed([vsync_state], 0)

		_change_volume(config.get_value("audio", "master_vol", 0.7), "Master")
		_change_volume(config.get_value("audio", "sfx_vol", 0.7), "SFX")
		_change_volume(config.get_value("audio", "music_vol", 0.7), "BGM")
		_change_volume(config.get_value("audio", "tile_vol", 0.7), "TILE")
		
		rebind_keyboard_only("up", config.get_value("binds", "up", KEY_W))
		rebind_keyboard_only("down", config.get_value("binds", "down", KEY_S))
		rebind_keyboard_only("left", config.get_value("binds", "left", KEY_A))
		rebind_keyboard_only("right", config.get_value("binds", "right", KEY_D))
		rebind_keyboard_only("confirm", config.get_value("binds", "confirm", KEY_C))
		rebind_keyboard_only("cancel", config.get_value("binds", "cancel", KEY_X))
		rebind_keyboard_only("Dungeon_Item", config.get_value("binds", "Dungeon_Item", KEY_I))
		rebind_keyboard_only("Dungeon_Skill", config.get_value("binds", "Dungeon_Skill", KEY_L))
		
		
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
	DisplayServer.window_set_position
	
	
func center_window_on_current_screen() -> void:
	var screen_id = DisplayServer.window_get_current_screen()
	var screen_pos = DisplayServer.screen_get_position(screen_id)
	var screen_size = DisplayServer.screen_get_size(screen_id)
	var window_size = DisplayServer.window_get_size()
	
	var new_pos = screen_pos + (screen_size / 2) - (window_size / 2)
	DisplayServer.window_set_position(new_pos)

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
	update_config_file()
	
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
	update_config_file()
	
func _fps_updated(options, current_selection):
	Engine.max_fps = int(options[current_selection])
	update_config_file()

func _vsync_changed(options, current_selection):
	match options[current_selection]:
		"On":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		"Off":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	update_config_file()
	
func _change_volume(value, bus_name):
	var bus_index = AudioServer.get_bus_index(bus_name)
	var db_volume = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db_volume)
	update_config_file()
	
func rebind_keyboard_only(action_name: String, new_keycode: int):
	var all_events = InputMap.action_get_events(action_name)
	
	for event in all_events:
		if event is InputEventKey:
			InputMap.action_erase_event(action_name, event)
	
	var new_event = InputEventKey.new()
	new_event.physical_keycode = new_keycode
	InputMap.action_add_event(action_name, new_event)
