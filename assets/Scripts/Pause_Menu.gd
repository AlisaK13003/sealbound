extends Control

@onready var clock = $MenuChrome/Timer
@onready var money_label = $MenuChrome/Money

@onready var menu_tab = $MenuTabs
@onready var windows = $Windows

@export var tab_names: Array[String]


var time: float = 0

func _ready():
	Global.save_loaded.connect(_on_game_start)
	menu_tab._setup(tab_names)
	menu_tab.selection_changed.connect(tab_changed)
	menu_tab.cycle_input(null, 0)
	
	#Global.is_paused = true

func tab_changed(which_tab):
	if not Global.is_paused:
		return
	for child in range(windows.get_child_count()):
		if which_tab == child:
			windows.get_child(child).visible = true
		else:
			windows.get_child(child).visible = false
	
func _on_game_start():
	return

	money_label.text = str(Global.money)



func _physics_process(_delta):
	clock.text = (str(Global.play_time_hours)) + ":" + ("%02d" % Global.play_time_minutes) + ":" + ("%02d" % Global.play_time_seconds)
