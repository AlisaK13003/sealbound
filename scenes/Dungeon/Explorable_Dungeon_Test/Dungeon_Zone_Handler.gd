extends Node3D

class_name explorable_dungeon

#@onready var dungeon_camera = $Dungeon_Camera
@onready var player = $"3dPlayer2"
@onready var navigation_region = $NavigationRegion3D
@onready var enemy_container = $Enemies

var in_combat: bool = false

var enemy_scene = "res://scenes/Dungeon/Explorable_Dungeon_Test/3D_Enemy.tscn"

var camera_player_displacement: Vector3

var rng = RandomNumberGenerator.new()
var player_start_position: Vector2

var current_dungeon: dungeon_type

var camera_speed = 3.0:
	set(value):
		camera_speed = value

enum cardinal_directions_locks {X, Y, Z}

signal zone_changed


#region DungeonGeneratingHelpers

#endregion

var setting_up = true
var free_cam = false

var current_floor = 0
var floor_count = 5

var movement_locked = false

var generation_failed = false
var potential_encounters: Array[generic_combatants]

func _ready():
	Global.menu_opened.connect(cant_move)
	Global.menu_closed.connect(can_move)
	return
	$"3dPlayer2"._setup(self)
	await Fade.fade_in(0.0)
	if await entered_new_floor():
		print("FINISHED")	

func can_move():
	movement_locked = false
	
func cant_move():
	movement_locked = true

var combat_scene_#: dungeon_loop
var should_spawn_boss_floor: bool = false
func _setup(dungeon_type_: dungeon_type):
	#await Fade.fade_in(0.0)
	floor_count = randi_range(dungeon_type_.minimum_number_of_floors, dungeon_type_.max_number_of_floors)
	current_dungeon = dungeon_type_
	if dungeon_type_.does_dungeon_have_boss:
		if not dungeon_type_.has_beaten_boss:
			floor_count = dungeon_type_.first_time_floor_count
			
	await player._setup(self)	
	await entered_new_floor()
	print("SETUP")

func remove_old_dungeon():
	player.position = Vector3(-10, 0, -10)
	player.current_grid_pos = Vector2(-1, -1)
	for child in navigation_region.get_children():
		var child_to_remove = child
		child.queue_free()
	for child in enemy_container.get_children():
		var child_to_remove = child
		child.queue_free()
	await player.clear_mini_map()

var setting_up_new_floor = false
func entered_new_floor():
	if current_floor == floor_count:
		GlobalCombatInformation.dungeon_over()
		return
	else:
		setting_up_new_floor = true
		current_floor += 1
		movement_locked = true
		if current_floor != 1:
			await Fade.fade_in(2)

		await remove_old_dungeon()
		setting_up = true
		
		while true:
			if await generate_dungeon():
				break
			else:
				remove_old_dungeon()

		setting_up = false
	setting_up_new_floor = false
	movement_locked = false
	await Fade.fade_out(2)
	
	
var generated_rooms
	
func get_room_node_at(coords):
	if active_room_nodes.has(coords):
		return active_room_nodes[coords]
	
func generate_dungeon():
	print("GENERATING DUNGEON")
	var new_room_generation: dungeon_generation = dungeon_generation.new()
	var boss_floor = false
	current_floor = floor_count
	if current_floor == floor_count and current_dungeon.does_dungeon_have_boss and not current_dungeon.has_beaten_boss:
		boss_floor = true
	
	

	new_room_generation.build_dungeon(boss_floor)
	new_room_generation.evaluate_room_names(new_room_generation.storage)
	var room_storage = new_room_generation.storage
	generated_rooms = room_storage
	
	player.update_pivot_rotation(generated_rooms[Vector2i(0, 0)])
	
	var keys = room_storage.keys()
	var min_x_key: int = keys[0].x
	var max_x_key: int = keys[0].x
	var min_y_key: int = keys[0].y
	var max_y_key: int = keys[0].y
	
	for key: Vector2i in keys:
		if key.x < min_x_key:
			min_x_key = key.x
		if key.x > max_x_key:
			max_x_key = key.x
			
		if key.y < min_y_key:
			min_y_key = key.y
		if key.y > max_y_key:
			max_y_key = key.y
	var bounding_box_arr : Array[Array] = []
	var width = max_x_key - min_x_key + 1
	var height = max_y_key - min_y_key + 1
	
	for x in range(width):
		bounding_box_arr.append([])
		for y in range(height):
			bounding_box_arr[x].append("0")
	
	for room_: Vector2i in room_storage:
		bounding_box_arr[room_.x - min_x_key][room_.y - min_y_key] = room_storage[room_].room_name_type[0]
	
	for y in range(height):
		var row = ("%4d" % (y + min_y_key)) + "    " 
		for x in range(width):
			row += bounding_box_arr[x][y] + " "
		print(row)
		
	var separator = "        " 
	for x in range(width):
		separator += "--" 
	print(separator)
	
	var x_header = "        " 
	for x in range(width):
		var world_x = x + min_x_key

		x_header += "%2d" % world_x 
	print(x_header)
	
	var ret_val = instantiate_rooms(room_storage, boss_floor)
	
	if not ret_val:
		return false

	player._setup_mini_map(self, room_storage)

	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if navigation_region.navigation_mesh:
		navigation_region.navigation_mesh.clear()
	
	navigation_region.bake_navigation_mesh(false)
	
	var retries = 0
	while navigation_region.navigation_mesh.get_polygon_count() == 0 and retries < 5:
		await get_tree().physics_frame
		
		navigation_region.navigation_mesh.clear()
		navigation_region.bake_navigation_mesh(false)
		retries += 1
		
	if navigation_region.navigation_mesh.get_polygon_count() == 0:
		return
			
	await get_tree().physics_frame
	
	player.position = Vector3(0, 2.0, 0)

	var current_start = get_room_node_at(Vector2(0, 0))
	player_start_position = Vector2(player.position.x, player.position.z)
	player.rotation_degrees.y = 0.0

	match current_start.rotation_degrees.y:
		0.0:
			pass
		90.0:
			player.rotation_degrees.y += 180
		180.0:
			player.rotation_degrees.y += -90.0
		270.0:
			player.rotation_degrees.y += 0.0
		360.0:
			player.rotation_degrees.y += 90.0
	player.sprite_pivot.rotation_degrees.y = 0
	var number_of_enemies = ceili(navigation_region.get_child_count() / 20)
	var enemy_spawnable_rooms = navigation_region.get_children()
	var enemy_count = 0
	var enemy_array: Array[CharacterBody3D]
	enemy_spawnable_rooms.shuffle()
	
	for room_ in enemy_spawnable_rooms:
		if room_ is MeshInstance3D or room_.room_classification in [0, 1]:
			continue
		else:
			if enemy_count > number_of_enemies:
				break
			var potential_enemy_encounters = randi_range(0, current_dungeon.potential_encounters.size() - 1)
			var new_enemy = load(enemy_scene)
			var new_enemy_instance = new_enemy.instantiate()
			
			new_enemy_instance.position.x = (room_.room_coords.x) * tile_size
			new_enemy_instance.position.z = (room_.room_coords.y) * tile_size
			new_enemy_instance.position.y = 2.0

			enemy_container.add_child(new_enemy_instance)
			new_enemy_instance._setup(self, current_dungeon.potential_encounters[potential_enemy_encounters].encounterable_enemy)
			enemy_array.append(new_enemy_instance)
			enemy_count += 1
			
	player.store_enemy_list(enemy_array)
	player.setup_fs()
	return true

var active_room_nodes: Dictionary[Vector2i, Node3D]
var tile_size = 0
func instantiate_rooms(room_storage, boss_floor):
	var normal_tile_size = 3.2
	tile_size = 2.5
	
	var room_count = 0
	for room_ in room_storage:
		room_count += 1
		
		var room_to_load = load(room_storage[room_].get_asset_path())
		var new_room: room = room_to_load.instantiate()
		new_room.room_coords = room_
		new_room.position = Vector3(room_.x * tile_size, 0, room_.y * tile_size)
		new_room.room_directions = room_storage[room_].required_directions
		new_room.scale *= float(tile_size / normal_tile_size)
		active_room_nodes[room_] = new_room
		
		new_room.rotation_degrees.y = room_storage[room_].get_rotation_degrees_()
		navigation_region.add_child(new_room)
		
		var is_center = room_storage[room_].is_center
		var is_locked = room_storage[room_].is_locked
		
		var spawn_boss_in_room: bool = false
		if room_storage[room_].group_id == 6 and room_storage[room_].is_center:
			spawn_boss_in_room = true
		
		if room_storage[room_].room_name_type == "Q":
			var possible_quests = []
			for quest_: quest in GlobalCombatInformation.active_quests:
				if quest_.dungeon_location == GlobalCombatInformation.selected_dungeon_ and quest_.should_spawn_dungeon_room and not quest_.does_player_have_special_item:
					possible_quests.append(quest_)
			new_room._setup(self, room_storage[room_].group_id, is_center, possible_quests.pick_random())
		else:
			new_room._setup(self, room_storage[room_].group_id, is_center, spawn_boss_in_room)
			
		if is_locked:
			new_room.lock_room(true)

	var spawn_locked_room = rng.randf()
	if boss_floor:
		var spawned_key: bool = false
		var room_caps = []
		for room_ in active_room_nodes.values():
			if room_.room_classification == 2:
				room_caps.append(room_)
		while not spawned_key:
			var room_to_have_key = room_caps.pick_random()
			if not room_to_have_key.is_locked and not room_to_have_key.has_key:
				room_to_have_key.set_key_spawn(true)
				spawned_key = true
	if spawn_locked_room < 1.0:
		var room_caps = []
		var chest_rooms = []
		for room_ in active_room_nodes.values():
			if room_.room_classification == 2:
				room_caps.append(room_)
			if room_.room_classification == 7:
				chest_rooms.append(room_)
		
		if not room_caps.is_empty() and not chest_rooms.is_empty():
			var room_to_be_locked = chest_rooms.pick_random()
			var room_to_have_key = room_caps.pick_random()
			
			if not room_to_be_locked.is_locked and not room_to_be_locked.has_key and not room_to_have_key.is_locked and not room_to_have_key.has_key:
				room_to_be_locked.lock_room(false)
				room_to_have_key.set_key_spawn()
		
	return true

func battle_initiated(with_what_enemy: generic_combatants, node_id, is_boss: bool = false):
	in_combat = true
	if not is_boss:
		var potential_encounters: Array[dungeon_wave]

		for encounter in current_dungeon.potential_encounters:
			if encounter.encounterable_enemy.combatant_name == with_what_enemy.combatant_name:
				potential_encounters.append(encounter)
		for encounter in potential_encounters:
			print(encounter.encounterable_enemy.combatant_name)

		var random_encounter = randi_range(0, potential_encounters.size() - 1)
		var enemy_to_potentially_remove
		for enemy in enemy_container.get_children():
			if enemy.get_instance_id() == node_id:
				enemy_to_potentially_remove = enemy
			enemy.disable_player_detection()
			
		GlobalCombatInformation.initiate_combat(potential_encounters[random_encounter], node_id)
	else:
		GlobalCombatInformation.initiate_combat(current_dungeon.boss_encounter, node_id, is_boss)
	#await combat_scene_.setup(current_dungeon, potential_encounters[random_encounter])

func return_to_exploring():
	await player.dungeon_overlay.mini_map.store_current_enemy_list(enemy_container.get_children())
	#in_combat = false
	await Fade.fade_out(2.0)
	in_combat = false
	for i in range(Engine.get_frames_per_second() * 3):
		await get_tree().process_frame
	for enemy in enemy_container.get_children():
		enemy.enable_player_detection()
	movement_locked = false
