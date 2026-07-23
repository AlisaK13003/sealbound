extends Node2D

const CUTSCENE_RUNNER_SCRIPT = preload("res://assets/Scripts/cutscene_runner.gd")
const RESTING_SCRIPT = preload("res://assets/Resources/Interactables/Resting.gd")
const BORDER_THICKNESS := 64.0
const BEDROOM_REST_SPOT_NAME := "BedroomRestSpot"

@export var is_building_insides: bool = false

@export var bgm: AudioStream

var player_node

func swap_to_me():
	player_node = get_tree().get_first_node_in_group("Overworld_Player")
	var entry_loading_zone: String = Global.current_loading_zone
	teleport_player_to_spawn()
	if is_building_insides:
		ensure_bed_rest_interactions()

	AudioManager.play_bgm(bgm, true)
	set_camera_limits()
	
	var cutscene_to_start
	if not Global.debug_story_skip_active:
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
						cutscene_to_start = potential_cutscene
						prepare_lyra_axe_return_cutscene()
						refresh_player_camera()
						await get_tree().process_frame
						refresh_player_camera()
					"quest_board_unlock_cutscene":
						print("QUEST BOARD INTRO")
						cutscene_to_start = potential_cutscene
						prepare_sera_quest_board_cutscene()
						refresh_player_camera()
						await get_tree().process_frame
						refresh_player_camera()
					"give_ore_to_blacksmith":
						print("GAVE ORE TO BLACKSMITH, TURNED IN THE QUEST")
						StateManager.set_story_state(StateManager.story_beats_lookup.BLACKSMITH_QUEST_FINISHED)
						StateManager.set_dungeon_unlock(StateManager.dungeon_state_lookup.CREEPY_DUNGEON_UNLOCKED)
						GlobalCombatInformation.complete_quest("res://scenes/Dungeon/Explorable_Dungeon_Test/Quest_Items/Quests/Retrieve_Ores.tres")
						GlobalCombatInformation.add_equipment_to_list("res://assets/Equipment/Training_Dagger.tres", true)
						StateManager.pseduo_story_time = Global.current_day
					"think_about_forest_clearing_mc_thought":
						print("THOUGHT ABOUT RETURNING TO THE CLEARING")
						StateManager.set_story_state(StateManager.story_beats_lookup.CUTSCENE_TELLING_YOU_GO_BACK_TO_CLEARING)
					"talk_to_sera_about_clearing":
						print("TALKED TO SERA ABOUT CLEARING")
						StateManager.set_story_state(StateManager.story_beats_lookup.TALKED_TO_SERA_ABOUT_CLEAR)
						StateManager.set_dungeon_unlock(StateManager.dungeon_state_lookup.SEAL_DUNGEON_UNLOCKED)
					"first_seal_dungeon_cutscene":
						print("SEAL DUNGEON CUTSCENE")
					

	await get_tree().create_timer(1.0).timeout
	await Fade.fade_out(0.5)
	Fade.is_fading = false
	match cutscene_to_start:
		"lyra_tavern_cutscene":
			start_lyra_tavern_cutscene()
		"turning_in_lyra_axe_cutscene":
			start_lyra_axe_return_cutscene()
		"quest_board_unlock_cutscene":
			start_sera_quest_board_cutscene()
	
func teleport_player_to_spawn():
	if player_node == null:
		return

	if Global.has_pending_player_spawn_position:
		_apply_pending_player_spawn_position()
		return

	if Global.current_loading_zone == "":
		_apply_pending_player_spawn_position()
		return
		
	var loading_zone_spawn := find_loading_zone_spawn(Global.current_loading_zone)
	if loading_zone_spawn == null:
		push_warning("EnvironmentHandler: Could not find loading zone spawn '%s' in %s." % [Global.current_loading_zone, scene_file_path])
		_apply_pending_player_spawn_position()
		return

	var spawn_point := loading_zone_spawn.find_child("Marker2D", true, false) as Node2D
	if spawn_point == null and loading_zone_spawn is Marker2D:
		spawn_point = loading_zone_spawn as Marker2D
	if spawn_point == null:
		push_warning("EnvironmentHandler: Loading zone spawn '%s' has no Marker2D in %s." % [Global.current_loading_zone, scene_file_path])
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

func prepare_lyra_axe_return_cutscene() -> void:
	var tavern_order_marker := get_tavern_order_cutscene_marker()
	var tavern_counter_marker := get_tavern_counter_cutscene_marker()
	if player_node != null:
		if tavern_order_marker != null:
			player_node.global_position = tavern_order_marker.global_position
		else:
			var tavern_marker := get_node_or_null("Tavern/LoadingZone/Marker2D") as Node2D
			if tavern_marker != null:
				player_node.global_position = tavern_marker.global_position

	var lyra_node = find_child("Lyra_NPC", true, false)
	if lyra_node == null:
		return
	if lyra_node.has_method("pin_to_location_for_cutscene"):
		lyra_node.pin_to_location_for_cutscene("Tavern_Counter")
	elif tavern_counter_marker != null and lyra_node.has_method("pin_to_global_position_for_cutscene"):
		lyra_node.pin_to_global_position_for_cutscene(tavern_counter_marker.global_position, &"down")

func prepare_sera_quest_board_cutscene() -> void:
	var bedroom_exit_marker := get_node_or_null("Bedroom_Exit/LoadingZone/Marker2D") as Node2D
	var tavern_bedroom_exit_marker := get_tavern_bedroom_exit_cutscene_marker()
	var lyra_room_marker := get_lyra_room_cutscene_marker()

	if player_node != null:
		if tavern_bedroom_exit_marker != null:
			player_node.global_position = tavern_bedroom_exit_marker.global_position
		elif bedroom_exit_marker != null:
			player_node.global_position = bedroom_exit_marker.global_position

	var sera_node = find_child("Sera_NPC", true, false)
	if sera_node != null and lyra_room_marker != null and sera_node.has_method("pin_to_global_position_for_cutscene"):
		sera_node.pin_to_global_position_for_cutscene(lyra_room_marker.global_position, &"down")

	var lyra_node = find_child("Lyra_NPC", true, false)
	if lyra_node != null and lyra_room_marker != null and lyra_node.has_method("pin_to_global_position_for_cutscene"):
		lyra_node.pin_to_global_position_for_cutscene(lyra_room_marker.global_position + Vector2(28.0, 0.0), &"left")

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

func start_lyra_axe_return_cutscene() -> void:
	var runner = CUTSCENE_RUNNER_SCRIPT.new()
	get_tree().current_scene.add_child(runner)
	runner.finished.connect(runner.queue_free)
	var lyra_node = find_child("Lyra_NPC", true, false)
	if lyra_node != null and lyra_node.has_method("restore_after_cutscene"):
		runner.finished.connect(Callable(self, "restore_cutscene_actor").bind(lyra_node))
	runner.play(Global.LYRA_AXE_RETURN_CUTSCENE_PATH)

func start_sera_quest_board_cutscene() -> void:
	var runner = CUTSCENE_RUNNER_SCRIPT.new()
	get_tree().current_scene.add_child(runner)
	runner.finished.connect(runner.queue_free)
	runner.finished.connect(restore_sera_quest_board_cutscene_actors)
	runner.play(Global.SERA_QUEST_BOARD_CUTSCENE_PATH)

func restore_sera_quest_board_cutscene_actors() -> void:
	restore_cutscene_actor(find_child("Sera_NPC", true, false))
	restore_cutscene_actor(find_child("Lyra_NPC", true, false))

func play_cutscene_animation(animation_name: String):
	match animation_name:
		"sera_walk_from_lyra_room_to_exit":
			return play_sera_walk_from_lyra_room_to_exit()
		"sera_walk_from_lyra_exit_to_player":
			return play_sera_walk_from_lyra_exit_to_player()
		"sera_walk_from_lyra_room_to_player":
			return play_sera_walk_from_lyra_room_to_player()
	return null

func play_sera_walk_from_lyra_room_to_player():
	var sera_node := get_sera_cutscene_node()
	var lyra_room_marker := get_lyra_room_cutscene_marker()
	var lyra_exit_marker := get_lyra_exit_cutscene_marker()
	var final_position: Vector2 = get_sera_talk_cutscene_position()
	if sera_node == null or lyra_room_marker == null or lyra_exit_marker == null:
		return 0.2
	if final_position == Vector2.INF:
		return 0.2

	sera_node.global_position = lyra_room_marker.global_position

	if sera_node.has_method("move_along_global_positions_for_cutscene"):
		var route_targets: Array[Vector2] = [
			lyra_exit_marker.global_position,
			final_position
		]
		var path_points: Array[Vector2] = build_axis_locked_cutscene_path(lyra_room_marker.global_position, route_targets)
		return sera_node.move_along_global_positions_for_cutscene(path_points, 90.0, &"down")
	if not sera_node.has_method("move_to_global_position_for_cutscene"):
		return 0.2
	return sera_node.move_to_global_position_for_cutscene(final_position, 1.25, &"down")

func play_sera_walk_from_lyra_room_to_exit():
	var sera_node := get_sera_cutscene_node()
	var lyra_room_marker := get_lyra_room_cutscene_marker()
	var lyra_exit_marker := get_lyra_exit_cutscene_marker()
	if sera_node == null or lyra_room_marker == null or lyra_exit_marker == null:
		return 0.2

	sera_node.global_position = lyra_room_marker.global_position
	if sera_node.has_method("move_along_global_positions_for_cutscene"):
		var path_points: Array[Vector2] = build_axis_locked_cutscene_path(lyra_room_marker.global_position, [lyra_exit_marker.global_position])
		return sera_node.move_along_global_positions_for_cutscene(path_points, 90.0, &"right")
	if not sera_node.has_method("move_to_global_position_for_cutscene"):
		return 0.2
	return sera_node.move_to_global_position_for_cutscene(lyra_exit_marker.global_position, 0.75, &"right")

func play_sera_walk_from_lyra_exit_to_player():
	var sera_node := get_sera_cutscene_node()
	var final_position: Vector2 = get_sera_talk_cutscene_position()
	if sera_node == null or final_position == Vector2.INF:
		return 0.2

	if sera_node.has_method("move_along_global_positions_for_cutscene"):
		var path_points: Array[Vector2] = build_axis_locked_cutscene_path(sera_node.global_position, [final_position])
		return sera_node.move_along_global_positions_for_cutscene(path_points, 90.0, &"down")
	if not sera_node.has_method("move_to_global_position_for_cutscene"):
		return 0.2
	return sera_node.move_to_global_position_for_cutscene(final_position, 0.9, &"down")

func get_sera_cutscene_node() -> Node2D:
	return find_child("Sera_NPC", true, false) as Node2D

func get_tavern_bedroom_exit_cutscene_marker() -> Node2D:
	return find_first_cutscene_marker(["Tavern_BedroomExit", "Tavern_Bedroom_Exit", "Tavern BedroomExit", "Tavern Bedroom Exit", "tavernbedroomexit", "tavern bedroom exit"])

func get_lyra_room_cutscene_marker() -> Node2D:
	return find_first_cutscene_marker(["Tavern_LyraRoom", "Tavern Lyra Room", "LyraRoom", "Lyra Room", "lyraroom", "lyra room"])

func get_lyra_exit_cutscene_marker() -> Node2D:
	return find_first_cutscene_marker(["Tavern_LyraExit", "Tavern_LuraExit", "Tavern_OutsideLyraRoom", "LyraExit", "Lyra Exit", "LuraExit", "Lura Exit", "lyraexit", "lyra exit", "luraexit", "lura exit", "Tavern_Path6"])

func get_tavern_order_cutscene_marker() -> Node2D:
	return find_first_cutscene_marker(["Tavern_Order", "Tavern Order", "tavernorder"])

func get_tavern_counter_cutscene_marker() -> Node2D:
	return find_first_cutscene_marker(["Tavern_Counter", "Tavern Counter", "taverncounter"])

func get_sera_talk_cutscene_position() -> Vector2:
	var sera_talk_marker := find_first_cutscene_marker(["Tavern_SeraTalkToPlayer", "Tavern_SeraTalkToPlater", "SeraTalkToPlayer", "Sera_TalkToPlayer", "Sera Talk To Player", "SeraTalkToPlater", "Sera Talk To Plater", "seratalktoplayer", "sera talk to player", "seratalktoplater", "sera talk to plater"])
	if sera_talk_marker != null:
		return sera_talk_marker.global_position
	var bedroom_exit_marker := get_node_or_null("Bedroom_Exit/LoadingZone/Marker2D") as Node2D
	if bedroom_exit_marker != null:
		return bedroom_exit_marker.global_position + Vector2(-52.0, 10.0)
	return Vector2.INF

func find_first_cutscene_marker(marker_names: Array[String]) -> Node2D:
	var normalized_names: Dictionary = {}
	for marker_name in marker_names:
		normalized_names[normalize_cutscene_marker_name(marker_name)] = true
		var marker := find_child(marker_name, true, false) as Node2D
		if marker != null:
			return marker
	return find_cutscene_marker_by_normalized_name(self, normalized_names)

func find_cutscene_marker_by_normalized_name(node: Node, normalized_names: Dictionary) -> Node2D:
	if node is Node2D and normalized_names.has(normalize_cutscene_marker_name(node.name)):
		return node as Node2D
	for child in node.get_children():
		var marker := find_cutscene_marker_by_normalized_name(child, normalized_names)
		if marker != null:
			return marker
	return null

func normalize_cutscene_marker_name(marker_name: String) -> String:
	return marker_name.to_lower().replace("_", "").replace(" ", "").replace("-", "")

func build_axis_locked_cutscene_path(start_position: Vector2, target_positions: Array[Vector2]) -> Array[Vector2]:
	var path_points: Array[Vector2] = []
	var current_position := start_position
	for target_position in target_positions:
		if not is_equal_approx(current_position.x, target_position.x) and not is_equal_approx(current_position.y, target_position.y):
			path_points.append(Vector2(target_position.x, current_position.y))
		path_points.append(target_position)
		current_position = target_position
	return path_points

func restore_cutscene_actor(actor: Node) -> void:
	if is_instance_valid(actor) and actor.has_method("restore_after_cutscene"):
		actor.restore_after_cutscene()

func ensure_bed_rest_interactions() -> void:
	if find_child(BEDROOM_REST_SPOT_NAME, true, false) != null:
		return

	var wake_marker := find_child("Bedspawn", true, false) as Node2D
	if wake_marker == null:
		return

	var rest_spot := Node2D.new()
	rest_spot.name = BEDROOM_REST_SPOT_NAME
	rest_spot.set_script(RESTING_SCRIPT)
	rest_spot.set("wake_marker_name", "Bedspawn")
	rest_spot.set("trigger_size", Vector2(80.0, 80.0))
	add_child(rest_spot)
	rest_spot.global_position = wake_marker.global_position

func build_world_border(top_left: Vector2, bottom_right: Vector2) -> void:
	if has_node("WorldBorder"):
		return  
	var border := StaticBody2D.new()
	border.name = "WorldBorder"
	border.top_level = true 
	add_child(border)

	var w := bottom_right.x - top_left.x
	var h := bottom_right.y - top_left.y
	var cx := (top_left.x + bottom_right.x) * 0.5
	var cy := (top_left.y + bottom_right.y) * 0.5
	var t := BORDER_THICKNESS

	var edges := [
		[Vector2(cx, top_left.y - t * 0.5), Vector2(w + t * 2.0, t)],      
		[Vector2(cx, bottom_right.y + t * 0.5), Vector2(w + t * 2.0, t)],  
		[Vector2(top_left.x - t * 0.5, cy), Vector2(t, h)],                
		[Vector2(bottom_right.x + t * 0.5, cy), Vector2(t, h)],          
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
	if room_name == "Bedroom_Exit":
		room_name = "Tavern"
	if room_name == "Bedspawn":
		room_name = "Bedroom"
	if room_name == "Blacksmith2":
		room_name = "Blacksmith"
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
