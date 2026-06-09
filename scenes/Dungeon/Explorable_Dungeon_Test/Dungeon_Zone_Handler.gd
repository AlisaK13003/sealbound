extends Node3D

class_name explorable_dungeon

@onready var dungeon_camera = $Dungeon_Camera
@onready var player = $"3dPlayer2"
@onready var dungeon_zones: Array[Node] = $Zones.get_children()
@onready var navigation_region = $NavigationRegion3D

var camera_player_displacement: Vector3

var rng = RandomNumberGenerator.new()

var camera_speed = 3.0:
	set(value):
		camera_speed = value

enum cardinal_directions_locks {X, Y, Z}

signal zone_changed

var room_names = ["Spawn_Room", "Room_Cap", "4-Way_Junction", "3-Way_Junction", "Corner_Junction", "2x2_Room", "Stair_Room"]
var rooms : Dictionary = {
	"Spawn_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Basic_Room.tscn",
	"Room_Cap": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Basic_Room.tscn",
	"4-Way_Junction": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/T_Junction.tscn",
	"3-Way_Junction": "",
	"Corner_Junction": "",
	"2x2_Room": "",
	"Stair_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Basic_Room.tscn"
}

var room_sizing : Dictionary = {
	"Spawn_Room": 1,
	"Room_Cap": 1,
	"Horizontal_Corridor": 1,
	"4-Way_Junction": 1,
	"3-Way_Junction": 1,
	"Corner_Junction": 1,
	"2x2_Room": 2,
	"Stair_Room": 1
}

var room_exits: Dictionary = {
	"Spawn_Room": 1,
	"Room_Cap": 1,
	"Horizontal_Corridor": 2,
	"4-Way_Junction": 4,
	"3-Way_Junction": 3,
	"Corner_Junction": 2,
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

var max_grid_size: Vector2 = Vector2(15, 15)

var camera_direction_locks: Dictionary = {
	"X": false,
	"Y": false,
	"Z": false
}

var setting_up = true
var free_cam = false

func _ready():
	camera_player_displacement = dungeon_camera.position - player.position
	dungeon_camera.position.x = player.position.x + camera_player_displacement.x
	zone_changed.connect(on_zone_changed)
	for zone in dungeon_zones:
		zone._setup(self)
	print("DONE")
	generate_dungeon()
	setting_up = false
	$"3dPlayer2"._setup(self)

func generate_dungeon() -> void:
	_build_room_geometry()
	
	await get_tree().physics_frame
	
	navigation_region.bake_navigation_mesh(true)
	
	await navigation_region.bake_finished
	
	_spawn_enemies_and_initialize()

var grid_size_x = 0
var grid_size_y = 0

# Total number of possible rooms / 3
var max_number_of_rooms = 1
# Total number of possible rooms / 5
var min_number_of_rooms = 3

func index_to_pos(index: int) -> Vector2i:
	return Vector2i(index % grid_size_x, index / grid_size_x)

func pos_to_index(pos: Vector2i) -> int:
	return pos.y * grid_size_x + pos.x

class dungeon_room:
	var room_pos: Vector2i
	var room_x_coord: int
	var room_y_coord: int
	var room_direction: Array[int] = []
	var room_name_type: String
	var border_check: Array[bool]
	func _init(position_, x_coord, y_coord, facing, border, room_name):
		room_pos = position_
		room_x_coord = x_coord
		room_y_coord = y_coord
		if facing != null:
			room_direction.append(facing)
		room_name_type = room_name
		border_check = border
		
	func add_direction(new_direction):
		room_direction.append(new_direction)
		
	func reset_directions():
		room_direction.clear()

const INVALID_OFFSETS = {
	0: [Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(-1, -1)], # Left
	1: [Vector2i(1, 0),  Vector2i(1, 1),  Vector2i(1, -1)],  # Right
	2: [Vector2i(0, 1),  Vector2i(1, 1),  Vector2i(-1, 1)],  # Up
	3: [Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1)]  # Down
}

func _build_room_geometry():
	var spawn_room = load(rooms["Spawn_Room"])
	var spawn_room_instance = spawn_room.instantiate()
	self.add_child(spawn_room_instance)
	var spawn_room_bounds = spawn_room_instance.get_combined_size(spawn_room_instance)
	var bounding_box = Vector2(spawn_room_bounds.x * max_grid_size.x, spawn_room_bounds.y * max_grid_size.y)
	grid_size_x = int(max_grid_size.x)
	grid_size_y = int(max_grid_size.y)
	
	# Determining position and rotation of floor spawn	
	var spawn_room_location = rng.randi_range(0, (max_grid_size.x * max_grid_size.y) - 1)

	var spawn_pos = index_to_pos(spawn_room_location)

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
	
	# Determining position and rotation of stairs down
	var exit_room_location = 0
	var has_stairs_down_found_valid_position = false
	var has_stairs_down_found_valid_rotation = false

	while not has_stairs_down_found_valid_position:
		exit_room_location = rng.randi_range(0, (grid_size_x * grid_size_y) - 1)
		
		if exit_room_location == spawn_room_location:
			continue
			
		var exit_pos = index_to_pos(exit_room_location)

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
			valid_facings.append(dir)
	var exit_is_facing = 0
	var exit_has_valid_rotation = false
	while (not exit_has_valid_rotation):
		exit_is_facing = valid_facings[rng.randi() % valid_facings.size()]
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
	
	# 	func _init(position_, x_coord, y_coord, facing, room_name):
	var rooms_already_present : Array[dungeon_room]
	rooms_already_present.append(dungeon_room.new(spawn_pos, int(spawn_pos.x), int(spawn_pos.y), spawn_is_facing, what_edges_is_spawn_on, "Spawn_Room"))
	rooms_already_present.append(dungeon_room.new(exit_pos, int(exit_pos.x), int(exit_pos.y), exit_is_facing, what_edges_is_exit_on, "Stair_Room"))
	
	var bounding_box_arr : Array[Array] = []
	for x in range(max_grid_size.x):
		var col: Array = []
		for y in range(max_grid_size.y):
			col.append(0)
		bounding_box_arr.append(col)
	
	bounding_box_arr[spawn_pos.x][spawn_pos.y] = "S"
	bounding_box_arr[exit_pos.x][exit_pos.y] = "E"
	
	var grid_size = grid_size_x * grid_size_y
	var number_of_rooms = randi_range(ceil(grid_size / min_number_of_rooms), ceil(grid_size / max_number_of_rooms))
	print("Number of Rooms: ", number_of_rooms)
	
	for i in range(number_of_rooms):
		var random_room_to_spawn = randi_range(1, rooms.size() - 2)
		var random_room_position = rng.randi_range(0, (grid_size_x * grid_size_y) - 1)
		var random_room_coords = index_to_pos(random_room_position)
		
		var what_edges_is_room_on = get_room_boundary_allignment(random_room_coords)

		var potential_room = dungeon_room.new(random_room_coords, int(random_room_coords.x), int(random_room_coords.y), null, what_edges_is_room_on, room_names[random_room_to_spawn])

		if not get_valid_direction(random_room_to_spawn, potential_room, what_edges_is_room_on):
			continue
		
		if room_names[random_room_to_spawn] == "2x2_Room":
			continue
			var which_layout = rng.randi_range(0, 1)
			# 4-way is 2, 3-way is 4, corner is 5
			# 1 4-way and 3 corners
			if which_layout == 0:
				for room_location in range(4):
					if i == 0:
						potential_room = dungeon_room.new(random_room_coords, int(random_room_coords.x), int(random_room_coords.y), null, what_edges_is_room_on, room_names[2])
					else:
						potential_room = dungeon_room.new(random_room_coords, int(random_room_coords.x), int(random_room_coords.y), null, what_edges_is_room_on, room_names[5])
					what_edges_is_room_on = get_room_boundary_allignment(random_room_coords)
					if not get_valid_direction(2, potential_room, what_edges_is_room_on):
						pass
					if check_room_placement(potential_room, rooms_already_present, random_room_to_spawn, bounding_box_arr):
						pass
					pass
			# 2 3-way and 2 corners
			else:
				potential_room = dungeon_room.new(random_room_coords, int(random_room_coords.x), int(random_room_coords.y), null, what_edges_is_room_on, room_names[3])

				

				pass

		# If room cap, corner, or 3-way, or 4-way
		else:
			check_room_placement(potential_room, rooms_already_present, random_room_to_spawn, bounding_box_arr)
		
	print("0 1 2 3 4 5 6 7 8 9")
	for y in range(max_grid_size.y):
		var row_string = ""
		
		# Inner loop iterates horizontally (X/Columns)
		for x in range(max_grid_size.x):
			# Add a space or tab (\t) to keep elements aligned
			row_string += str(bounding_box_arr[x][y]) + " "
		row_string += (" " + str(y))
		print(row_string)
		
	print(rooms_already_present[0].room_pos)
	print(rooms_already_present[0].room_direction)
	print(rooms_already_present[1].room_pos)
	print(rooms_already_present[1].room_direction)
	return
	var horizontal_room = load(rooms["Junction"])
	var room_cap = load(rooms["Room_Cap"])
	
	var horizontal_room_instance = horizontal_room.instantiate()
	var room_cap_instance = room_cap.instantiate()
	
	horizontal_room_instance.position = Vector3(0, 0, 0)
	room_cap_instance.position = Vector3(0, 0, 0)
	
	self.add_child(horizontal_room_instance)
	self.add_child(room_cap_instance)
	
	var room_1_markers = null
	for marker_container in horizontal_room_instance.entrance_markers:
		if not horizontal_room_instance.entrance_markers[marker_container]:
			room_1_markers = marker_container
			break
	var room_2_markers = null
	for marker_container in room_cap_instance.entrance_markers:
		if not room_cap_instance.entrance_markers[marker_container]:
			room_2_markers = marker_container
			break
	
	connect_rooms(
			horizontal_room_instance, 
			room_1_markers.get_child(0), 
			room_1_markers.get_child(1), 
			room_2_markers.get_child(0), 
			room_2_markers.get_child(1)
		)	

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
	
	# 8, 2     up down left
	# 9, 2     left
	
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

func check_room_placement(room_to_check: dungeon_room, room_to_check_against, room_index, bounding_box_arr):
	var can_place_room = true
	var forbidden_positions = []
	
	var rooms_already_present: Array[dungeon_room] = room_to_check_against
	
	if room_to_check.room_name_type == "Room_Cap":
		for direction in INVALID_OFFSETS:
			for offset in INVALID_OFFSETS[direction]:
				forbidden_positions.append(rooms_already_present[0].room_pos + offset)
				forbidden_positions.append(rooms_already_present[1].room_pos + offset)
				
	if room_to_check.room_pos in forbidden_positions:
		can_place_room = false
		return can_place_room
				
	for placed_rooms: dungeon_room in rooms_already_present:
		if room_to_check.room_pos.x == placed_rooms.room_x_coord and room_to_check.room_pos.y == placed_rooms.room_y_coord:
			print("TRYING TO OVERWRITE")
			can_place_room = false
			break
		
		if not get_door_alignment(room_to_check, placed_rooms):
			can_place_room = false
			break
			
		var room_forbidden_positions = []
		var placed_coords = Vector2i(placed_rooms.room_x_coord, placed_rooms.room_y_coord)
		
		for direction in placed_rooms.room_direction:
			for offset in INVALID_OFFSETS[direction]:
				room_forbidden_positions.append(placed_coords + offset) 
		
		if true in room_to_check.border_check:
			if room_to_check.border_check[0] and 0 in room_to_check.room_direction:
				can_place_room = false
			if room_to_check.border_check[1] and 1 in room_to_check.room_direction:
				can_place_room = false
			if room_to_check.border_check[2] and 2 in room_to_check.room_direction:
				can_place_room = false
			if room_to_check.border_check[3] and 3 in room_to_check.room_direction:
				can_place_room = false
		
		if room_to_check.room_pos in room_forbidden_positions:
			can_place_room = false
			break
			
	if can_place_room:
		print("SPAWNING ", room_to_check.room_name_type)
		print(room_to_check.room_pos)
		print(room_to_check.room_direction)
		rooms_already_present.append(room_to_check)
		bounding_box_arr[room_to_check.room_pos.x][room_to_check.room_pos.y] = room_names[room_index][0]
	return can_place_room

func get_doorway_center(left_marker: Node3D, right_marker: Node3D) -> Vector3:
	return (left_marker.global_position + right_marker.global_position) / 2.0

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
	

func _spawn_enemies_and_initialize() -> void:
	# Example spawning logic
	#var enemy = enemy_scene.instantiate()
	#add_child(enemy)
	#enemy.global_position = target_spawn_point
	
	$"3dEnemy"._setup(self)

func on_zone_changed(x_lock, y_lock, z_lock):
	camera_direction_locks["X"] = x_lock
	camera_direction_locks["Y"] = y_lock
	camera_direction_locks["Z"] = z_lock

func _input(event):
	if event.is_action_pressed("Pause"):
		free_cam = not free_cam
		print("FREE CAM ACTIVE: ", free_cam)
		if free_cam:
			dungeon_camera.fov = 75.0
		else:
			dungeon_camera.fov = 15.0

func _physics_process(delta):
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
					dungeon_camera.position.x = lerp(dungeon_camera.position.x, target_x, camera_speed * delta)
				"Y":
					var target_y = player.position.y + camera_player_displacement.y
					dungeon_camera.position.y = lerp(dungeon_camera.position.y, target_y, camera_speed * delta)
				"Z":
					var target_z = player.position.z + camera_player_displacement.z
					dungeon_camera.position.z = lerp(dungeon_camera.position.z, target_z, camera_speed * delta)
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
		dungeon_camera.position += direction * free_cam_speed * delta
