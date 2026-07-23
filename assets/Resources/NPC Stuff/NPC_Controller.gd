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
const DEFAULT_SCHEDULE_TRAVEL_MINUTES: int = 30
const DEFAULT_OVERWORLD_SPRITE_DISPLAY_HEIGHT: float = 36.0
const LOCATION_ARRIVAL_FACING_OVERRIDES: Dictionary = {
	"Practice Field": "right",
	"HerbCollecting": "down",
	"Tavern_Counter": "down",
	"CounterSell": "down",
	"Bridge": "down",
	"CliffSide": "right",
	"Well": "left"
}
var current_destination = null

@onready var clickable_area : Area2D = $NPC_Clickable
@onready var check_player_in_range: Area2D = $Player_In_Range
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shop_controller: Node = get_node_or_null("CanvasLayer/ShopInterface")

@onready var menu_tab = get_node_or_null("CanvasLayer/MenuTabs")


@export_file("*.json") var dialogue_path: String
@export var npc_id: String = ""
@export var bond_combatant: generic_combatants
@export var location_container: Node2D
@export var speed: float = 75.0
@export_file("*.json") var schedule_path: String
@export var default_z_index: int = 0
@export var counter_z_index: int = 0
@export var counter_draw_order_y: float = -720.0
@export var use_counter_draw_order: bool = false
@export var auto_match_player_visual_height: bool = true
@export var overworld_sprite_display_height: float = DEFAULT_OVERWORLD_SPRITE_DISPLAY_HEIGHT
@export_range(0, 8, 1) var side_idle_pose_frame: int = CharacterAnimationDriver.DEFAULT_SIDE_IDLE_POSE_FRAME

var cached_overworld_sprite_frame_height: float = 0.0
var schedule_info
var loaded_schedule_day: int = -1
var traveling_to : int
var just_swapped_scenes: bool = false
var last_applied_schedule_key: String = ""
var schedule_paused_for_cutscene: bool = false
var cutscene_restore_state: Dictionary = {}
var cutscene_motion_direction: Vector2 = Vector2.ZERO
var animation_driver: CharacterAnimationDriver = CharacterAnimationDriver.new()

func tab_changed(tab):
	if tab == 0:
		$%ShopInterface.visible = true
		$%ShopInterface2.visible = false
	else:
		$%ShopInterface.visible = false
		$%ShopInterface2.visible = true

func _ready():
	animation_driver.side_idle_pose_frame = side_idle_pose_frame
	apply_overworld_sprite_scale()
	call_deferred("apply_overworld_sprite_scale")
	if shop_controller != null:
		shop_controller.shop_closed.connect(close_shop)
		$%ShopInterface2.shop_closed.connect(close_shop)
	Global.time_updated.connect(navigate)
	if dialogue_path.is_empty():
		print("Error: JSON file path is not set in the editor.")
		return
	schedule_info = {}
	if not schedule_path.is_empty():
		load_schedule_info()
	ensure_location_container()
	
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
	
	if menu_tab != null:
		menu_tab._setup(["Buy", "Sell"])
		menu_tab.selection_changed.connect(tab_changed)
	
	navigate.call_deferred()

func apply_overworld_sprite_scale() -> void:
	if not auto_match_player_visual_height:
		return
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	var frame_height := get_cached_overworld_sprite_frame_height()
	if frame_height <= 0.0:
		return
	var inherited_y_scale := absf(global_transform.get_scale().y)
	if inherited_y_scale <= 0.0:
		inherited_y_scale = 1.0
	var target_display_height := get_player_overworld_sprite_display_height()
	var display_scale := target_display_height / (frame_height * inherited_y_scale)
	animated_sprite.scale = Vector2(display_scale, display_scale)

func get_cached_overworld_sprite_frame_height() -> float:
	if cached_overworld_sprite_frame_height <= 0.0 and animated_sprite != null and animated_sprite.sprite_frames != null:
		cached_overworld_sprite_frame_height = get_first_sprite_frame_height(animated_sprite.sprite_frames)
	return cached_overworld_sprite_frame_height

func get_player_overworld_sprite_display_height() -> float:
	if not is_inside_tree():
		return overworld_sprite_display_height
	var player_sprite := get_player_animated_sprite()
	if player_sprite == null or player_sprite.sprite_frames == null:
		return overworld_sprite_display_height
	var player_frame_height := get_first_sprite_frame_height(player_sprite.sprite_frames)
	var player_y_scale := absf(player_sprite.global_transform.get_scale().y)
	if player_frame_height <= 0.0 or player_y_scale <= 0.0:
		return overworld_sprite_display_height
	return player_frame_height * player_y_scale

func get_player_animated_sprite() -> AnimatedSprite2D:
	if not is_inside_tree():
		return null
	var candidates := get_tree().get_nodes_in_group("Overworld_Player")
	for candidate in candidates:
		var candidate_node := candidate as Node
		if candidate_node == null:
			continue
		var player_sprite := candidate_node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if player_sprite != null:
			return player_sprite
	return null

func get_first_sprite_frame_height(sprite_frames: SpriteFrames) -> float:
	for animation_name in sprite_frames.get_animation_names():
		var frame_count := sprite_frames.get_frame_count(animation_name)
		for frame_index in range(frame_count):
			var frame_texture := sprite_frames.get_frame_texture(animation_name, frame_index)
			if frame_texture != null:
				var visible_height := get_visible_texture_height(frame_texture)
				if visible_height > 0.0:
					return visible_height
				return float(frame_texture.get_height())
	return 0.0

func get_visible_texture_height(texture: Texture2D) -> float:
	var image: Image
	var frame_region := Rect2i(Vector2i.ZERO, Vector2i(texture.get_width(), texture.get_height()))

	if texture is AtlasTexture:
		var atlas_texture := texture as AtlasTexture
		if atlas_texture.atlas == null:
			return 0.0
		image = atlas_texture.atlas.get_image()
		var atlas_region := atlas_texture.region
		frame_region = Rect2i(
			Vector2i(int(atlas_region.position.x), int(atlas_region.position.y)),
			Vector2i(int(atlas_region.size.x), int(atlas_region.size.y))
		)
	else:
		image = texture.get_image()

	if image == null:
		return 0.0

	var start_x := clampi(frame_region.position.x, 0, image.get_width())
	var start_y := clampi(frame_region.position.y, 0, image.get_height())
	var end_x := clampi(frame_region.position.x + frame_region.size.x, 0, image.get_width())
	var end_y := clampi(frame_region.position.y + frame_region.size.y, 0, image.get_height())
	var min_y := end_y
	var max_y := start_y - 1

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			if image.get_pixel(x, y).a > 0.05:
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)

	if max_y < min_y:
		return 0.0
	return float(max_y - min_y + 1)


# If there is no schedule to execute, or if player is talking, do nothing
# If player stopped talking, wait 3 seconds till they start going again 
# Otherwise have the npc move towards their destination
func _process(delta):
	update_schedule_draw_order()
	if schedule_paused_for_cutscene:
		animation_driver.sync(animated_sprite, cutscene_motion_direction)
		return
	if path_nodes.is_empty():
		walking = false
		apply_location_facing(current_destination)
		animation_driver.sync(animated_sprite, Vector2.ZERO)
		if leaving_scene:
			set_schedule_presence(false)
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
	if not visible:
		set_schedule_presence(true)
	var current_target = path_nodes[0]
	just_swapped_scenes = false
	var motion: Vector2 = current_target - global_position
	animation_driver.sync(animated_sprite, motion)
	global_position = global_position.move_toward(current_target, speed * delta)
	
	if global_position.distance_to(current_target) < 0.1:
		global_position = current_target
		path_nodes.pop_front() 
		if path_nodes.is_empty():
			apply_location_facing(current_destination)

func update_schedule_draw_order() -> void:
	if not use_counter_draw_order:
		return
	if global_position.y <= counter_draw_order_y:
		z_index = counter_z_index
	else:
		z_index = default_z_index

func set_schedule_presence(is_present: bool) -> void:
	visible = is_present
	set_interaction_area_enabled(clickable_area, is_present)
	set_interaction_area_enabled(check_player_in_range, is_present)
	if not is_present:
		player_in_range = false
		player_is_speaking_to_me = false
		player_just_stopped_talking_to_me = false
		pending_choice_action = ""

func set_interaction_area_enabled(area: Area2D, is_enabled: bool) -> void:
	if area == null:
		return
	area.monitoring = is_enabled
	area.monitorable = is_enabled
	area.input_pickable = is_enabled
	for child in area.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", not is_enabled)

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
	if not schedule_path.is_empty() and loaded_schedule_day != Global.current_day:
		load_schedule_info()
	if schedule_paused_for_cutscene:
		return
	if not (schedule_info is Dictionary) or not schedule_info.has("schedules"):
		return
	if not is_inside_tree() or get_tree().current_scene == null:
		return
	if not ensure_location_container():
		return
	var path = get_tree().current_scene.scene_file_path
	for schedule_name in schedule_info["schedules"]:
		var details = schedule_info["schedules"][schedule_name]
		if details["scene_swap"] == 1 and details["2_start_time_hour"] != 0:
			if is_schedule_scene_match(details["start_scene"], path):
				if check_time(details["start_time_hour"], details["start_time_minute"], 2):
					#print("NOT TIME YET")
					return
				elif check_time(details["start_time_hour"], details["start_time_minute"], 1):
					set_schedule_presence(true)
					setup_navigation(details, 0)
					leaving_scene = true
					if details["should_disappear"] == 1:
						set_schedule_presence(false)
					return
				elif check_time(details["2_start_time_hour"], details["2_start_time_minute"], 2) and just_swapped_scenes:
					print("TRYING AGAIN")
					set_schedule_presence(true)
					setup_navigation(details, 2)
					leaving_scene = true
					if details["should_disappear"] == 1:
						set_schedule_presence(false)
					return
			elif is_schedule_scene_match(details["end_scene"], path) and check_time(details["2_start_time_hour"], details["2_start_time_minute"], 1):
				leaving_scene = true
				set_schedule_presence(true)
				setup_navigation(details, 1)
				if details["should_disappear"] == 1:
					set_schedule_presence(false)
				return
		elif is_schedule_scene_match(details["start_scene"], path) and check_time(details["start_time_hour"], details["start_time_minute"], 1):
			last_applied_schedule_key = get_schedule_key(schedule_name, details)
			set_schedule_presence(true)
			setup_navigation(details, 0)
			leaving_scene = int(details.get("hide_on_arrival", 0)) == 1
			if details["should_disappear"] == 1:
				set_schedule_presence(false)
			return
	catch_up_to_scene_schedule(path)

func load_schedule_info() -> void:
	loaded_schedule_day = Global.current_day
	schedule_info = {}
	last_applied_schedule_key = ""
	path_nodes.clear()
	walking = false
	leaving_scene = false
	var file = FileAccess.open(schedule_path, FileAccess.READ)
	if file == null:
		push_warning("NPC_Controller: Could not open schedule file %s." % schedule_path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return
	if parsed.has("days"):
		var day_name = get_weekday_name(Global.current_day)
		var days: Dictionary = parsed["days"]
		if days.has(day_name):
			schedule_info = days[day_name]
		elif days.has("default"):
			schedule_info = days["default"]
		else:
			schedule_info = {}
	else:
		schedule_info = parsed

func ensure_location_container() -> bool:
	if is_valid_location_container(location_container):
		return true
	if not is_inside_tree() or get_tree().current_scene == null:
		return false
	for container in get_location_container_candidates(get_tree().current_scene):
		if is_valid_location_container(container):
			location_container = container
			return true
	return false

func ensure_location_container_for_locations(start_location, end_location = null) -> bool:
	if is_location_container_for_schedule(location_container, start_location, end_location):
		return true
	if not is_inside_tree() or get_tree().current_scene == null:
		return false
	for container in get_location_container_candidates(get_tree().current_scene):
		if is_location_container_for_schedule(container, start_location, end_location):
			location_container = container
			return true
	return ensure_location_container()

func get_location_container_candidates(root_node: Node) -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	collect_location_container_candidates(root_node, candidates)
	return candidates

func collect_location_container_candidates(node: Node, candidates: Array[Node2D]) -> void:
	if node is Node2D and is_valid_location_container(node) and (str(node.name).contains("LocationContainer") or node.has_method("get_path_between")):
		candidates.append(node as Node2D)
	for child in node.get_children():
		collect_location_container_candidates(child, candidates)

func is_location_container_for_schedule(container: Node, start_location, end_location = null) -> bool:
	if not is_valid_location_container(container):
		return false
	if not can_container_resolve_location(container, start_location):
		return false
	if end_location == null:
		return true
	return can_container_resolve_location(container, end_location)

func can_container_resolve_location(container: Node, location) -> bool:
	match typeof(location):
		TYPE_INT:
			return int(location) >= 0 and int(location) < container.get_child_count()
		TYPE_FLOAT:
			var location_index := int(location)
			return location_index >= 0 and location_index < container.get_child_count()
		TYPE_STRING:
			var location_name := str(location).strip_edges()
			if location_name.is_empty():
				return false
			if container.get_node_or_null(NodePath(location_name)) != null:
				return true
			var normalized_location_name := normalize_location_name(location_name)
			for child in container.get_children():
				if normalize_location_name(str(child.name)) == normalized_location_name:
					return true
			if location_name.is_valid_int():
				var numeric_index := int(location_name)
				return numeric_index >= 0 and numeric_index < container.get_child_count()
	return false

func is_valid_location_container(container: Node) -> bool:
	return container != null and container is Node2D and container.get_child_count() > 0

func get_weekday_name(day_index: int) -> String:
	var day_names: Array[String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
	return day_names[posmod(day_index, day_names.size())]

func get_schedule_minutes(details: Dictionary) -> int:
	return (int(details["start_time_hour"]) * 60) + int(details["start_time_minute"])

func get_current_day_minutes() -> int:
	return (Global.current_hour * 60) + Global.current_minute

func get_schedule_key(schedule_name: String, details: Dictionary) -> String:
	return str(Global.current_year) + ":" + str(Global.current_day) + ":" + schedule_name + ":" + str(details["start_time_hour"]) + ":" + str(details["start_time_minute"])

func is_schedule_scene_match(schedule_scene, current_scene_path: String) -> bool:
	var schedule_path := str(schedule_scene)
	if schedule_path == current_scene_path:
		return true
	return get_schedule_scene_alias(schedule_path) == get_schedule_scene_alias(current_scene_path)

func get_schedule_scene_alias(scene_path: String) -> String:
	match scene_path:
		"res://scenes/main/Hearthwynn.tscn", "res://scenes/main/hearthwynn.res":
			return "hearthwynn"
		"res://scenes/main/Building Insides.tscn", "res://scenes/main/new_building_insides.res":
			return "building_insides"
	return scene_path.to_lower()

func catch_up_to_scene_schedule(path: String) -> void:
	var current_minutes = get_current_day_minutes()
	var latest_schedule_name = ""
	var latest_details: Dictionary = {}
	var latest_minutes = -1
	for schedule_name in schedule_info["schedules"]:
		var details: Dictionary = schedule_info["schedules"][schedule_name]
		if details["scene_swap"] != 0 or not is_schedule_scene_match(details["start_scene"], path):
			continue
		var schedule_minutes = get_schedule_minutes(details)
		if schedule_minutes <= current_minutes and schedule_minutes > latest_minutes:
			latest_schedule_name = schedule_name
			latest_details = details
			latest_minutes = schedule_minutes
	if latest_details.is_empty():
		return
	var schedule_key = get_schedule_key(latest_schedule_name, latest_details)
	if schedule_key == last_applied_schedule_key:
		return
	last_applied_schedule_key = schedule_key
	path_nodes.clear()
	walking = false
	leaving_scene = int(latest_details.get("hide_on_arrival", 0)) == 1
	set_schedule_presence(int(latest_details.get("should_disappear", 0)) != 1)
	catch_up_along_path(latest_details, current_minutes - latest_minutes)

func catch_up_along_path(details: Dictionary, elapsed_minutes: int) -> void:
	if not ensure_location_container():
		return
	current_destination = details["end_location"]
	var travel_minutes = max(1, int(details.get("travel_minutes", DEFAULT_SCHEDULE_TRAVEL_MINUTES)))
	var path_ids = get_schedule_path_ids(details, "start_location", "end_location")
	if path_ids.is_empty():
		return
	if elapsed_minutes >= travel_minutes:
		place_at_location(details["end_location"])
		if int(details.get("hide_on_arrival", 0)) == 1:
			set_schedule_presence(false)
		return
	var points: Array[Vector2] = []
	for vertex_id in path_ids:
		points.append(get_location_global_position(vertex_id))
	var total_distance = get_path_distance(points)
	if total_distance <= 0.0:
		place_at_location(details["end_location"])
		if int(details.get("hide_on_arrival", 0)) == 1:
			set_schedule_presence(false)
		return
	var target_distance = total_distance * (float(elapsed_minutes) / float(travel_minutes))
	place_along_points(points, target_distance)

func get_path_distance(points: Array[Vector2]) -> float:
	var distance = 0.0
	for index in range(points.size() - 1):
		distance += points[index].distance_to(points[index + 1])
	return distance

func place_along_points(points: Array[Vector2], target_distance: float) -> void:
	path_nodes.clear()
	var distance_left = target_distance
	for index in range(points.size() - 1):
		var segment_start = points[index]
		var segment_end = points[index + 1]
		var segment_length = segment_start.distance_to(segment_end)
		if distance_left <= segment_length:
			var segment_progress = 0.0
			if segment_length > 0.0:
				segment_progress = distance_left / segment_length
			global_position = segment_start.lerp(segment_end, segment_progress)
			path_nodes.append(segment_end)
			for remaining_index in range(index + 2, points.size()):
				path_nodes.append(points[remaining_index])
			return
		distance_left -= segment_length
	global_position = points[points.size() - 1]

func check_time(start_time_hour, start_time_minutes, before_equal_after):
	match before_equal_after:
		0:
			var schedule_total = Global.get_time_total_minutes(Global.current_day, start_time_hour, start_time_minutes)
			var current_total = Global.get_time_total_minutes(Global.current_day, Global.current_hour, Global.current_minute)
			return schedule_total < current_total
		1:
			return Global.did_time_reach(start_time_hour, start_time_minutes)
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
			set_schedule_path(schedule_info_basic, "start_location", "end_location", true)
		1:
			set_schedule_path(schedule_info_basic, "2_start_location", "2_end_location", true)
		# resume schedule
		2:
			var temp_path = location_container.get_path_between(schedule_info_basic["start_location"], schedule_info_basic["end_location"])
			var time_diff = ((schedule_info_basic["2_start_time_hour"] - Global.current_hour) * 60) - (schedule_info_basic["2_start_time_minute"] - Global.current_minute)
			var start_diff = (( schedule_info_basic["2_start_time_hour"] - schedule_info_basic["start_time_hour"]) * 60) - (schedule_info_basic["2_start_time_minute"] - schedule_info_basic["2_start_time_minute"])
			var final_diff = time_diff / start_diff
			var path_start = (temp_path.size() - 1) * final_diff
			if floor(path_start) == location_container.get_child_count():
				path_start -= 1
			set_path(floor(path_start), schedule_info_basic["end_location"], true)
		3:
			var temp_path = location_container.get_path_between(schedule_info_basic["start_location"], schedule_info_basic["end_location"])
			var time_diff = ((schedule_info_basic["end_time_hour"] - Global.current_hour) * 60) - (Global.current_minute)
			var start_diff = ((schedule_info_basic["end_time_hour"] - schedule_info_basic["start_time_hour"]) * 60) - schedule_info_basic["start_time_minute"] + schedule_info_basic["end_time_minute"]
			var final_diff = time_diff / start_diff
			var path_start = temp_path.size() * final_diff

			set_path(floor(path_start), schedule_info_basic["end_location"], true)
			

func set_path(start_point, end_point, snap_to_start: bool = false):
	if not ensure_location_container_for_locations(start_point, end_point):
		return
	current_destination = end_point
	var start_index = get_location_index(start_point)
	if not location_container.has_method("get_path_between"):
		var end_index = get_location_index(end_point)
		if start_index >= 0 and start_index == end_index:
			set_path_nodes([start_index], start_index, start_point, end_point, snap_to_start)
		return
	var path_ids = location_container.get_path_between(start_point, end_point)
	set_path_nodes(path_ids, start_index, start_point, end_point, snap_to_start)

func set_schedule_path(schedule_info_basic: Dictionary, start_key: String, end_key: String, snap_to_start: bool = false) -> void:
	if not ensure_location_container_for_locations(schedule_info_basic[start_key], schedule_info_basic[end_key]):
		return
	var start_point = schedule_info_basic[start_key]
	var end_point = schedule_info_basic[end_key]
	current_destination = end_point
	var path_ids = get_schedule_path_ids(schedule_info_basic, start_key, end_key)
	var start_index = get_location_index(start_point)
	set_path_nodes(path_ids, start_index, start_point, end_point, snap_to_start)

func get_schedule_path_ids(schedule_info_basic: Dictionary, start_key: String, end_key: String) -> Array[int]:
	if not ensure_location_container_for_locations(schedule_info_basic[start_key], schedule_info_basic[end_key]):
		return []
	var start_location_index = get_location_index(schedule_info_basic[start_key])
	var end_location_index = get_location_index(schedule_info_basic[end_key])
	if start_location_index >= 0 and start_location_index == end_location_index:
		return [start_location_index]
	var tried_graph := false
	if location_container.has_method("get_path_between"):
		tried_graph = true
		var graph_path: Array[int] = location_container.get_path_between(schedule_info_basic[start_key], schedule_info_basic[end_key])
		if not graph_path.is_empty():
			return graph_path

	var path_locations_key := "path_locations"
	if start_key.begins_with("2_"):
		path_locations_key = "2_path_locations"
	var explicit_path = schedule_info_basic.get(path_locations_key, [])
	if explicit_path is Array and not explicit_path.is_empty():
		var explicit_path_ids: Array[int] = []
		var resolved_all_locations := true
		for location in explicit_path:
			var location_index = get_location_index(location)
			if location_index < 0 or location_index >= location_container.get_child_count():
				push_warning("NPC_Controller: Could not resolve explicit schedule path location '%s' in %s." % [str(location), schedule_path])
				resolved_all_locations = false
				break
			if explicit_path_ids.is_empty() or explicit_path_ids[explicit_path_ids.size() - 1] != location_index:
				explicit_path_ids.append(location_index)
		if resolved_all_locations and not explicit_path_ids.is_empty():
			if tried_graph:
				push_warning("NPC_Controller: Using explicit fallback route for '%s' -> '%s' in %s because no graph route was available." % [str(schedule_info_basic[start_key]), str(schedule_info_basic[end_key]), schedule_path])
			return explicit_path_ids
	return []

func get_location_index(location) -> int:
	if location_container == null:
		return -1
	if location_container.has_method("get_location_index"):
		return int(location_container.get_location_index(location))
	match typeof(location):
		TYPE_INT:
			return location
		TYPE_FLOAT:
			return int(location)
		TYPE_STRING:
			var location_name = str(location).strip_edges()
			if location_name.is_empty():
				return -1
			var location_node = location_container.get_node_or_null(NodePath(location_name))
			if location_node != null:
				return location_node.get_index()
			var numeric_index: int = -1
			if location_name.is_valid_int():
				numeric_index = int(location_name)
			var normalized_location_name = normalize_location_name(location_name)
			var normalized_index = get_location_index_by_normalized_name(normalized_location_name)
			if normalized_index >= 0:
				return normalized_index
			var numbered_name_index = get_location_index_by_numeric_suffix(normalized_location_name)
			if numbered_name_index >= 0:
				return numbered_name_index
			if numeric_index >= 0:
				return numeric_index
	return -1

func get_location_index_by_normalized_name(normalized_location_name: String) -> int:
	if location_container == null:
		return -1
	for child in location_container.get_children():
		if normalize_location_name(str(child.name)) == normalized_location_name:
			return child.get_index()
	return -1

func get_location_index_by_numeric_suffix(normalized_location_name: String) -> int:
	if location_container == null or not normalized_location_name.is_valid_int():
		return -1
	for child in location_container.get_children():
		var normalized_child_name = normalize_location_name(str(child.name))
		var suffix_start = normalized_child_name.length() - normalized_location_name.length()
		if suffix_start < 0:
			continue
		if normalized_child_name.substr(suffix_start) != normalized_location_name:
			continue
		if suffix_start == 0:
			return child.get_index()
		var previous_character = normalized_child_name.substr(suffix_start - 1, 1)
		if not previous_character.is_valid_int():
			return child.get_index()
	return -1

func normalize_location_name(location_name: String) -> String:
	return location_name.to_lower().replace(" ", "").replace("_", "").replace("-", "")

func set_path_nodes(path_ids: Array[int], start_index: int, start_point, end_point, snap_to_start: bool = false) -> void:
	path_nodes.clear()
	if path_ids.size() <= 1:
		place_at_location(end_point if path_ids.size() == 1 else start_point)
		current_destination = end_point
		return
	if snap_to_start:
		place_at_location(start_point)
		current_destination = end_point
	for vertex_id in path_ids:
		var target_pos = get_location_global_position(vertex_id)
		if vertex_id == start_index and not snap_to_start:
			global_position = target_pos
		path_nodes.append(target_pos)

func place_at_location(location):
	if not ensure_location_container_for_locations(location):
		return
	var location_index = get_location_index(location)
	if location_index < 0 or location_index >= location_container.get_child_count():
		return
	global_position = get_location_global_position(location_index)
	current_destination = location
	apply_location_facing(location)

func get_location_global_position(location_index: int) -> Vector2:
	var target_node := location_container.get_child(location_index) as Node2D
	if target_node == null:
		return global_position
	return target_node.global_position

func apply_location_facing(location) -> void:
	if location == null or animated_sprite == null:
		return
	if not ensure_location_container():
		return
	var location_index = get_location_index(location)
	if location_index < 0 or location_index >= location_container.get_child_count():
		return
	var target_node = location_container.get_child(location_index)
	var arrival_facing = ""
	if target_node.has_method("get_arrival_facing"):
		arrival_facing = str(target_node.get_arrival_facing())
	var override_arrival_facing = str(LOCATION_ARRIVAL_FACING_OVERRIDES.get(str(location), ""))
	if not override_arrival_facing.is_empty():
		arrival_facing = override_arrival_facing
	if arrival_facing.is_empty() or arrival_facing == "none":
		return
	animation_driver.face(animated_sprite, StringName(arrival_facing))

func pin_to_location_for_cutscene(location) -> void:
	if schedule_paused_for_cutscene:
		return

	cutscene_restore_state = {
		"global_position": global_position,
		"path_nodes": path_nodes.duplicate(),
		"walking": walking,
		"leaving_scene": leaving_scene,
		"visible": visible,
		"player_just_stopped_talking_to_me": player_just_stopped_talking_to_me,
		"running_time": running_time,
		"z_index": z_index
	}
	schedule_paused_for_cutscene = true
	cutscene_motion_direction = Vector2.ZERO
	path_nodes.clear()
	walking = false
	leaving_scene = false
	player_just_stopped_talking_to_me = false
	running_time = 0
	set_schedule_presence(true)
	place_at_location(location)
	animation_driver.sync(animated_sprite, Vector2.ZERO)

func pin_to_global_position_for_cutscene(target_position: Vector2, facing: StringName = &"down") -> void:
	if schedule_paused_for_cutscene:
		return

	cutscene_restore_state = {
		"global_position": global_position,
		"path_nodes": path_nodes.duplicate(),
		"walking": walking,
		"leaving_scene": leaving_scene,
		"visible": visible,
		"player_just_stopped_talking_to_me": player_just_stopped_talking_to_me,
		"running_time": running_time,
		"z_index": z_index
	}
	schedule_paused_for_cutscene = true
	cutscene_motion_direction = Vector2.ZERO
	path_nodes.clear()
	walking = false
	leaving_scene = false
	player_just_stopped_talking_to_me = false
	running_time = 0
	set_schedule_presence(true)
	global_position = target_position
	current_destination = null
	animation_driver.face(animated_sprite, facing)
	animation_driver.sync(animated_sprite, Vector2.ZERO)

func move_to_global_position_for_cutscene(target_position: Vector2, duration: float = 1.0, arrival_facing: StringName = &"down") -> Tween:
	if not schedule_paused_for_cutscene:
		pin_to_global_position_for_cutscene(global_position, arrival_facing)

	cutscene_motion_direction = target_position - global_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, duration)
	tween.finished.connect(func():
		cutscene_motion_direction = Vector2.ZERO
		animation_driver.face(animated_sprite, arrival_facing)
		animation_driver.sync(animated_sprite, Vector2.ZERO)
	)
	return tween

func move_along_global_positions_for_cutscene(target_positions: Array[Vector2], pixels_per_second: float = 90.0, arrival_facing: StringName = &"down") -> Tween:
	if not schedule_paused_for_cutscene:
		pin_to_global_position_for_cutscene(global_position, arrival_facing)

	var tween := create_tween()
	var segment_start: Vector2 = global_position
	for target_position in target_positions:
		var segment_motion: Vector2 = target_position - segment_start
		if segment_motion.length_squared() < 0.0001:
			segment_start = target_position
			continue
		var segment_duration: float = maxf(0.05, segment_motion.length() / maxf(1.0, pixels_per_second))
		tween.tween_callback(Callable(self, "set_cutscene_motion_direction").bind(segment_motion))
		tween.tween_property(self, "global_position", target_position, segment_duration)
		segment_start = target_position
	tween.tween_callback(Callable(self, "finish_cutscene_motion").bind(arrival_facing))
	return tween

func set_cutscene_motion_direction(direction: Vector2) -> void:
	cutscene_motion_direction = direction

func finish_cutscene_motion(arrival_facing: StringName) -> void:
	cutscene_motion_direction = Vector2.ZERO
	animation_driver.face(animated_sprite, arrival_facing)
	animation_driver.sync(animated_sprite, Vector2.ZERO)

func restore_after_cutscene() -> void:
	if not schedule_paused_for_cutscene:
		return

	global_position = cutscene_restore_state.get("global_position", global_position)
	path_nodes = cutscene_restore_state.get("path_nodes", []).duplicate()
	walking = bool(cutscene_restore_state.get("walking", false))
	leaving_scene = bool(cutscene_restore_state.get("leaving_scene", false))
	set_schedule_presence(bool(cutscene_restore_state.get("visible", visible)))
	player_just_stopped_talking_to_me = bool(cutscene_restore_state.get("player_just_stopped_talking_to_me", false))
	running_time = float(cutscene_restore_state.get("running_time", 0.0))
	z_index = int(cutscene_restore_state.get("z_index", z_index))
	cutscene_restore_state = {}
	schedule_paused_for_cutscene = false
	cutscene_motion_direction = Vector2.ZERO
	if not schedule_path.is_empty():
		path_nodes.clear()
		walking = false
		leaving_scene = false
		current_destination = null
		last_applied_schedule_key = ""
	animation_driver.sync(animated_sprite, Vector2.ZERO)
	navigate.call_deferred()

# This shouldn't really exist (the cancel operation), only does for testing purposes
# Currently only makes it so when you press cancel (x) it closes the dialogue box
func _input(event):
	if Global.is_in_menu and not player_is_speaking_to_me:
		return

	if not player_in_range:
		return

	if player_is_speaking_to_me:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_BRACKETRIGHT:
			debug_skip_dialogue()
			get_viewport().set_input_as_handled()
			return
		if Global.get_input_mapping("cancel"):
			end_dialogue()
		return

	if Global.get_input_mapping("confirm") or event.is_action_pressed("Mouse_Right_Click"):
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

func debug_skip_dialogue() -> void:
	end_dialogue()

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

	if action == "start_lyra_axe_quest":
		Global.start_lyra_axe_quest()

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
	if shop_controller != null:
		show_shop()
		return

	push_warning("NPC_Controller: No ShopController child found to open.")

func show_shop():
	$CanvasLayer/MenuTabs.cycle_input(null, -1)
	$CanvasLayer.visible = true
	$%ShopInterface.visible = true
	$%ShopInterface2.visible = false
	Global.is_paused = true
	Global.is_in_menu = true
	
func close_shop():
	$CanvasLayer.visible = false
	Global.is_paused = false
	Global.is_in_menu = false
	$%ShopInterface.visible = false
	$%ShopInterface2.visible = false

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
