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

var room_symbol_mapping: Dictionary = {
	"S": "Spawn_Room",
	"E": "Stair_Room",
	"R": "Room_Cap",
	"C": "Corner_Junction",
	"3": "3-Way_Junction",
	"4": "4-Way_Junction",
	"2": "2x2_Room",
	"T": "T_Chest_Room",            

	# --- Hallways & Corridors ---
	"H": "Generic_Hallway",      
	"h": "Room_Cap",        
	"-": "Straight_Room",
	"|": "Straight_Room",  
	"c": "Corner_Junction",      
	"t": "3-Way_Junction", 
	"+": "4-Way_Junction", 

	"0": "Empty_Space"      
}

var active_room_nodes: Dictionary = {}

var room_names = ["Spawn_Room", "Room_Cap", "4-Way_Junction", "3-Way_Junction", "Corner_Junction", "2x2_Room", "T_Chest_Room", "Stair_Room", "Straight_Room"]
var rooms : Dictionary = {
	"Spawn_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Spawn_Room.tscn",
	"Room_Cap": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Room_Cap.tscn",
	"4-Way_Junction": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/4-Way_Junction2.tscn",
	"3-Way_Junction": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/3-way-junction.tscn",
	"Corner_Junction": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Corner_Junction.tscn",
	"2x2_Room": "",
	"T_Chest_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Chest_Room_.tscn",
	"Stair_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Stair_Room.tscn",
	"Straight_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/straight_room_.tscn"
}

var room_sizing : Dictionary = {
	"Spawn_Room": 1,
	"Room_Cap": 1,
	"Horizontal_Corridor": 1,
	"4-Way_Junction": 1,
	"3-Way_Junction": 1,
	"Corner_Junction": 1,
	"2x2_Room": 2,
	"Stair_Room": 1,
	"T_Chest_Room": 1,
}

var room_exits: Dictionary = {
	"Spawn_Room": 1,
	"Room_Cap": 1,
	"Horizontal_Corridor": 2,
	"4-Way_Junction": 4,
	"3-Way_Junction": 3,
	"Corner_Junction": 2,
	"T_Chest_Room": 1,
	"2x2_Room": 2,
	"Stair_Room": 1
}

var same_directions: Dictionary = {
	0: 1,
	1: 0,
	2: 3, 
	3: 2
}

var valid_directions: Dictionary = {
	"Spawn_Room": [], 
	"Room_Cap": [
		[0], [1], [2], [3] 
	],
	"T_Chest_Room":
		[
		[0], [1], [2], [3]		
	],
	"Horizontal_Corridor": [
		[0, 1], [1, 0], 
		[2, 3], [3, 2]  
	],
	"4-Way_Junction": [], 
	"3-Way_Junction": [
		[0, 1, 2], [0, 1, 3], [0, 2, 3], 
		[1, 0, 2], [1, 0, 3], [1, 2, 3], 
		[2, 0, 1], [2, 0, 3], [2, 1, 3], 
		[3, 0, 1], [3, 0, 2], [3, 1, 2]  
	],
	"Corner_Junction": [
		[0, 2], [2, 0], 
		[1, 2], [2, 1], 
		[0, 3], [3, 0], 
		[1, 3], [3, 1]  
	],
	"2x2_Room": [], 
	"Stair_Room": [] 
}

const DIR_VECTORS = {
	0: Vector2i(-1, 0), # Left
	1: Vector2i(1, 0),  # Right
	2: Vector2i(0, -1), # Up
	3: Vector2i(0, 1)   # Down
}

#region DungeonGeneratingHelpers
func index_to_pos(index: int) -> Vector2i:
	return Vector2i(index % grid_size_x, index / grid_size_x)

func pos_to_index(pos: Vector2i) -> int:
	return pos.y * grid_size_x + pos.x

func get_room_node_at(grid_coords: Vector2i) -> Node3D:
	if active_room_nodes.has(grid_coords):
		return active_room_nodes[grid_coords]
	
	# Return null if they stepped into empty space/void
	return null

class dungeon_room:
	var room_pos: Vector2
	var room_x_coord: int
	var room_y_coord: int
	var room_direction: Array[int] = []
	var external_directions: Array[int] = [] 
	var room_name_type: String
	var border_check: Array[bool]
	var group_id: int = -1 
	
	func _init(position_, x_coord, y_coord, facing, border, room_name, grp_id = -1):
		room_pos = position_
		room_x_coord = x_coord
		room_y_coord = y_coord
		room_name_type = room_name
		border_check = border
		group_id = grp_id
		if facing == null:
			pass
		elif facing != null or facing.size() != 0:
			room_direction.append(facing)
			external_directions.append(facing)
			
	func add_direction(new_direction):
		if not room_direction.has(new_direction):
			room_direction.append(new_direction)
		if not external_directions.has(new_direction):
			external_directions.append(new_direction)
			
	func add_internal_direction(new_direction):
		if not room_direction.has(new_direction):
			room_direction.append(new_direction)
			
	func reset_directions():
		room_direction.clear()
		external_directions.clear()

const INVALID_OFFSETS = {
	0: [Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(-1, -1)], # Left
	1: [Vector2i(1, 0),  Vector2i(1, 1),  Vector2i(1, -1)],  # Right
	2: [Vector2i(0, 1),  Vector2i(1, 1),  Vector2i(-1, 1)],  # Up
	3: [Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1)]  # Down
}

func has_border_conflict(room_: dungeon_room) -> bool:
	for dir in room_.room_direction:
		if room_.border_check[dir]:
			return true 
	return false

func get_room_boundary_allignment(room_coords):
	# Checks if room lies on the border
	var on_left_room = (room_coords.x == 0)
	var on_right_room = (room_coords.x == grid_size_x - 1)
	var on_top_room = (room_coords.y == 0)
	var on_bottom_room = (room_coords.y == grid_size_y - 1)

	var what_edges_is_room_on: Array[bool] = [on_left_room, on_right_room, on_top_room, on_bottom_room]
	return what_edges_is_room_on

func get_door_alignment(room_a: dungeon_room, room_b: dungeon_room):
	var dx = room_b.room_x_coord - room_a.room_x_coord
	var dy = room_b.room_y_coord - room_a.room_y_coord
	
	if abs(dx) + abs(dy) != 1:
		return true
	
	var dir_a_to_b = -1
	if dx == -1: dir_a_to_b = 0   # B is Left of A
	elif dx == 1: dir_a_to_b = 1  # B is Right of A
	elif dy == -1: dir_a_to_b = 2 # B is Up of A
	elif dy == 1: dir_a_to_b = 3  # B is Down of A
	
	var dir_b_to_a = same_directions[dir_a_to_b]
	
	var a_points_to_b = dir_a_to_b in room_a.room_direction
	var b_points_to_a = dir_b_to_a in room_b.room_direction
	
	return a_points_to_b == b_points_to_a

func get_valid_direction(random_room_to_spawn, potential_room, what_edges_is_room_on):
	# Applies a valid direction to the room
	var total_directions = room_exits[room_names[random_room_to_spawn]]
	var valid_layouts = valid_directions[potential_room.room_name_type]
	var valid_direction = false
	
	if not valid_layouts.is_empty():
		for layout in range(valid_layouts.size()):
			if not valid_direction:
				potential_room.reset_directions()
				var chosen_layout = valid_layouts[rng.randi() % valid_layouts.size()]
				for dir in chosen_layout:
					potential_room.add_direction(dir)
				
				if true in what_edges_is_room_on:
					var border_confliction = false
					for dir in potential_room.room_direction:
						if potential_room.border_check[dir]:
							border_confliction = true
					if not border_confliction:
						valid_direction = true
				else:
					valid_direction = true
			else:
				break
	else:
		var needed_exits = room_exits[room_names[random_room_to_spawn]]
		var directions_pool = [0, 1, 2, 3]
		
		var attempts = 0
		var max_attempts = 100
		
		while (not valid_direction) and (attempts < max_attempts):
			attempts += 1
			potential_room.reset_directions()
			directions_pool.shuffle()
			
			var chosen_layout = directions_pool.slice(0, needed_exits)
			for dir in chosen_layout:
				potential_room.add_direction(dir)
			
			if true in what_edges_is_room_on:
				var border_confliction = false
				for dir in potential_room.room_direction:
					if potential_room.border_check[dir]:
						border_confliction = true
				if not border_confliction:
					valid_direction = true
			else:
				valid_direction = true
	
	return valid_direction

func check_room_placement(room_to_check: dungeon_room, room_to_check_against: Array, room_index: int, bounding_box_arr: Array) -> bool:
	var rooms_already_present: Array = room_to_check_against
	
	var rx = room_to_check.room_x_coord
	var ry = room_to_check.room_y_coord
	var room_coords = Vector2i(rx, ry)

	if rooms_already_present.size() >= 2:
		var protected_tiles = []
		var spawn_room = rooms_already_present[0]
		var exit_room = rooms_already_present[1]
		
		for dir in spawn_room.room_direction:
			protected_tiles.append(Vector2i(spawn_room.room_x_coord, spawn_room.room_y_coord) + DIR_VECTORS[dir])
			
		for dir in exit_room.room_direction:
			protected_tiles.append(Vector2i(exit_room.room_x_coord, exit_room.room_y_coord) + DIR_VECTORS[dir])
			
		if room_coords in protected_tiles:
			return false

	for placed_room in rooms_already_present:
		if rx == placed_room.room_x_coord and ry == placed_room.room_y_coord:
			return false
		
		if not get_door_alignment(room_to_check, placed_room):
			return false
			
		var placed_coords = Vector2i(placed_room.room_x_coord, placed_room.room_y_coord)
		for direction in placed_room.room_direction:
			for offset in INVALID_OFFSETS[direction]:
				var forbidden_pos = placed_coords + offset
				if rx == forbidden_pos.x and ry == forbidden_pos.y:
					return false

	if has_border_conflict(room_to_check):
		return false

	return true

func get_doorway_center(left_marker: Node3D, right_marker: Node3D) -> Vector3:
	return (left_marker.global_position + right_marker.global_position) / 2.0

class DungeonEdge:
	var u: int       
	var v: int      
	var weight: float 

	func _init(_u: int, _v: int, _weight: float):
		u = _u
		v = _v
		weight = _weight

class DisjointSet:
	var parent: Dictionary = {}

	func make_set(num_elements: int):
		for i in range(num_elements):
			parent[i] = i

	func find(i: int) -> int:
		if parent[i] == i:
			return i
		parent[i] = find(parent[i]) 
		return parent[i]

	func union(i: int, j: int) -> bool:
		var root_i = find(i)
		var root_j = find(j)
		if root_i != root_j:
			parent[root_i] = root_j
			return true 
		return false 

#endregion


var camera_direction_locks: Dictionary = {
	"X": false,
	"Y": false,
	"Z": false
}

var setting_up = true
var free_cam = false

var grid_size_x = 0
var grid_size_y = 0

var max_grid_size: Vector2 = Vector2(15, 15)

var min_room_density: float = 0.02
var max_room_density: float = 0.3

# Need to dynamically change this based on max_room_size
var absolute_min_rooms: int = 10
var absolute_max_rooms: int = 50

var current_floor = 0
var floor_count = 5

var spawn_position: Vector2i

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

		var bounding_box_arr: Array[Array] = []
		await remove_old_dungeon()
		setting_up = true
		
		while true:
			if await generate_dungeon(bounding_box_arr):
				break
			else:
				await remove_old_dungeon()
				bounding_box_arr.clear()
		setting_up = false
	print("FADING OUT")
	setting_up_new_floor = false
	await Fade.fade_out(2)
	movement_locked = false
	
var number_of_rooms = 0
var spawn_room_location
func generate_dungeon(bounding_box_arr):
	var generated_rooms
	var dungeon_clearable = false
	while (not dungeon_clearable):
		generated_rooms = _build_room_geometry(bounding_box_arr)
		
		var delaunay_edges = get_biased_delaunay_edges(generated_rooms)
		
		var mst_edges = generate_mst_paths(delaunay_edges, generated_rooms)
		
		carve_all_corridors(mst_edges, bounding_box_arr, generated_rooms)
		
		dynamically_retype_rooms(generated_rooms, bounding_box_arr)
		
		classify_corridors(generated_rooms, bounding_box_arr)
		
		var all_rooms_connected = true
		for dungeon in range(1, generated_rooms.size()):
			if not is_dungeon_winnable(generated_rooms[0].room_pos, generated_rooms[dungeon].room_pos, bounding_box_arr):
				all_rooms_connected = false
				break
		
		if all_rooms_connected:
			dungeon_clearable = true
			
			var spawn_count = 0
			var stair_count = 0
			for row in range(max_grid_size.x):
				for col in range(max_grid_size.y):
					if str(bounding_box_arr[row][col]) == "E":
						stair_count += 1
					elif str(bounding_box_arr[row][col]) == "S":
						spawn_count += 1
			if spawn_count > 1 or stair_count > 1:
				dungeon_clearable = false
				bounding_box_arr.clear()
				generated_rooms.clear()
		else:
			bounding_box_arr.clear()
			generated_rooms.clear()
		
	for row in range(max_grid_size.x):
		var row_string = ""
		for col in range(max_grid_size.y):
			row_string += str(bounding_box_arr[row][col]) + " "
		print(row_string)
	var ret_val = await instantiate_rooms(generated_rooms, bounding_box_arr)
	if not ret_val:
		return false
	mini_map._setup(self, bounding_box_arr, generated_rooms, spawn_position)

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

	player.position.x += (generated_rooms[0].room_x_coord * tile_size)
	player.position.z += (generated_rooms[0].room_y_coord * tile_size)
	
	var current_start = get_room_node_at(index_to_pos(spawn_room_location))
	player_start_position = Vector2(player.position.x, player.position.z)
	player.rotation_degrees.y = 0.0
	player.camera_pivot.rotation.y = 0.0
	player.camera_pivot.current_yaw = 0.0
	player.camera_pivot.current_pitch = 0.0
	player.camera_pivot.target_yaw = 0.0
	player.camera_pivot.target_pitch = 0.0

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


var number_of_allowed_2x2 = 1


@export var sector_cols: int = 3
@export var sector_rows: int = 3

@export var sector_width: int = 8
@export var sector_height: int = 8

func _build_room_geometry(bounding_box_arr):
	grid_size_x = int(max_grid_size.x)
	grid_size_y = int(max_grid_size.y)
	for x in range(max_grid_size.x):
		var col: Array = []
		for y in range(max_grid_size.y):
			col.append(0)
		bounding_box_arr.append(col)

	# Determining position and rotation of floor spawn	
	#var spawn_room_index = rng.randi_range(0, (max_grid_size.x * max_grid_size.y) - 1)
	
	var rand_val = rng.randi_range(0, 3)
	var random_x = 0
	var random_y = 0
	match rand_val:
		0:
			random_y = rng.randi_range(0, max_grid_size.y - 1)
		1:
			random_x = rng.randi_range(0, max_grid_size.x - 1)
		2:
			random_x = max_grid_size.x - 1
			random_y = rng.randi_range(0, max_grid_size.y - 1)
		3:
			random_y = max_grid_size.y - 1
			random_x = rng.randi_range(0, max_grid_size.x - 1)
	
	var spawn_pos = Vector2i(random_x, random_y)
	spawn_position = spawn_pos
	spawn_room_location = pos_to_index(spawn_pos)
	var rooms_already_present : Array[dungeon_room]

	print("SPAWN IS AT ", spawn_room_location)

	var on_left = (spawn_pos.x == 0)
	var on_right = (spawn_pos.x == grid_size_x - 1)
	var on_top = (spawn_pos.y == 0)
	var on_bottom = (spawn_pos.y == grid_size_y - 1)

	var spawn_is_on_edge = on_left or on_right or on_top or on_bottom
	var what_edges_is_spawn_on: Array[bool] = [on_left, on_right, on_top, on_bottom]
	
	var valid_facings = []
	for dir in range(4):
		if not what_edges_is_spawn_on[dir]:
			valid_facings.append(dir)
	var spawn_is_facing = valid_facings[rng.randi() % valid_facings.size()]
	rooms_already_present.append(dungeon_room.new(spawn_pos, int(spawn_pos.x), int(spawn_pos.y), spawn_is_facing, what_edges_is_spawn_on, "Spawn_Room"))

	var spawn_boss = false
	if floor_count == current_floor - 1:
		spawn_boss = true
		grid_size_x = 30
		grid_size_y = 30
		var room_names = ["Spawn_Room", "Room_Cap", "4-Way_Junction", "3-Way_Junction", "Corner_Junction", "2x2_Room", "Stair_Room", "Straight_Room"]


		var what_edges_is_room_on = get_room_boundary_allignment(2)
		

		
		var boss_pos = Vector2i(grid_size_x / 2, grid_size_y / 2)
		var pot_room = dungeon_room.new(boss_pos, boss_pos.x, boss_pos.y, [0, 1, 2, 3], what_edges_is_room_on, room_names[2], -1)
		spawn_room(2, boss_pos, -1, pot_room, rooms_already_present, bounding_box_arr)
	else:
		# Determining position and rotation of stairs down
		var exit_room_location = 0
		var has_stairs_down_found_valid_position = false
		var has_stairs_down_found_valid_rotation = false

		while not has_stairs_down_found_valid_position:
			exit_room_location = rng.randi_range(0, (grid_size_x * grid_size_y) - 1)
			
			if exit_room_location == spawn_room_location:
				continue
				
			var exit_pos = index_to_pos(exit_room_location)

			var on_left_exit = (exit_pos.x == 0)
			var on_right_exit = (exit_pos.x == grid_size_x - 1)
			var on_top_exit = (exit_pos.y == 0)
			var on_bottom_exit = (exit_pos.y == grid_size_y - 1)

			var exit_is_on_edge = on_left_exit or on_right_exit or on_top_exit or on_bottom_exit

			if exit_is_on_edge:
				continue
			
			var found_invalid = false
			for offset in INVALID_OFFSETS:
				for pos in INVALID_OFFSETS[offset]:
					if (exit_pos + pos) == spawn_pos:
						found_invalid = true
						continue
			if found_invalid:
				continue

			if not spawn_is_on_edge:
				var forbidden_positions = []
				for offset in INVALID_OFFSETS[spawn_is_facing]:
					forbidden_positions.append(spawn_pos + offset)
					
				if exit_pos in forbidden_positions:
					print("Invalid exit position")
					continue
			
			has_stairs_down_found_valid_position = true
		var exit_pos = index_to_pos(exit_room_location)
		var on_left_exit = (exit_pos.x == 0)
		var on_right_exit = (exit_pos.x == grid_size_x - 1)
		var on_top_exit = (exit_pos.y == 0)
		var on_bottom_exit = (exit_pos.y == grid_size_y - 1)

		var exit_is_on_edge = on_left_exit or on_right_exit or on_top_exit or on_bottom_exit
		var what_edges_is_exit_on: Array[bool] = [on_left_exit, on_right_exit, on_top_exit, on_bottom_exit]
		
		var valid_facings_exit = []
		for dir in range(4):
			if not what_edges_is_exit_on[dir]:
				valid_facings_exit.append(dir)
		var exit_is_facing = 0
		var exit_has_valid_rotation = false
		while (not exit_has_valid_rotation):
			exit_is_facing = valid_facings_exit[rng.randi() % valid_facings_exit.size()]
			if exit_is_facing == 0 and spawn_is_facing == 1:
				continue
			elif exit_is_facing == 1 and spawn_is_facing == 0:
				continue
			elif exit_is_facing == 2 and spawn_is_facing == 3:
				continue
			elif exit_is_facing == 3 and spawn_is_facing == 2:
				continue
			else:
				exit_has_valid_rotation = true
		rooms_already_present.append(dungeon_room.new(exit_pos, int(exit_pos.x), int(exit_pos.y), exit_is_facing, what_edges_is_exit_on, "Stair_Room"))
		bounding_box_arr[exit_pos.x][exit_pos.y] = "E"

	# 	func _init(position_, x_coord, y_coord, facing, room_name):
	

	
	bounding_box_arr[spawn_pos.x][spawn_pos.y] = "S"
	
	var grid_size = grid_size_x * grid_size_y
	
	var min_rooms = clamp(int(grid_size * min_room_density), absolute_min_rooms, absolute_max_rooms)
	var max_rooms = clamp(int(grid_size * max_room_density), absolute_min_rooms, absolute_max_rooms)
	
	if min_rooms > max_rooms:
		max_rooms = min_rooms
		
	number_of_rooms = randi_range(min_rooms, max_rooms)
	
	for i in range(number_of_rooms):
		var random_room_to_spawn = randi_range(1, rooms.size() - 2)

		if random_room_to_spawn == 6:
			print("YAY")
		var random_room_position = rng.randi_range(0, (grid_size_x * grid_size_y) - 1)
		var random_room_coords = index_to_pos(random_room_position)
		
		var what_edges_is_room_on = get_room_boundary_allignment(random_room_coords)
		
		var facing = valid_facings[rng.randi() % valid_facings.size()]

		
		var potential_room = dungeon_room.new(random_room_coords, int(random_room_coords.x), int(random_room_coords.y), facing , what_edges_is_room_on, room_names[random_room_to_spawn], i)

		spawn_room(random_room_to_spawn, random_room_position, i, potential_room, rooms_already_present, bounding_box_arr)
	return rooms_already_present

func spawn_room(random_room_to_spawn, random_room_position, i, potential_room: dungeon_room, rooms_already_present, bounding_box_arr):
	var random_room_coords = Vector2i(potential_room.room_x_coord, potential_room.room_y_coord)
	var what_edges_is_room_on = potential_room.border_check
	if not get_valid_direction(random_room_to_spawn, potential_room, potential_room.border_check):
		return false
	
	if room_names[random_room_to_spawn] == "2x2_Room":
		if number_of_allowed_2x2 <= 0:
			return false
			
		const OFFSETS_2X2 = [
			Vector2i(0, 0),  
			Vector2i(1, 0),  
			Vector2i(0, -1),  
			Vector2i(1, -1)   
		]
		
		var is_invalid = false
		for off in OFFSETS_2X2:
			var cell_coords = random_room_coords + off
			if cell_coords.x < 0 or cell_coords.x >= grid_size_x - 1 or cell_coords.y <= 0 or cell_coords.y >= grid_size_y - 1:
				is_invalid = true
				break
			
			if str(bounding_box_arr[cell_coords.x][cell_coords.y]) != "0":
				is_invalid = true
				break
			
			for dir in range(4):
				var nx = cell_coords.x + DIR_VECTORS[dir].x
				var ny = cell_coords.y + DIR_VECTORS[dir].y
				if nx >= 0 and nx < grid_size_x and ny >= 0 and ny < grid_size_y:
					var is_in_2x2 = false
					for inner_off in OFFSETS_2X2:
						if random_room_coords + inner_off == Vector2i(nx, ny):
							is_in_2x2 = true
							break
					if not is_in_2x2 and str(bounding_box_arr[nx][ny]) != "0":
						is_invalid = true
						break
			if is_invalid: break
			
		if is_invalid:
			return false

		const INTENTIONAL_DIRECTIONS = {
			0: [1, 2], 
			1: [0, 2], 
			2: [1, 3], 
			3: [0, 3]  
		}
		
		const EXTERNAL_DIRECTIONS = {
			0: [0, 3], # Top-Left can exit Left (0) or Up (2)
			1: [1, 3], # Top-Right can exit Right (1) or Up (2)
			2: [0, 2], # Bottom-Left can exit Left (0) or Down (3)
			3: [1, 2]  # Bottom-Right can exit Right (1) or Down (3)
		}
		
		var which_layout = rng.randi_range(0, 1)
		# 4-way is 2, 3-way is 4, corner is 5
		# 1 4-way and 3 corners
		which_layout = 1
		if which_layout == 0:
			var layout_success = false
			var rooms_to_spawn = []

			for four_way_idx in range(4):
				var candidate_rooms = []
				var all_cells_valid = true
				
				for l in range(4):
					var cell_coords = random_room_coords + OFFSETS_2X2[l]
					var is_four_way = (l == four_way_idx)
					
					if cell_coords.x < 0 or cell_coords.x >= grid_size_x or cell_coords.y < 0 or cell_coords.y >= grid_size_y:
						all_cells_valid = false
						break
					
					var room_type_name = "4-Way_Junction" if is_four_way else "Corner_Junction"
					what_edges_is_room_on = get_room_boundary_allignment(cell_coords)
					
					var new_potential_room = dungeon_room.new(cell_coords, cell_coords.x, cell_coords.y, null, what_edges_is_room_on, room_type_name, i)
					if is_four_way:
						for dir in INTENTIONAL_DIRECTIONS[l]:
							new_potential_room.add_internal_direction(dir)
						for dir in [0, 1, 2, 3]:
							if not (dir in INTENTIONAL_DIRECTIONS[l]):
								new_potential_room.add_direction(dir) # External doors
								new_potential_room.external_directions.append(dir)
					else:
						for dir in INTENTIONAL_DIRECTIONS[l]:
							new_potential_room.add_internal_direction(dir)
					
					if not check_room_placement(new_potential_room, rooms_already_present, random_room_to_spawn, bounding_box_arr):
						all_cells_valid = false
						break 
					
					if has_border_conflict(new_potential_room):
						all_cells_valid = false
						break
					
					candidate_rooms.append(new_potential_room)
					
				if all_cells_valid:
					rooms_to_spawn = candidate_rooms
					layout_success = true
					break 
					
			if layout_success:
				for new_potential_room in rooms_to_spawn:
					rooms_already_present.append(new_potential_room)
					bounding_box_arr[new_potential_room.room_x_coord][new_potential_room.room_y_coord] = new_potential_room.room_name_type[0]
				number_of_allowed_2x2 -= 1
		# 2 3-way and 2 corners
		else:
			var layout_success = false
			var rooms_to_spawn = [] 
			
			var indices = [0, 1, 2, 3]
			var three_way_idx1 = 0
			var three_way_idx2 = 0
			
			var valid_pair_found = false
			while not valid_pair_found:
				indices.shuffle()
				three_way_idx1 = indices[0]
				three_way_idx2 = indices[1]
				
				var offset1 = OFFSETS_2X2[three_way_idx1]
				var offset2 = OFFSETS_2X2[three_way_idx2]

				if offset1.x != offset2.x and offset1.y != offset2.y:
					valid_pair_found = true
			
			var candidate_rooms = []
			var all_cells_valid = true
			
			for l in range(4):
				var cell_coords = random_room_coords + OFFSETS_2X2[l]
				if cell_coords.x < 0 or cell_coords.x >= grid_size_x or cell_coords.y < 0 or cell_coords.y >= grid_size_y:
					all_cells_valid = false
					break
				
				var is_three_way = (l == three_way_idx1 or l == three_way_idx2)
				
				var room_type_name = "3-Way_Junction" if is_three_way else "Corner_Junction"
				what_edges_is_room_on = get_room_boundary_allignment(cell_coords)
				
				var new_potential_room = dungeon_room.new(cell_coords, cell_coords.x, cell_coords.y, null, what_edges_is_room_on, room_type_name, i)

				if is_three_way:
					for dir in INTENTIONAL_DIRECTIONS[l]:
						new_potential_room.add_internal_direction(dir)
					var possible_exits = EXTERNAL_DIRECTIONS[l]
					var chosen_exit = possible_exits[rng.randi() % possible_exits.size()]
					
					new_potential_room.add_direction(chosen_exit)
					
					new_potential_room.external_directions.append(chosen_exit)
				else:
					for dir in INTENTIONAL_DIRECTIONS[l]:
						new_potential_room.add_internal_direction(dir)
				
				if not check_room_placement(new_potential_room, rooms_already_present, random_room_to_spawn, bounding_box_arr):
					all_cells_valid = false
					break 
				
				if has_border_conflict(new_potential_room):
					all_cells_valid = false
					break
				
				candidate_rooms.append(new_potential_room)
				
			if all_cells_valid:
				rooms_to_spawn = candidate_rooms
				layout_success = true
				
			if layout_success:
				for new_potential_room_ in rooms_to_spawn:
					rooms_already_present.append(new_potential_room_)
					bounding_box_arr[new_potential_room_.room_x_coord][new_potential_room_.room_y_coord] = new_potential_room_.room_name_type[0]
				number_of_allowed_2x2 -= 1
	
	elif room_names[random_room_to_spawn] == "4-Way_Junction":
		var is_invalid = false
		if random_room_coords.x < 0 or random_room_coords.x >= grid_size_x or random_room_coords.y < 0 or random_room_coords.y >= grid_size_y:
			is_invalid = true
		else:
			for dir in range(4):
				var nx = random_room_coords.x + DIR_VECTORS[dir].x
				var ny = random_room_coords.y + DIR_VECTORS[dir].y
				if nx >= 0 and nx < grid_size_x and ny >= 0 and ny < grid_size_y:
					if str(bounding_box_arr[nx][ny]) != "0":
						is_invalid = true
						break
				
		if is_invalid:
			return false
			
		if check_room_placement(potential_room, rooms_already_present, random_room_to_spawn, bounding_box_arr):
			var can_place = true
			var potential_room_layout = []
			potential_room_layout.append(potential_room)
			var room_nums = [1, 7] # 1 = Room_Cap, 7 = Straight_Room
			
			var room_types = []
			var number_of_straight_rooms = 0
			for l in range(4):
				room_nums.shuffle()
				
				var chosen_index = room_nums[0]
				if chosen_index == 7:
					number_of_straight_rooms += 1
				if l == 3 and number_of_straight_rooms < 2:
					can_place = false
					break
						
				room_types.append(chosen_index)
				
				var direction_offset = DIR_VECTORS[l] 
				var new_coords = Vector2i(
					potential_room.room_pos.x + direction_offset.x, 
					potential_room.room_pos.y + direction_offset.y
				)
				
				if new_coords.x < 0 or new_coords.x >= grid_size_x or new_coords.y < 0 or new_coords.y >= grid_size_y:
					can_place = false
					break
					
				var cardinal_room_edge = get_room_boundary_allignment(new_coords)
				var potential_attachment = dungeon_room.new(
					new_coords, 
					int(new_coords.x), 
					int(new_coords.y), 
					null, 
					cardinal_room_edge, 
					room_names[chosen_index]
				)
				
				potential_attachment.add_direction(same_directions[l])
				
				if room_names[chosen_index] == "Straight_Room":
					potential_attachment.add_direction(l)
				
				if check_room_placement(potential_attachment, rooms_already_present, chosen_index, bounding_box_arr):
					potential_room_layout.append(potential_attachment)
				else:
					can_place = false
					break
				
			if can_place:
				for room_ in potential_room_layout:
					rooms_already_present.append(room_)
					
					var char_to_write = room_.room_name_type[0]
					if room_.room_name_type == "Straight_Room":
						char_to_write = "-"
						
					bounding_box_arr[room_.room_x_coord][room_.room_y_coord] = char_to_write 
			else:
				return false

	else:
		var is_invalid = false
		if random_room_coords.x < 0 or random_room_coords.x >= grid_size_x or random_room_coords.y < 0 or random_room_coords.y >= grid_size_y:
			is_invalid = true
		else:
			for dir in range(4):
				var nx = random_room_coords.x + DIR_VECTORS[dir].x
				var ny = random_room_coords.y + DIR_VECTORS[dir].y
				if nx >= 0 and nx < grid_size_x and ny >= 0 and ny < grid_size_y:
					if str(bounding_box_arr[nx][ny]) != "0":
						is_invalid = true
						break
				
		if is_invalid:
			return false
		if check_room_placement(potential_room, rooms_already_present, random_room_to_spawn, bounding_box_arr):
			rooms_already_present.append(potential_room)
			bounding_box_arr[random_room_coords.x][random_room_coords.y] = room_names[random_room_to_spawn][0]
		else:
			return false


var tile_size = 0
func instantiate_rooms(rooms_already_present, bounding_box_arr):
	tile_size = 3.2
	
	var room_lookup = {}
	for room_: dungeon_room in rooms_already_present:
		room_lookup[Vector2i(room_.room_x_coord, room_.room_y_coord)] = room_
	
	for x in range(max_grid_size.x):
		for y in range(max_grid_size.y):
			var room_to_load = room_symbol_mapping[str(bounding_box_arr[x][y])]
			if room_to_load == "Empty_Space":
				continue
			var new_instance = load(rooms[room_symbol_mapping[bounding_box_arr[x][y]]])
			var new_room = new_instance.instantiate()

			var base_position = Vector3(x * tile_size, 0.0, y * tile_size)
			new_room.room_coords = Vector2(x, y)
			new_room._setup(self)

			var direction = get_directions_at(x, y, room_lookup, bounding_box_arr)
			
			new_room.room_directions = direction
			new_room.rotation_degrees.y = get_rotation_degrees_(room_to_load, direction)


			new_room.room_directions.sort()
			if room_to_load == "3-Way_Junction":
				if new_room.room_directions.size() <= 2:
					return false
					
			new_room.position = base_position
			navigation_region.add_child(new_room)
			
			var grid_pos = Vector2i(x, y)
			active_room_nodes[grid_pos] = new_room
	return true

const ASSET_OFFSETS = {
	"Spawn_Room": 180.0,
	"Stair_Room": 180.0,
	"Room_Cap": 180.0,              
	"Corner_Junction": 90.0,       
	"Hallway_Corner": 0.0,
	"Horizontal_Corridor": 90.0,  
	"Vertical_Corridor": 90.0,
	"3-Way_Junction": 180.0,       
	"Hallway_3-Way_Junction": 0.0,
	"Straight_Room": 90.0,
	"T_Chest_Room": 180.0
}

func get_rotation_degrees_(room_type: String, directions: Array[int]) -> float:
	var exits = directions.duplicate()
	exits.sort() 
	
	var calculated_rot = 0.0
	
	if room_type in ["Room_Cap", "Spawn_Room", "Stair_Room", "T_Chest_Room"] and exits.size() == 1:
		match exits[0]:
			2: calculated_rot = 0.0   # Facing Up (North)
			1: calculated_rot = -90.0  # Facing Right (East)
			3: calculated_rot = 180.0 # Facing Down (South)
			0: calculated_rot = 90.0  # Facing Left (West)

	elif room_type in ["Corner_Junction", "Hallway_Corner"] and exits.size() == 2:
		if exits == [1, 2]: calculated_rot = 0.0   # Connects Right & Up
		if exits == [1, 3]: calculated_rot = -90.0  # Connects Right & Down
		if exits == [0, 3]: calculated_rot = 180.0 # Connects Left & Down
		if exits == [0, 2]: calculated_rot = 90.0  # Connects Left & Up

	elif room_type in ["Horizontal_Corridor", "Vertical_Corridor", "Straight_Room"] and exits.size() == 2:
		if exits == [2, 3]: calculated_rot = 90.0   # Vertical
		if exits == [0, 1]: calculated_rot = 0.0  # Horizontal

	elif room_type in ["3-Way_Junction", "Hallway_3-Way_Junction"] and exits.size() == 3:
		if exits == [0, 1, 2]: calculated_rot = 0.0   # Solid wall is Down (South)
		if exits == [1, 2, 3]: calculated_rot = -90.0  # Solid wall is Left (West)
		if exits == [0, 1, 3]: calculated_rot = 180.0 # Solid wall is Up (North)
		if exits == [0, 2, 3]: calculated_rot = 90.0  # Solid wall is Right (East)

	var asset_offset = ASSET_OFFSETS.get(room_type, 0.0)
	
	return calculated_rot + asset_offset

func get_directions_at(x: int, y: int, room_lookup: Dictionary, bounding_box_arr) -> Array[int]:
	var coord = Vector2i(x, y)
	
	if room_lookup.has(coord):
		return room_lookup[coord].room_direction
		
	var active_exits: Array[int] = []
	for dir in range(4):
		var neighbor = coord + DIR_VECTORS[dir]
		if neighbor.x >= 0 and neighbor.x < grid_size_x and neighbor.y >= 0 and neighbor.y < grid_size_y:
			var neighbor_val = str(bounding_box_arr[neighbor.x][neighbor.y])
			
			if neighbor_val != "0":
				if room_lookup.has(neighbor):
					var room = room_lookup[neighbor]
					var opposite_dir = same_directions[dir]
					if opposite_dir in room.room_direction:
						active_exits.append(dir)
				else:
					active_exits.append(dir)
					
	return active_exits

func dynamically_retype_rooms(rooms_already_present: Array, bounding_box_arr):
	for room_ in rooms_already_present:
		if room_.room_name_type in ["Spawn_Room", "Stair_Room", "T_Chest_Room"]:
			continue 
			
		var active_exits: Array[int] = []
		var room_coords = Vector2i(room_.room_x_coord, room_.room_y_coord)
		
		for dir in room_.room_direction:
			if room_.group_id != -1 and not room_.external_directions.has(dir):
				active_exits.append(dir)
				continue
			
			var neighbor_pos = room_coords + DIR_VECTORS[dir]
			if neighbor_pos.x >= 0 and neighbor_pos.x < grid_size_x and neighbor_pos.y >= 0 and neighbor_pos.y < grid_size_y:
				var neighbor_type = str(bounding_box_arr[neighbor_pos.x][neighbor_pos.y])
				
				if neighbor_type != "0":
					active_exits.append(dir)
					
		room_.room_direction = active_exits
		var count = active_exits.size()
		
		if count <= 1:
			room_.room_name_type = "Room_Cap"
		elif count == 2:
			if (0 in active_exits and 1 in active_exits) or (2 in active_exits and 3 in active_exits):
				room_.room_name_type = "Horizontal_Corridor"
			else:
				room_.room_name_type = "Corner_Junction"
		elif count == 3:
			room_.room_name_type = "3-Way_Junction"
		elif count == 4:
			room_.room_name_type = "4-Way_Junction"
			
		bounding_box_arr[room_.room_x_coord][room_.room_y_coord] = room_.room_name_type[0]

func classify_corridors(rooms_already_present: Array, bounding_box_arr):
	var temp_grid = bounding_box_arr.duplicate(true)
	
	var room_dict = {}
	for room_ in rooms_already_present:
		room_dict[Vector2i(room_.room_x_coord, room_.room_y_coord)] = room_
		
	for x in range(grid_size_x):
		for y in range(grid_size_y):
			if str(temp_grid[x][y]) == "H":
				var active_connections: Array[int] = []
				var current_pos = Vector2i(x, y)
				
				for dir in range(4):
					var neighbor = current_pos + DIR_VECTORS[dir]
					if neighbor.x >= 0 and neighbor.x < grid_size_x and neighbor.y >= 0 and neighbor.y < grid_size_y:
						var neighbor_val = str(temp_grid[neighbor.x][neighbor.y])
						
						if neighbor_val in ["H", "h", "-", "|", "c", "t", "+"]:
							active_connections.append(dir)
						
						elif neighbor_val != "0":
							if room_dict.has(neighbor):
								var adjacent_room = room_dict[neighbor]
								var opposite_dir = same_directions[dir]
								if opposite_dir in adjacent_room.room_direction:
									active_connections.append(dir)
										
				var count = active_connections.size()
				
				if count <= 1:
					bounding_box_arr[x][y] = "h" 
				elif count == 2:
					if 0 in active_connections and 1 in active_connections:
						bounding_box_arr[x][y] = "|" # Horizontal (Left/Right)
					elif 2 in active_connections and 3 in active_connections:
						bounding_box_arr[x][y] = "-" # Vertical (Up/Down)
					else:
						bounding_box_arr[x][y] = "c" # Corner
				elif count == 3:
					bounding_box_arr[x][y] = "t" # 3-Way
				elif count == 4:
					bounding_box_arr[x][y] = "+" # 4-Way
					

func connect_rooms(room_b: Node3D, marker_b_left: Node3D, marker_b_right: Node3D, marker_a_left: Node3D, marker_a_right: Node3D) -> void:
	marker_a_left.force_update_transform()
	marker_a_right.force_update_transform()
	marker_b_left.force_update_transform()
	marker_b_right.force_update_transform()
	
	var best_rotation: float = 0.0
	var best_offset: Vector3 = Vector3.ZERO
	var best_dot: float = 1.0 
	
	for i in range(4):
		var angle = i * (PI / 2.0)
		
		room_b.global_rotation.y = angle
		
		room_b.force_update_transform()
		marker_b_left.force_update_transform()
		marker_b_right.force_update_transform()
		marker_a_left.force_update_transform()
		marker_a_right.force_update_transform()
		
		var center_a = get_doorway_center(marker_a_left, marker_a_right)
		var center_b = get_doorway_center(marker_b_left, marker_b_right)
		
		var forward_a = (-marker_a_left.global_transform.basis.z - marker_a_right.global_transform.basis.z).normalized()
		var forward_b = (-marker_b_left.global_transform.basis.z - marker_b_right.global_transform.basis.z).normalized()
		var dot_product = forward_a.dot(forward_b)
		
		if dot_product < best_dot:
			best_dot = dot_product
			best_rotation = angle
			best_offset = center_a - center_b
			
	room_b.global_rotation.y = best_rotation
	room_b.force_update_transform()
	
	marker_b_left.force_update_transform()
	marker_b_right.force_update_transform()
	
	room_b.global_position += best_offset
	
	room_b.force_update_transform()
	marker_b_left.force_update_transform()
	marker_b_right.force_update_transform()
	
	var final_center_a = get_doorway_center(marker_a_left, marker_a_right)
	var final_center_b = get_doorway_center(marker_b_left, marker_b_right)
	
func get_biased_delaunay_edges(rooms_list: Array[dungeon_room]) -> Array[DungeonEdge]:
	var edges: Array[DungeonEdge] = []
	
	var room_positions = PackedVector2Array()
	for room in rooms_list:
		room_positions.append(Vector2(room.room_x_coord, room.room_y_coord))
		
	var triangles: PackedInt32Array = Geometry2D.triangulate_delaunay(room_positions)
	if triangles.is_empty():
		return edges
		
	var seen_edges = {}
	for i in range(0, triangles.size(), 3):
		var p1 = triangles[i]
		var p2 = triangles[i+1]
		var p3 = triangles[i+2]
		
		var triangle_edges = [[p1, p2], [p2, p3], [p3, p1]]
		for edge in triangle_edges:
			var u = min(edge[0], edge[1])
			var v = max(edge[0], edge[1])
			var key = str(u) + "_" + str(v)
			
			if not seen_edges.has(key):
				seen_edges[key] = true
				
				var room_a = rooms_list[u]
				var room_b = rooms_list[v]
				var base_dist = room_positions[u].distance_to(room_positions[v])
				
				var is_same_group = (room_a.group_id != -1 and room_a.group_id == room_b.group_id)
				
				var final_weight = base_dist
				
				if is_same_group:
					final_weight = 0.01
				else:
					if room_a.group_id != -1 and room_a.external_directions.is_empty():
						for sibling in rooms_list:
							if sibling.group_id == room_a.group_id and not sibling.external_directions.is_empty():
								room_a = sibling
								u = rooms_list.find(sibling)
								break
								
					if room_b.group_id != -1 and room_b.external_directions.is_empty():
						for sibling in rooms_list:
							if sibling.group_id == room_b.group_id and not sibling.external_directions.is_empty():
								room_b = sibling
								v = rooms_list.find(sibling)
								break
								
					var temp_u = min(u, v)
					var temp_v = max(u, v)
					u = temp_u
					v = temp_v
					
					base_dist = room_positions[u].distance_to(room_positions[v])
					final_weight = base_dist
					
					var dx = room_b.room_x_coord - room_a.room_x_coord
					var dy = room_b.room_y_coord - room_a.room_y_coord
					var dir_a_to_b = -1
					if abs(dx) > abs(dy):
						dir_a_to_b = 1 if dx > 0 else 0  
					else:
						dir_a_to_b = 3 if dy > 0 else 2  
					
					var dir_b_to_a = same_directions[dir_a_to_b]
					
					var a_has_door = dir_a_to_b in room_a.room_direction
					var b_has_door = dir_b_to_a in room_b.room_direction					
					
					if a_has_door and b_has_door:
						final_weight *= 0.1
					elif a_has_door or b_has_door:
						final_weight *= 20.0
					else:
						final_weight *= 5.0
					
				edges.append(DungeonEdge.new(u, v, final_weight))
				
	return edges

func generate_mst_paths(edges: Array[DungeonEdge], rooms_already_present) -> Array[DungeonEdge]:
	var final_mst_edges: Array[DungeonEdge] = []
	var discarded_edges: Array[DungeonEdge] = []
	
	edges.sort_custom(func(a, b): return a.weight < b.weight)
	
	var dsu = DisjointSet.new()
	dsu.make_set(rooms_already_present.size())
	
	for edge in edges:
		if dsu.union(edge.u, edge.v):
			final_mst_edges.append(edge)
		else:
			discarded_edges.append(edge)
			
	discarded_edges.shuffle()
	var loops_to_add = int(discarded_edges.size() * 0.12)
	var added_loops = 0
	var i = 0
	
	while added_loops < loops_to_add and i < discarded_edges.size():
		var edge = discarded_edges[i]
		i += 1
		
		if edge.u != 0 and edge.v != 0 and edge.u != 1 and edge.v != 1:
			final_mst_edges.append(edge)
			added_loops += 1
		
	return final_mst_edges
	
# Helper to get the absolute grid coordinates of a room's doors
func get_doorway_positions(room: dungeon_room) -> Array[Vector2i]:
	var doorways: Array[Vector2i] = []
	var room_coords = Vector2i(room.room_x_coord, room.room_y_coord)
	
	for dir in room.external_directions:
		var door_pos = room_coords + DIR_VECTORS[dir]
		if door_pos.x >= 0 and door_pos.x < grid_size_x and door_pos.y >= 0 and door_pos.y < grid_size_y:
			doorways.append(door_pos)
			
	if doorways.is_empty():
		doorways.append(room_coords)
		
	return doorways

func get_best_doorway_pair(room_a: dungeon_room, room_b: dungeon_room) -> Array[Vector2i]:
	var doors_a = get_doorway_positions(room_a)
	var doors_b = get_doorway_positions(room_b)
	
	var best_a: Vector2i
	var best_b: Vector2i
	var min_dist = INF
	
	for da in doors_a:
		for db in doors_b:
			var dist = da.distance_to(db)
			if dist < min_dist:
				min_dist = dist
				best_a = da
				best_b = db
				
	return [best_a, best_b]

func carve_all_corridors(mst_edges: Array[DungeonEdge], bounding_box_arr, rooms_already_present):
	var astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, grid_size_x, grid_size_y)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER 
	astar.update()
	
	var room_exits = {}
	for r in rooms_already_present:
		var exits = r.external_directions if r.group_id != -1 else r.room_direction
		room_exits[Vector2i(r.room_x_coord, r.room_y_coord)] = exits

	for x in range(grid_size_x):
		for y in range(grid_size_y):
			var pos = Vector2i(x, y)
			var cell_val = str(bounding_box_arr[x][y])
			
			if cell_val != "0" and cell_val != "H":
				astar.set_point_solid(pos, true)
			else:
				astar.set_point_solid(pos, false)
				var weight = 2.0
				
				var touches_wall = false
				var touches_door = false
				
				for dir in range(4):
					var nx = x + DIR_VECTORS[dir].x
					var ny = y + DIR_VECTORS[dir].y
					if nx >= 0 and nx < grid_size_x and ny >= 0 and ny < grid_size_y:
						var n_pos = Vector2i(nx, ny)
						var n_val = str(bounding_box_arr[nx][ny])
						
						if n_val != "0" and n_val != "H":
							var opposite_dir = same_directions[dir] 
							
							if room_exits.has(n_pos) and opposite_dir in room_exits[n_pos]:
								touches_door = true
							else:
								touches_wall = true
				
				if touches_wall and not touches_door:
					weight = 8000.0 
				elif touches_door:
					weight = 1.0 
					
				astar.set_point_weight_scale(pos, weight)
				
	for edge in mst_edges:
		var room_a = rooms_already_present[edge.u]
		var room_b = rooms_already_present[edge.v]
		
		var door_pair = get_best_doorway_pair(room_a, room_b)
		var start_door = door_pair[0]
		var end_door = door_pair[1]
		
		if astar.is_in_boundsv(start_door) and astar.is_in_boundsv(end_door):
			var was_start_solid = astar.is_point_solid(start_door)
			var was_end_solid = astar.is_point_solid(end_door)
			
			astar.set_point_solid(start_door, false)
			astar.set_point_solid(end_door, false)
			
			var path: Array[Vector2i] = astar.get_id_path(start_door, end_door)
			
			if not path.is_empty():
				for point in path:
					if str(bounding_box_arr[point.x][point.y]) == "0":
						bounding_box_arr[point.x][point.y] = "H"
						
						astar.set_point_solid(point, false)
						astar.set_point_weight_scale(point, 1.0)
						
						for dir in range(4):
							var nx = point.x + DIR_VECTORS[dir].x
							var ny = point.y + DIR_VECTORS[dir].y
							if nx >= 0 and nx < grid_size_x and ny >= 0 and ny < grid_size_y:
								if str(bounding_box_arr[nx][ny]) == "0":
									astar.set_point_weight_scale(Vector2i(nx, ny), 300.0)
			else:
				print("A* Failed to connect: ", edge.u, " to ", edge.v)
				
			astar.set_point_solid(start_door, was_start_solid)
			astar.set_point_solid(end_door, was_end_solid)

func is_dungeon_winnable(spawn_pos: Vector2i, exit_pos: Vector2i, bounding_box_arr) -> bool:
	var validation_astar = AStarGrid2D.new()
	validation_astar.region = Rect2i(0, 0, grid_size_x, grid_size_y)
	validation_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	validation_astar.update()
	
	var walkable_chars = ["H", "h", "-", "|", "c", "C", "t", "3", "+", "4", "S", "E", "R", "T"]
	
	for x in range(grid_size_x):
		for y in range(grid_size_y):
			var cell_val = str(bounding_box_arr[x][y])
			
			if cell_val in walkable_chars:
				validation_astar.set_point_solid(Vector2i(x, y), false)
			else:
				validation_astar.set_point_solid(Vector2i(x, y), true)
				
	var path: Array[Vector2i] = validation_astar.get_id_path(spawn_pos, exit_pos)
	
	return not path.is_empty()

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
		
	

func on_zone_changed(x_lock, y_lock, z_lock):
	camera_direction_locks["X"] = x_lock
	camera_direction_locks["Y"] = y_lock
	camera_direction_locks["Z"] = z_lock

func _physics_process(delta):
	return
	if setting_up:
		return
		
	if free_cam:
		_handle_free_cam_movement(delta)
		return 
		
	for key in camera_direction_locks:
		if not camera_direction_locks[key]:
			match key:
				"X":
					var target_x = player.position.x + camera_player_displacement.x
					#dungeon_camera.position.x = lerp(dungeon_camera.position.x, target_x, camera_speed * delta)
				"Y":
					var target_y = player.position.y + camera_player_displacement.y
					#dungeon_camera.position.y = lerp(dungeon_camera.position.y, target_y, camera_speed * delta)
				"Z":
					var target_z = player.position.z + camera_player_displacement.z
					#dungeon_camera.position.z = lerp(dungeon_camera.position.z, target_z, camera_speed * delta)
					
var free_cam_speed = 7.0
func _handle_free_cam_movement(delta: float) -> void:
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("right"):
		direction.x += 1.0
	if Input.is_action_pressed("left"):
		direction.x -= 1.0
	if Input.is_action_pressed("up"):
		direction.z -= 1.0
	if Input.is_action_pressed("down"):
		direction.z += 1.0 
	if Input.is_action_pressed("Dungeon_Attack"):
		direction.y += 1.0 
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		#dungeon_camera.position += direction * free_cam_speed * delta
