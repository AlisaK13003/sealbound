extends Node2D

var dialogue_data: Dictionary

var path_nodes: Array[Vector2]
var walking: bool = false

var running_time: float = 0

var player_in_range: bool = false
var player_is_speaking_to_me: bool = false
var player_just_stopped_talking_to_me: bool = false

@onready var clickable_area : Area2D = $NPC_Clickable
@onready var check_player_in_range: Area2D = $Player_In_Range
@onready var dialogue_box : Control = $CanvasLayer/DialogueWindow

@export_file("*.json") var dialogue_path: String
@export var location_container: Node2D
@export var speed: float = 300.0
@export var schedule: Array[npc_schedule]

func _ready():
	Global.time_updated.connect(navigate)
	if dialogue_path.is_empty():
		print("Error: JSON file path is not set in the editor.")
		return

	dialogue_data = load_json_file(dialogue_path)

# If there is no schedule to execute, or if player is talking, do nothing
# If player stopped talking, wait 3 seconds till they start going again 
# Otherwise have the npc move towards their destination
func _process(delta):
	if path_nodes.is_empty():
		return 
		
	if player_is_speaking_to_me:
		return
	
	if player_just_stopped_talking_to_me:
		running_time += delta
		
		if running_time >= 3:
			player_just_stopped_talking_to_me = false
			running_time = 0
		return
	
	var current_target = path_nodes[0]
	global_position = global_position.move_toward(current_target, speed * delta)
	
	if global_position.distance_to(current_target) < 0.1:
		global_position = current_target
		path_nodes.pop_front() 

# Loads the NPCs dialogue "tree" into memory
func load_json_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		return {}

	var json_text: String = file.get_as_text()
	file.close()

	var parse_result: Variant = JSON.parse_string(json_text)
	if parse_result is Dictionary:
		return parse_result as Dictionary
	elif parse_result is Array:
		return { "data": parse_result } 
	else:
		return {}	

# Is called by a signal in global that emits every time the clock updates
# Checks if there is a schedule that can be executed, if yes, send them on their merry way
func navigate():
	for navigation in schedule:
		if Global.current_weather != navigation.weather_conditions:
			print("weather doesn't match")
		elif Global.current_day % navigation.repeats_every_x_days != 0:
			print("Can't happen")
		elif Global.current_hour == navigation.what_hour and Global.current_minute == navigation.what_minute:
			setup_navigation(navigation)

# Given the start and end location specified in the schedule, return the path of points needed to traverse to get there
func setup_navigation(active_schedule: npc_schedule):
	var path_ids = location_container.get_path_between(active_schedule.start_location, active_schedule.end_location)
		
	for vertex_id in path_ids:
		var target_node = location_container.get_child(vertex_id)
		var target_pos = target_node.location_position[2] 
		path_nodes.append(target_pos)

# This shouldn't really exist (the cancel operation), only does for testing purposes
# Currently only makes it so when you press cancel (x) it closes the dialogue box
func _input(event):
	if player_is_speaking_to_me and player_in_range:
		if event.is_action_pressed("Cancel"):
			player_is_speaking_to_me = false
			player_just_stopped_talking_to_me = true
			Global.is_in_menu = false
			dialogue_box.visible = false
			dialogue_box.clear_text_box()

# Upon click, start dialogue
# Will be set up so different dialogue happens depending on state, not there yet
# Currently just specify which scene and it'll go through that set till conclusion and repeat
func _on_npc_clickable_input_event(_viewport, event, _shape_idx):
	if player_in_range:
		if event.is_action_pressed("Mouse_Right_Click"):
			player_is_speaking_to_me = true
			Global.is_in_menu = true
			dialogue_box.visible = true
			dialogue_box.start_talking(dialogue_data["scene1"].duplicate(true), 0)

# Determines if the player is in range to talk with NPC
func _on_player_in_range_area_entered(area):
	if area.is_in_group("Overworld_Player"):
		player_in_range = true

func _on_player_in_range_area_exited(area):
	if area.is_in_group("Overworld_Player"):
		player_in_range = false
