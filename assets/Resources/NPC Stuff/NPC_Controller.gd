extends Node2D

var dialogue_data: Dictionary

var path_nodes: Array[Vector2]
var walking: bool = false
var leaving_scene: bool = false

var running_time: float = 0

var player_in_range: bool = false
var player_is_speaking_to_me: bool = false
var player_just_stopped_talking_to_me: bool = false
var pending_choice_action: String = ""

var current_location

@onready var clickable_area : Area2D = $NPC_Clickable
@onready var check_player_in_range: Area2D = $Player_In_Range
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shop_controller: Node = get_node_or_null("ShopController")

@export_file("*.json") var dialogue_path: String
@export var npc_id: String = ""
@export var bond_combatant: generic_combatants
@export var location_container: Node2D
@export var speed: float = 300.0
@export_file("*.json") var schedule_path: String

var schedule_info
var traveling_to : int
var just_swapped_scenes: bool = false
var animation_driver: CharacterAnimationDriver = CharacterAnimationDriver.new()

func _ready():
	Global.time_updated.connect(navigate)
	if dialogue_path.is_empty():
		print("Error: JSON file path is not set in the editor.")
		return
	schedule_info = {}
	if not schedule_path.is_empty():
		var file = FileAccess.open(schedule_path, FileAccess.READ)
		if file != null:
			var json_string = file.get_as_text()
			file.close()
			schedule_info = JSON.parse_string(json_string)
	
	dialogue_data = load_json_file(dialogue_path)
	var dialogue_system = get_node_or_null("/root/DialogueSystem")
	if dialogue_system != null and dialogue_system.has_signal("dialogue_closed"):
		var dialogue_closed_callback = Callable(self, "_on_dialogue_system_dialogue_closed")
		if not dialogue_system.dialogue_closed.is_connected(dialogue_closed_callback):
			dialogue_system.dialogue_closed.connect(dialogue_closed_callback)
	if dialogue_system != null and dialogue_system.has_signal("choice_action_requested"):
		var choice_action_callback = Callable(self, "_on_dialogue_system_choice_action_requested")
		if not dialogue_system.choice_action_requested.is_connected(choice_action_callback):
			dialogue_system.choice_action_requested.connect(choice_action_callback)
	just_swapped_scenes = true


# If there is no schedule to execute, or if player is talking, do nothing
# If player stopped talking, wait 3 seconds till they start going again 
# Otherwise have the npc move towards their destination
func _process(delta):
	if path_nodes.is_empty():
		walking = false
		animation_driver.sync(animated_sprite, Vector2.ZERO)
		if leaving_scene:
			self.visible = false
		return 
	if player_is_speaking_to_me:
		animation_driver.sync(animated_sprite, Vector2.ZERO)
		return
	
	if player_just_stopped_talking_to_me:
		running_time += delta
		
		if running_time >= 3:
			player_just_stopped_talking_to_me = false
			running_time = 0
		animation_driver.sync(animated_sprite, Vector2.ZERO)
		return
	walking = true
	self.visible = true
	var current_target = path_nodes[0]
	just_swapped_scenes = false
	var motion: Vector2 = current_target - global_position
	animation_driver.sync(animated_sprite, motion)
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
	if not (schedule_info is Dictionary) or not schedule_info.has("schedules"):
		return
	if walking == true:
		return
	if not is_inside_tree() or get_tree().current_scene == null:
		return
	for schedule_name in schedule_info["schedules"]:
		var details = schedule_info["schedules"][schedule_name]
		var path = get_tree().current_scene.scene_file_path
		if details["scene_swap"] == 1 and details["2_start_time_hour"] != 0:
			if details["start_scene"] == path:
				if check_time(details["start_time_hour"], details["start_time_minute"], 2):
					#print("NOT TIME YET")
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
	var start_index = location_container.get_location_index(start_point)
	path_nodes.clear()
	for vertex_id in path_ids:
		var target_node = location_container.get_child(vertex_id)
		var target_pos = target_node.location_position[2] 
		if vertex_id == start_index:
			self.position = target_pos
		path_nodes.append(target_pos)

# This shouldn't really exist (the cancel operation), only does for testing purposes
# Currently only makes it so when you press cancel (x) it closes the dialogue box
func _input(event):
	if Global.is_in_menu and not player_is_speaking_to_me:
		return

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
	if Global.is_in_menu:
		return

	if player_in_range:
		if event.is_action_pressed("Mouse_Right_Click"):
			begin_dialogue()

func begin_dialogue() -> void:
	if player_is_speaking_to_me:
		return

	pending_choice_action = ""
	var dialogue_system = get_node_or_null("/root/DialogueSystem")
	if dialogue_system == null or not dialogue_system.has_method("show_dialog"):
		push_warning("NPC_Controller: DialogueSystem autoload is missing.")
		return
	if dialogue_path.is_empty():
		push_warning("NPC_Controller: dialogue_path is empty.")
		return

	dialogue_system.dialogue_file_path = dialogue_path
	dialogue_system.dialogue_start_node_id = get_dialogue_start_node_id()
	dialogue_system.dialogue_context = get_dialogue_context()
	sync_bond_to_combatant()
	if dialogue_system.show_dialog():
		player_is_speaking_to_me = true

func get_dialogue_start_node_id() -> String:
	if npc_id.is_empty():
		return ""
	var bond_info = Global.get_npc_bond_info(npc_id)
	var bond_starts = dialogue_data.get("bond_starts", {})
	if typeof(bond_starts) == TYPE_DICTIONARY and bond_starts.has(bond_info["tier_name"]):
		return str(bond_starts[bond_info["tier_name"]])
	return ""

func get_dialogue_context() -> Dictionary:
	if npc_id.is_empty():
		return {}
	var bond_info = Global.get_npc_bond_info(npc_id)
	return {
		"npc_id": npc_id,
		"bond_tier": bond_info["tier_name"],
		"bond_exp": bond_info["exp"],
		"last_talk_day": bond_info["last_talk_day"],
		"can_daily_talk": int(bond_info["last_talk_day"]) != Global.current_day
	}

func sync_bond_to_combatant() -> void:
	if npc_id.is_empty() or bond_combatant == null:
		return
	var bond_info = Global.get_npc_bond_info(npc_id)
	bond_combatant.bond_points = int(bond_info["exp"])

func end_dialogue() -> void:
	if not player_is_speaking_to_me:
		return

	var dialogue_system = get_node_or_null("/root/DialogueSystem")
	if dialogue_system != null and dialogue_system.has_method("hide_dialog"):
		dialogue_system.hide_dialog()
	else:
		_on_dialogue_system_dialogue_closed()

func _on_dialogue_system_dialogue_closed() -> void:
	if not player_is_speaking_to_me:
		return

	player_is_speaking_to_me = false
	player_just_stopped_talking_to_me = true
	Global.is_in_menu = false
	if pending_choice_action == "open_shop":
		pending_choice_action = ""
		open_shop()
		return
	pending_choice_action = ""

func _on_dialogue_system_choice_action_requested(action: String, choice_data: Dictionary) -> void:
	if not player_is_speaking_to_me:
		return

	if not npc_id.is_empty():
		if bool(choice_data.get("daily_talk_bond", false)):
			Global.add_daily_talk_bond(npc_id)
		var bond_delta: int = int(choice_data.get("bond_delta", 0))
		if bond_delta != 0:
			var reason = action if not action.is_empty() else "dialogue choice"
			Global.add_npc_bond_exp(npc_id, bond_delta, reason)
		sync_bond_to_combatant()

	pending_choice_action = action

func open_shop() -> void:
	if shop_controller != null and shop_controller.has_method("show_shop"):
		shop_controller.show_shop()
		return

	push_warning("NPC_Controller: No ShopController child found to open.")

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
