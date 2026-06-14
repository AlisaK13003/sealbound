extends Node

class_name dungeon_generation_helper

var room_names = ["Spawn_Room", "Room_Cap", "4-Way_Junction", "3-Way_Junction", "Corner_Junction", "2x2_Room", "Stair_Room", "Straight_Room"]
var number_of_allowed_2x2 = 3

const INVALID_OFFSETS = {
	0: [Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(-1, -1)], # Left
	1: [Vector2i(1, 0),  Vector2i(1, 1),  Vector2i(1, -1)],  # Right
	2: [Vector2i(0, 1),  Vector2i(1, 1),  Vector2i(-1, 1)],  # Up
	3: [Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1)]  # Down
}

const DIR_VECTORS = {
	0: Vector2i(-1, 0), # Left
	1: Vector2i(1, 0),  # Right
	2: Vector2i(0, -1), # Up
	3: Vector2i(0, 1)   # Down
}

var same_directions: Dictionary = {
	0: 1,
	1: 0,
	2: 3, 
	3: 2
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

var rng = RandomNumberGenerator.new()

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
		
		if facing != null:
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

func get_room_boundary_allignment(room_coords, grid_size_x, grid_size_y):
	# Checks if room lies on the border
	var on_left_room = (room_coords.x == 0)
	var on_right_room = (room_coords.x == grid_size_x - 1)
	var on_top_room = (room_coords.y == 0)
	var on_bottom_room = (room_coords.y == grid_size_y - 1)

	var what_edges_is_room_on: Array[bool] = [on_left_room, on_right_room, on_top_room, on_bottom_room]
	return what_edges_is_room_on

func index_to_pos(index: int, grid_size_x) -> Vector2i:
	return Vector2i(index % grid_size_x, index / grid_size_x)

func pos_to_index(pos: Vector2i, grid_size_x) -> int:
	return pos.y * grid_size_x + pos.x

func spawn_room(random_room_to_spawn, random_room_position, grid_size_x, grid_size_y, bounding_box_arr, i, rooms_already_present):
	var random_room_coords = index_to_pos(random_room_position, grid_size_x)
	var what_edges_is_room_on = get_room_boundary_allignment(random_room_coords, grid_size_x, grid_size_y)
	var potential_room: dungeon_room = dungeon_room.new(random_room_coords, int(random_room_coords.x), int(random_room_coords.y), null, what_edges_is_room_on, room_names[random_room_to_spawn])
			#var potential_room = dungeon_room.new(random_room_coords, int(random_room_coords.x), int(random_room_coords.y), null, what_edges_is_room_on, room_names[random_room_to_spawn])

	if not get_valid_direction(random_room_to_spawn, potential_room, what_edges_is_room_on):
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
					what_edges_is_room_on = get_room_boundary_allignment(cell_coords, grid_size_x, grid_size_y)
					
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
				what_edges_is_room_on = get_room_boundary_allignment(cell_coords, grid_size_x, grid_size_y)
				
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
					
				var cardinal_room_edge = get_room_boundary_allignment(new_coords, grid_size_x, grid_size_y)
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
	
func has_border_conflict(room_) -> bool:
	for dir in room_.room_direction:
		if room_.border_check[dir]:
			return true 
	return false
	
func get_door_alignment(room_a, room_b):
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
