extends Control

@onready var clock = $MenuChrome/Timer
@onready var money_label = $MenuChrome/Money

@onready var menu_tab = $MenuTabs
@onready var windows = $Windows

@export var tab_names: Array[String]
@export var is_dungeon_menu: bool = false

@export var mini_map_handler: Control

@export var tab_icons: Array[Texture2D]

var mini_map = null

var time: float = 0

func _ready():
	Global.save_loaded.connect(_on_game_start)
	menu_tab._setup(tab_names, "res://assets/Resources/Pause Menu/Custom_Menu_Tab.tscn", tab_icons)
	menu_tab.selection_changed.connect(tab_changed)
	
	#Global.is_paused = true

func _setup(dungeon_instance, generated_rooms):
	if is_dungeon_menu and not windows.get_child(0) is mini_map_class:
		var new_map = mini_map_handler.duplicate()
		windows.add_child(new_map)
		windows.move_child(new_map, 0)
		new_map._setup(dungeon_instance, generated_rooms)
		new_map.hide_mini_map()
		new_map.open_full_screen()
		mini_map = new_map
	elif is_dungeon_menu and windows.get_child(0) is mini_map_class:
		mini_map._setup(dungeon_instance, generated_rooms)
		mini_map.hide_mini_map()
		mini_map.open_full_screen()
	
	windows.get_child(1).visible = false
	windows.get_child(0).visible = true
	menu_tab.cycle_input(null, -10)

func _reset():
	menu_tab.cycle_input(null, -10)
	tab_changed(0)

func clear_minimap():
	if mini_map != null:
		mini_map.clear_mini_map()

func update_fsm():
	mini_map.center_fullscreen_around_tile(windows.get_child(0).current_player_room_coords)

func tab_changed(which_tab):
	if not Global.is_paused:
		return
	for child in range(windows.get_child_count()):
		if which_tab == child:
			if child == 0 and is_dungeon_menu:
				windows.get_child(child).can_move_fullscreen_map = true
				windows.get_child(child).center_fullscreen_around_tile(windows.get_child(child).current_player_room_coords)
			windows.get_child(child).visible = true
			if windows.get_child(child).has_method("enable"):
				windows.get_child(child).enable()
		else:
			if child == 0 and is_dungeon_menu:
				windows.get_child(child).can_move_fullscreen_map = false
			windows.get_child(child).visible = false
			if windows.get_child(child).has_method("disable"):
				windows.get_child(child).disable()
	
func _on_game_start():
	return

	money_label.text = str(Global.money)

func _physics_process(_delta):
	clock.text = (str(Global.play_time_hours)) + ":" + ("%02d" % Global.play_time_minutes) + ":" + ("%02d" % Global.play_time_seconds)
