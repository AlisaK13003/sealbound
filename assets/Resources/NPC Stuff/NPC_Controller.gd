extends Node2D

var dialogue_data: Dictionary

var path_nodes: Array[Vector2]
var walking: bool = false
var leaving_scene: bool = false

var running_time: float = 0

var player_in_range: bool = false
var player_is_speaking_to_me: bool = false
var player_just_stopped_talking_to_me: bool = false

var current_location

@onready var clickable_area : Area2D = $NPC_Clickable
@onready var check_player_in_range: Area2D = $Player_In_Range

@export_file("*.json") var dialogue_path: String
@export var location_container: Node2D
@export var speed: float = 300.0
@export_file("*.json") var schedule_path: String

var schedule_info
var traveling_to : int
var just_swapped_scenes: bool = false

func _ready():
	Global.time_updated.connect(navigate)
	if dialogue_path.is_empty():
		print("Error: JSON file path is not set in the editor.")
		return
	var file = FileAccess.open(schedule_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	schedule_info = JSON.parse_string(json_string)
	
	dialogue_data = load_json_file(dialogue_path)
	if DialogueSystem != null and DialogueSystem.has_signal("dialogue_closed"):
		var dialogue_closed_callback = Callable(self, "_on_dialogue_system_dialogue_closed")
		if not DialogueSystem.dialogue_closed.is_connected(dialogue_closed_callback):
			DialogueSystem.dialogue_closed.connect(dialogue_closed_callback)
	just_swapped_scenes = true


# If there is no schedule to execute, or if player is talking, do nothing
# If player stopped talking, wait 3 seconds till they start going again 
# Otherwise have the npc move towards their destination
func _process(delta):
	if path_nodes.is_empty():
		walking = false
		if leaving_scene:
			self.visible = false
		return 
	if player_is_speaking_to_me:
		return
	
	if player_just_stopped_talking_to_me:
		running_time += delta
		
		if running_time >= 3:
			player_just_stopped_talking_to_me = false
			running_time = 0
		return
	walking = true
	self.visible = true
	var current_target = path_nodes[0]
	just_swapped_scenes = false
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
	if walking == true:
		return
	for schedule_name in schedule_info["schedules"]:
		var details = schedule_info["schedules"][schedule_name]
		var path = get_tree().current_scene.scene_file_path
		if details["scene_swap"] == 1 and details["2_start_time_hour"] != 0:
			if details["start_scene"] == path:
				if check_time(details["start_time_hour"], details["start_time_minute"], 2):
					print("NOT TIME YET")
					return
				elif check_time(details["start_time_hour"], details["start_time_minute"], 1):
					self.visible = true
					setup_navigation(details, 0)
					leaving_scene = true
					if details["should_disappear"] == 1:
						self.visible = false
					return
				elif check_time(details["2_start_time_hour"], details["2_start_time_minute"], 2) and just_swapped_scenes:
					print("TRYING AGAIN")
					self.visible = true
					setup_navigation(details, 2)
					leaving_scene = true
					if details["should_disappear"] == 1:
						self.visible = false
					return
			elif details["end_scene"] == path and check_time(details["2_start_time_hour"], details["2_start_time_minute"], 1):
				leaving_scene = true
				self.visible = true
				setup_navigation(details, 1)
				if details["should_disappear"] == 1:
					self.visible = false
				return
		elif details["start_scene"] == path and check_time(details["start_time_hour"], details["start_time_minute"], 1):
			self.visible = true
			setup_navigation(details, 0)
			leaving_scene = false
			if details["should_disappear"] == 1:
				self.visible = false
			return
		elif details["start_scene"] == path and check_time(details["2_start_time_hour"], details["2_start_time_minute"], 2) and just_swapped_scenes:
			self.visible = true
			setup_navigation(details, 3)
			leaving_scene = false
			if details["should_disappear"] == 1:
				self.visible = false
	return

func check_time(start_time_hour, start_time_minutes, before_equal_after):
	match before_equal_after:
		0:
			if start_time_hour < Global.current_hour and start_time_minutes < Global.current_minute:
				return true
		1:
			if start_time_hour == Global.current_hour and start_time_minutes == Global.current_minute:
				return true
		2:
			if start_time_hour > Global.current_hour:
				return true
			elif start_time_hour == Global.current_hour and start_time_minutes > Global.current_minute:
				return true

	return false

# Given the start and end location specified in the schedule, return the path of points needed to traverse to get there
func setup_navigation(schedule_info_basic, which_sub_schedule):
	match which_sub_schedule:
		0:
			set_path(schedule_info_basic["start_location"], schedule_info_basic["end_location"])
		1:
			set_path(schedule_info_basic["2_start_location"], schedule_info_basic["2_end_location"])
		# resume schedule
		2:
			var temp_path = location_container.get_path_between(schedule_info_basic["start_location"], schedule_info_basic["end_location"])
			var time_diff = ((schedule_info_basic["2_start_time_hour"] - Global.current_hour) * 60) - (schedule_info_basic["2_start_time_minute"] - Global.current_minute)
			var start_diff = (( schedule_info_basic["2_start_time_hour"] - schedule_info_basic["start_time_hour"]) * 60) - (schedule_info_basic["2_start_time_minute"] - schedule_info_basic["2_start_time_minute"])
			var final_diff = time_diff / start_diff
			var path_start = (temp_path.size() - 1) * final_diff
			if floor(path_start) == location_container.get_child_count():
				path_start -= 1
			set_path(floor(path_start), schedule_info_basic["end_location"])
		3:
			var temp_path = location_container.get_path_between(schedule_info_basic["start_location"], schedule_info_basic["end_location"])
			var time_diff = ((schedule_info_basic["end_time_hour"] - Global.current_hour) * 60) - (Global.current_minute)
			var start_diff = ((schedule_info_basic["end_time_hour"] - schedule_info_basic["start_time_hour"]) * 60) - schedule_info_basic["start_time_minute"] + schedule_info_basic["end_time_minute"]
			var final_diff = time_diff / start_diff
			var path_start = temp_path.size() * final_diff

			set_path(floor(path_start), schedule_info_basic["end_location"])
			

func set_path(start_point, end_point):
	var path_ids = location_container.get_path_between(start_point, end_point)
	path_nodes.clear()
	for vertex_id in path_ids:
		var target_node = location_container.get_child(vertex_id)
		var target_pos = target_node.location_position[2] 
		if vertex_id == start_point:
			self.position = target_pos
		path_nodes.append(target_pos)

# This shouldn't really exist (the cancel operation), only does for testing purposes
# Currently only makes it so when you press cancel (x) it closes the dialogue box
func _input(event):
	if not player_in_range:
		return

	if player_is_speaking_to_me:
		if event.is_action_pressed("Cancel"):
			end_dialogue()
		return

	if event.is_action_pressed("Confirm") or event.is_action_pressed("Mouse_Right_Click"):
		begin_dialogue()

# Upon click, start dialogue
# Will be set up so different dialogue happens depending on state, not there yet
# Currently just specify which scene and it'll go through that set till conclusion and repeat
func _on_npc_clickable_input_event(_viewport, event, _shape_idx):
	if player_in_range:
		if event.is_action_pressed("Mouse_Right_Click"):
			begin_dialogue()

func begin_dialogue() -> void:
	if player_is_speaking_to_me:
		return

	player_is_speaking_to_me = true
	Global.is_in_menu = true

	if DialogueSystem != null and DialogueSystem.has_method("show_dialog"):
		DialogueSystem.show_dialog()

func end_dialogue() -> void:
	if not player_is_speaking_to_me:
		return

	if DialogueSystem != null and DialogueSystem.has_method("hide_dialog"):
		DialogueSystem.hide_dialog()

func _on_dialogue_system_dialogue_closed() -> void:
	if not player_is_speaking_to_me:
		return

	player_is_speaking_to_me = false
	player_just_stopped_talking_to_me = true
	Global.is_in_menu = false

# Determines if the player is in range to talk with NPC
func _on_player_in_range_area_entered(area):
	if area.is_in_group("Overworld_Player"):
		player_in_range = true

func _on_player_in_range_area_exited(area):
	if area.is_in_group("Overworld_Player"):
		player_in_range = false

func _on_player_in_range_body_entered(body):
	if body.is_in_group("Overworld_Player"):
		player_in_range = true

func _on_player_in_range_body_exited(body):
	if body.is_in_group("Overworld_Player"):
		player_in_range = false
		if player_is_speaking_to_me:
			end_dialogue()

func _on_npc_clickable_body_entered(_body):
	pass

func _on_npc_clickable_body_exited(_body):
	pass

func _on_button_button_down():
	if player_in_range:
		begin_dialogue()
