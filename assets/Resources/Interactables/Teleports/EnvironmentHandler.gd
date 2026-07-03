extends Node2D

const CUTSCENE_RUNNER_SCRIPT = preload("res://assets/Scripts/cutscene_runner.gd")

@export var player_node : Node2D

@export var is_building_insides: bool = false

func swap_to_me():
	var entry_loading_zone: String = Global.current_loading_zone
	var should_start_entry_cutscene := Global.should_start_lyra_tavern_cutscene(entry_loading_zone)
	teleport_player_to_spawn()
	if should_start_entry_cutscene:
		prepare_lyra_tavern_cutscene()
	set_camera_limits()
	if should_start_entry_cutscene:
		refresh_player_camera()
		await get_tree().process_frame
		refresh_player_camera()
	#await get_tree().create_timer(0.75).timeout
	await Fade.fade_out(0.5)
	if should_start_entry_cutscene:
		start_lyra_tavern_cutscene()

func teleport_player_to_spawn():
	if Global.current_loading_zone == "":
		return
		
	print("Current Loading Zone ", Global.current_loading_zone)
	print("Current Region ", Global.current_region)
	var spawn_point = find_loading_zone_spawn(Global.current_loading_zone)
	if spawn_point == null:
		push_warning("EnvironmentHandler: Could not find loading zone spawn '%s' in %s." % [Global.current_loading_zone, scene_file_path])
		return
	
	#if is_building_insides:
	#	spawn_point = spawn_point
	#else:
	#	spawn_point = spawn_point.get_child(0)
	spawn_point.is_disabled = true
	if player_node:
		player_node.global_position = spawn_point.global_position
		if Global.has_pending_player_spawn_position:
			player_node.global_position = Global.pending_player_spawn_position
			Global.has_pending_player_spawn_position = false

func prepare_lyra_tavern_cutscene() -> void:
	if player_node != null:
		player_node.global_position = Global.LYRA_TAVERN_PLAYER_POSITION

	var lyra_node = find_child("Lyra_NPC", true, false)
	if lyra_node != null and lyra_node.has_method("pin_to_location_for_cutscene"):
		lyra_node.pin_to_location_for_cutscene("Tavern_Counter")

func refresh_player_camera() -> void:
	if player_node == null:
		return
	var camera = player_node.get_node_or_null("Camera2D")
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
	var camera_bounds: Node
	if is_building_insides:
		if Global.current_loading_zone == "Bedroom":
			camera_bounds = find_child("Tavern", true, false).get_child(0)
		else:
			camera_bounds = find_child(Global.current_loading_zone, true, false).get_child(0)
	else:
		camera_bounds = $"Camera Bounds"

	var upper_left_bounds : Vector2 = camera_bounds.get_child(0).global_position
	var bottom_right_bounds : Vector2 = camera_bounds.get_child(1).global_position
	
	player_node.get_node("Camera2D").limit_left = upper_left_bounds.x
	player_node.get_node("Camera2D").limit_right = bottom_right_bounds.x
	player_node.get_node("Camera2D").limit_top = upper_left_bounds.y
	player_node.get_node("Camera2D").limit_bottom = bottom_right_bounds.y
