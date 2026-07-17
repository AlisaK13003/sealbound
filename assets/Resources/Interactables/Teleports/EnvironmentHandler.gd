extends Node2D

const CUTSCENE_RUNNER_SCRIPT = preload("res://assets/Scripts/cutscene_runner.gd")
const BORDER_THICKNESS := 64.0

@export var is_building_insides: bool = false

@export var bgm: AudioStream

var player_node

func swap_to_me():
	player_node = get_tree().get_first_node_in_group("Overworld_Player")
	var entry_loading_zone: String = Global.current_loading_zone
	await teleport_player_to_spawn()

	AudioManager.play_bgm(bgm, true)
	set_camera_limits()
	
	var cutscene_to_start
	for potential_cutscene in StateManager.story_triggers:
		if StateManager.should_trigger(potential_cutscene):
			print("TRIGGERED: ", potential_cutscene)
			match potential_cutscene:
				"lyra_tavern_cutscene":
					cutscene_to_start = potential_cutscene
					prepare_lyra_tavern_cutscene()
					refresh_player_camera()
					await get_tree().process_frame
					refresh_player_camera()
				"turning_in_lyra_axe_cutscene":
					print("RETURN AXE")
					StateManager.pseduo_story_time = Global.current_day
					GlobalCombatInformation.complete_quest(GlobalCombatInformation.active_quests[GlobalCombatInformation.active_quests.find_custom(func(stored_quest: quest): return stored_quest.quest_name == "Find Lyra's Axe")])
					StateManager.set_dungeon_unlock(StateManager.dungeon_state_lookup.FOREST_DUNGEON_UNLOCKED, true)
					StateManager.set_story_state(StateManager.story_beats_lookup.TURNED_IN_LYRA_QUEST, true)
				"quest_board_unlock_cutscene":
					print("COMPLETED LYRA QUEST")
					StateManager.set_story_state(StateManager.story_beats_lookup.QUEST_BOARD_UNLOCK, true)
					StateManager.set_party_member_unlock(StateManager.party_member_unlock_lookup.SERA_UNLOCKED)
					StateManager.set_party_member_unlock(StateManager.party_member_unlock_lookup.LYRA_UNLOCKED)
					

	await get_tree().create_timer(0.5).timeout
	await Fade.fade_out(0.5)

	match cutscene_to_start:
		"lyra_tavern_cutscene":
			start_lyra_tavern_cutscene()
	
func teleport_player_to_spawn():
	if player_node == null:
		return

	if Global.has_pending_player_spawn_position:
		_apply_pending_player_spawn_position()
		return

	if Global.current_loading_zone == "":
		_apply_pending_player_spawn_position()
		return
		
	var spawn_point = find_loading_zone_spawn(Global.current_loading_zone)
	spawn_point = spawn_point.find_child("Marker2D")
	if spawn_point == null:
		push_warning("EnvironmentHandler: Could not find loading zone spawn '%s' in %s." % [Global.current_loading_zone, scene_file_path])
		_apply_pending_player_spawn_position()
		return
	
	#if is_building_insides:
	#	spawn_point = spawn_point
	#else:
	#	spawn_point = spawn_point.get_child(0)
	
	await get_tree().physics_frame
	player_node.global_position = spawn_point.global_position
	#_apply_pending_player_spawn_position()

func _apply_pending_player_spawn_position() -> void:
	if Global.has_pending_player_spawn_position and player_node != null:
		player_node.global_position = Global.pending_player_spawn_position
		Global.has_pending_player_spawn_position = false

func prepare_lyra_tavern_cutscene() -> void:
	if player_node != null:
		player_node.global_position = $Tavern/LoadingZone/Marker2D.global_position

	var lyra_node = find_child("Lyra_NPC", true, false)
	if lyra_node != null and lyra_node.has_method("pin_to_location_for_cutscene"):
		lyra_node.pin_to_location_for_cutscene("Tavern_Counter")

func refresh_player_camera() -> void:
	if player_node == null:
		return
	var camera = get_node_or_null("UniversalCamera")
	if camera == null:
		return
	if camera.has_method("reset_smoothing"):
		camera.reset_smoothing()
	if camera.has_method("force_update_scroll"):
		camera.force_update_scroll()

func start_lyra_tavern_cutscene() -> void:
	var runner = CUTSCENE_RUNNER_SCRIPT.new()
	get_tree().current_scene.add_child(runner)
	runner.finished.connect(runner.queue_free)
	var lyra_node = find_child("Lyra_NPC", true, false)
	if lyra_node != null and lyra_node.has_method("restore_after_cutscene"):
		runner.finished.connect(Callable(self, "restore_cutscene_actor").bind(lyra_node))
	runner.play(Global.LYRA_TAVERN_CUTSCENE_PATH)

func restore_cutscene_actor(actor: Node) -> void:
	if is_instance_valid(actor) and actor.has_method("restore_after_cutscene"):
		actor.restore_after_cutscene()

func build_world_border(top_left: Vector2, bottom_right: Vector2) -> void:
	if has_node("WorldBorder"):
		return  # scene instances are reused; build once per session
	var border := StaticBody2D.new()
	border.name = "WorldBorder"
	border.top_level = true  # use global coords, ignore any root rotation (Cliff has one)
	add_child(border)

	var w := bottom_right.x - top_left.x
	var h := bottom_right.y - top_left.y
	var cx := (top_left.x + bottom_right.x) * 0.5
	var cy := (top_left.y + bottom_right.y) * 0.5
	var t := BORDER_THICKNESS

	# [center, size] per edge; top/bottom overhang by 2t to seal the corners
	var edges := [
		[Vector2(cx, top_left.y - t * 0.5), Vector2(w + t * 2.0, t)],      # top
		[Vector2(cx, bottom_right.y + t * 0.5), Vector2(w + t * 2.0, t)],  # bottom
		[Vector2(top_left.x - t * 0.5, cy), Vector2(t, h)],                # left
		[Vector2(bottom_right.x + t * 0.5, cy), Vector2(t, h)],           # right
	]
	for edge in edges:
		var shape := RectangleShape2D.new()
		shape.size = edge[1]
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = edge[0]
		border.add_child(col)
		
func find_loading_zone_spawn(loading_zone_name: String) -> Node2D:
	var named_node = find_child(loading_zone_name, true, false)
	if named_node != null:
		if is_loading_zone_node(named_node):
			return named_node as Node2D
		var child_loading_zone = named_node.find_child("LoadingZone", true, false)
		if child_loading_zone != null and is_loading_zone_node(child_loading_zone):
			return child_loading_zone as Node2D

	return find_loading_zone_by_current_spot(self, loading_zone_name)

func find_loading_zone_by_current_spot(node: Node, loading_zone_name: String) -> Node2D:
	if node != self and is_loading_zone_node(node) and str(node.get("Current Location/Spot")) == loading_zone_name:
		return node as Node2D

	for child in node.get_children():
		var result = find_loading_zone_by_current_spot(child, loading_zone_name)
		if result != null:
			return result

	return null

func is_loading_zone_node(node: Node) -> bool:
	return node.get("is_disabled") != null

func set_camera_limits():
	var camera := get_node_or_null("UniversalCamera") as Camera2D
	if camera == null:
		push_warning("EnvironmentHandler: Player camera was not found in %s." % scene_file_path)
		return
		
	camera.target = player_node
	var camera_bounds := get_camera_bounds_node()
	if camera_bounds == null:
		return
	var upper_left_marker := camera_bounds.get_node_or_null("Upper Left") as Node2D
	var bottom_right_marker := camera_bounds.get_node_or_null("Bottom Right") as Node2D
	if upper_left_marker == null or bottom_right_marker == null:
		push_warning("EnvironmentHandler: Camera bounds '%s' must have Upper Left and Bottom Right markers." % camera_bounds.name)
		return

	var upper_left_bounds : Vector2 = upper_left_marker.global_position
	var bottom_right_bounds : Vector2 = bottom_right_marker.global_position
	
	camera.limit_left = upper_left_bounds.x
	camera.limit_right = bottom_right_bounds.x
	camera.limit_top = upper_left_bounds.y
	camera.limit_bottom = bottom_right_bounds.y
	build_world_border(upper_left_bounds, bottom_right_bounds)
func get_camera_bounds_node() -> Node2D:
	if not is_building_insides:
		var overworld_bounds := get_node_or_null("Camera Bounds") as Node2D
		if overworld_bounds == null:
			push_warning("EnvironmentHandler: Camera Bounds node was not found in %s." % scene_file_path)
		return overworld_bounds

	var room_name := Global.current_loading_zone
	if room_name == "Bedroom":
		room_name = "Tavern"
	if room_name == "":
		push_warning("EnvironmentHandler: Cannot set building camera bounds without a current loading zone.")
		return null

	var room_node := find_child(room_name, true, false)
	if room_node == null:
		push_warning("EnvironmentHandler: Could not find room '%s' for camera bounds in %s." % [room_name, scene_file_path])
		return null

	var camera_bounds := room_node.get_node_or_null("Camera Bounds") as Node2D
	if camera_bounds == null:
		push_warning("EnvironmentHandler: Room '%s' does not have a Camera Bounds node." % room_name)
	return camera_bounds
