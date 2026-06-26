extends Node3D

class_name explorable_dungeon

#@onready var dungeon_camera = $Dungeon_Camera
@onready var player = $"3dPlayer2"
@onready var dungeon_zones: Array[Node] = $Zones.get_children()
@onready var navigation_region = $NavigationRegion3D
@onready var enemy_container = $Enemies
@onready var mini_map = $MiniMap

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
	return
	$"3dPlayer2"._setup(self)
	await Fade.fade_in(0.0)
	if await entered_new_floor():
		print("FINISHED")	

var combat_scene_: dungeon_loop
func _setup(dungeon_type_: dungeon_type):
	await Fade.fade_in(0.0)
	floor_count = randi_range(dungeon_type_.minimum_number_of_floors, dungeon_type_.max_number_of_floors)
	current_dungeon = dungeon_type_
	if dungeon_type_.does_dungeon_have_boss:
		if not dungeon_type_.has_beaten_boss:
			floor_count = dungeon_type_.first_time_floor_count
	player._setup(self)	
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
	await mini_map.clear_mini_map()

var setting_up_new_floor = false
func entered_new_floor():
	if current_floor == floor_count:
		return true
		get_tree().quit()
	else:
		setting_up_new_floor = true
		current_floor += 1
		movement_locked = true
		await Fade.fade_in(2)

		await remove_old_dungeon()
		setting_up = true
		
		while true:
			if await generate_dungeon():
				break
			else:
				remove_old_dungeon()

		setting_up = false
	print("FADING OUT")
	setting_up_new_floor = false
	await Fade.fade_out(2)
	movement_locked = false
	
var generated_rooms
	
func get_room_node_at(coords):
	if active_room_nodes.has(coords):
		return active_room_nodes[coords]
	
func generate_dungeon():
	print("GENERATING DUNGEON")
	var new_room_generation: dungeon_generation = dungeon_generation.new()
	
	
	new_room_generation.build_dungeon()
	new_room_generation.evaluate_room_names(new_room_generation.storage)
	var room_storage = new_room_generation.storage
	generated_rooms = room_storage
	
	var keys = room_storage.keys()
	var min_x_key: int = keys[0].x
	var max_x_key: int = keys[0].x
	var min_y_key: int = keys[0].y
	var max_y_key: int = keys[0].y
	
	# Separate the IF statements (avoid "elif" for min/max calculations)
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
	
# 1. Print the Rows with perfectly aligned Y-labels
	for y in range(height):
		# "%4d" forces the Y-coordinate to take up exactly 4 characters.
		# We then add 4 spaces, making the total margin exactly 8 characters!
		var row = ("%4d" % (y + min_y_key)) + "    " 
		for x in range(width):
			row += bounding_box_arr[x][y] + " "
		print(row)
		
	# 2. Print a Separator Line to divide the grid from the X-header
	var separator = "        " # Exactly 8 spaces of padding
	for x in range(width):
		separator += "--" # Draws a line matching the 2-character column width
	print(separator)
	
	# 3. Print the X Coordinates perfectly aligned
	var x_header = "        " # Exactly 8 spaces of padding
	for x in range(width):
		var world_x = x + min_x_key
		# "%2d" forces the number to take up exactly 2 characters in the console,
		# aligning it perfectly with your "cell + space" columns!
		x_header += "%2d" % world_x 
	print(x_header)
	
	
	var ret_val = instantiate_rooms(room_storage)
	
	if not ret_val:
		return false
	mini_map._setup(self, room_storage)

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

	#player.position.x += (generated_rooms[0].room_x_coord * tile_size)
	#player.position.z += (generated_rooms[0].room_y_coord * tile_size)
	
	var current_start = get_room_node_at(Vector2(0, 0))
	player_start_position = Vector2(player.position.x, player.position.z)
	player.rotation_degrees.y = 0.0
	#player.camera_pivot.rotation.y = 0.0
	#player.camera_pivot.current_yaw = 0.0
	#player.camera_pivot.current_pitch = 0.0
	#player.camera_pivot.target_yaw = 0.0
	#player.camera_pivot.target_pitch = 0.0

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
	mini_map.store_current_enemy_list(enemy_array)
	return true

var active_room_nodes: Dictionary[Vector2i, Node3D]
var tile_size = 0
func instantiate_rooms(room_storage):
	tile_size = 3.2
	
	var room_count = 0
	for room_ in room_storage:
		room_count += 1
		var room_to_load = load(room_storage[room_].asset_path)
		
		var new_room: room = room_to_load.instantiate()
		new_room.room_coords = room_
		new_room.position = Vector3(room_.x * tile_size, 0, room_.y * tile_size)
		new_room.room_directions = room_storage[room_].required_directions
		
		active_room_nodes[room_] = new_room
		
		new_room.rotation_degrees.y = room_storage[room_].get_rotation_degrees_()
		navigation_region.add_child(new_room)
		new_room._setup(self)
		

	return true
#	for x in range(max_grid_size.x):
#		for y in range(max_grid_size.y):
#			var room_to_load = room_symbol_mapping[str(bounding_box_arr[x][y])]
#			if room_to_load == "Empty_Space":
#				continue
#			var new_instance = load(rooms[room_symbol_mapping[bounding_box_arr[x][y]]])
#			var new_room = new_instance.instantiate()
#
#			var base_position = Vector3(x * tile_size, 0.0, y * tile_size)
#			new_room.room_coords = Vector2(x, y)
#			new_room._setup(self)
#
#			var direction = get_directions_at(x, y, room_lookup, bounding_box_arr)
#			
#			new_room.room_directions = direction
#			new_room.rotation_degrees.y = get_rotation_degrees_(room_to_load, direction)
#
#
#			new_room.room_directions.sort()
#			if room_to_load == "3-Way_Junction":
#				if new_room.room_directions.size() <= 2:
#					return false
#					
#			new_room.position = base_position
#			navigation_region.add_child(new_room)
#			
#			var grid_pos = Vector2i(x, y)
#			active_room_nodes[grid_pos] = new_room
#	return true

func battle_initiated(with_what_enemy: generic_combatants, node_id):
	in_combat = true
	var potential_encounters: Array[dungeon_wave]
	if potential_encounters == null:
		print("jhgfdjhgfkhgfjh")
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
			break
	for enemy in enemy_container.get_children():
		enemy.disable_player_detection()
	GlobalCombatInformation.initiate_combat(potential_encounters[random_encounter], node_id)
	#await combat_scene_.setup(current_dungeon, potential_encounters[random_encounter])

func return_to_exploring():
	await mini_map.store_current_enemy_list(enemy_container.get_children())
	print("BACK")
	#in_combat = false
	await Fade.fade_out(2.0)
	in_combat = false
	for i in range(Engine.get_frames_per_second() * 3):
		await get_tree().process_frame
	for enemy in enemy_container.get_children():
		enemy.enable_player_detection()
