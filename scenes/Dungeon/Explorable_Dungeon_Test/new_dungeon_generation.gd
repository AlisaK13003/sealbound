extends Node3D

class_name dungeon_generation

class dungeon_room:
	var room_pos: Vector2i
	var required_directions: Array[int] = []
	var total_direction_count: int = 0
	var room_name_type: String
	var group_id: int = -1 
	var asset_path: String
	
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
	
	const room_symbol_mapping: Dictionary[String, String] = {
		"S": "Spawn_Room",
		"D": "Stair_Room",
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

	const rooms : Dictionary[String, String] = {
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
	
	func _init(position_, facing, total_dir_count, room_name, grp_id = -1):
		room_pos = position_
		room_name_type = room_name
		group_id = grp_id
		if facing == null:
			pass
		elif facing != null or facing.size() != 0:
			for dir in facing:
				required_directions.append(dir)
		total_direction_count = total_dir_count
		#required_directions.sort()
			
	func add_direction(new_direction: int) -> bool:
		if required_directions.has(new_direction):
			return true
			
		if required_directions.size() >= total_direction_count:
			if room_name_type == "Generic_Path" and total_direction_count < 4:
				total_direction_count += 1 
			else:
				return false 
		
				
		required_directions.append(new_direction)
		return true
	
	func update_location(new_pos):
		self.room_pos = new_pos
		
	func duplicate():
		return dungeon_room.new(room_pos, required_directions.duplicate(), total_direction_count, room_name_type, group_id)
	
	func update_asset_path():
		asset_path = rooms[room_symbol_mapping[room_name_type[0]]]
		
	func get_rotation_degrees_() -> float:		
		var temp_directions = required_directions.duplicate()
		temp_directions.sort()

		if room_name_type == "Down":
			match temp_directions[0]:
				0: return 180.0   # Facing Up (North)
				3: return -90.0    # Facing Right (East)
				2: return 0.0     # Facing Down (South)
				1: return -90.0   # Facing Left (West)  #asdf

		# Completely unified lookup guaranteeing logic and visuals ALWAYS perfectly align
		if temp_directions.size() == 1:
			match temp_directions[0]:
				0: return 180.0   # Facing Up (North)
				3: return 90.0    # Facing Right (East)
				2: return 0.0     # Facing Down (South)
				1: return -90.0   # Facing Left (West)

		elif temp_directions.size() == 2:
			if temp_directions == [0, 3]: return 90.0   # Connects Right & Up
			if temp_directions == [2, 3]: return 0.0    # Connects Right & Down
			if temp_directions == [1, 2]: return -90.0  # Connects Left & Down
			if temp_directions == [0, 1]: return 180.0  # Connects Left & Up
			
			if temp_directions == [0, 2]: return 0.0    # Vertical Straight
			if temp_directions == [1, 3]: return 90.0   # Horizontal Straight

		elif temp_directions.size() == 3:
			if temp_directions == [0, 1, 3]: return 180.0   # Solid wall is Down (South)
			if temp_directions == [0, 2, 3]: return 90.0    # Solid wall is Left (West)
			if temp_directions == [1, 2, 3]: return 0.0     # Solid wall is Up (North)
			if temp_directions == [0, 1, 2]: return -90.0   # Solid wall is Right (East)

		return 0.0

class room_template:
	var sub_rooms: Dictionary[Vector2i, dungeon_room]
	
	var room_size: Vector2i
	
	var cur_rotation: int = 0
	
	func _init(subrooms_: Array[dungeon_room], room_dim):
		room_size = room_dim
		for room_: dungeon_room in subrooms_:
			sub_rooms[room_.room_pos] = room_
		
	# The connecting direction is still rotated at (0, 0) so it shouldn't do that
	func clock_wise_rotation():
		for room_: dungeon_room in sub_rooms.values():
			var old_pos: Vector2 = Vector2(room_.room_pos.x, room_.room_pos.y)
			room_.room_pos = Vector2i(-old_pos.y, old_pos.x)
				
			for dir in range(room_.required_directions.size()):
				room_.required_directions[dir] = (room_.required_directions[dir] + 3) % 4
		
		print(sub_rooms[Vector2i(0, 0)].room_pos)
		print(cur_rotation)
		for room_: dungeon_room in sub_rooms.values():
			print(room_.required_directions)
		
		# Rebuild the dictionary with updated keys
		var new_sub_rooms: Dictionary[Vector2i, dungeon_room] = {}
		for room_: dungeon_room in sub_rooms.values():
			new_sub_rooms[room_.room_pos] = room_

		sub_rooms = new_sub_rooms  # ← outside the loop
		cur_rotation += 1
		cur_rotation += 1
		print()

	func duplicate():
		var room_arr: Array[dungeon_room] = []
		for room_: dungeon_room in self.sub_rooms.values():
			room_arr.append(room_.duplicate())
		
		var new_template = room_template.new(room_arr, self.room_size)
		return new_template

const DIR_VECTORS = {
	0: Vector2i(0, -1), # Up    (North) - Y decreases going up
	1: Vector2i(-1, 0), # Left  (West)
	2: Vector2i(0, 1),  # Down  (South) - Y increases going down  
	3: Vector2i(1, 0),  # Right (East)
}

var same_directions: Dictionary = {
	0: 2,
	1: 3,
	2: 0, 
	3: 1
}

func build_dungeon():
	build_room_templates()

	var room_storage: Dictionary[Vector2i, dungeon_room]

	var valid_room_layout_generated: bool = false
	while not valid_room_layout_generated:
		if build_rooms(room_storage):
			valid_room_layout_generated = true
		else:
			room_storage.clear()
		
	var min_x_key: int = 0
	var min_y_key: int = 0
	var max_x_key: int = 0
	var max_y_key: int = 0
	for key: Vector2i in room_storage.keys():
		if key.x <= min_x_key:
			min_x_key = key.x
		elif key.x >= max_x_key:
			max_x_key = key.x
			
		if key.y <= min_y_key:
			min_y_key = key.y
		elif key.y >= max_y_key:
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
		var row = str(y) + "       "
		for x in range(width):
			row += bounding_box_arr[x][y] + " "
		print(row)
	
	return room_storage

func build_room_templates():
	# TEMPLATE 1: 2x2 with 2 corners and 2 3-ways
	# Top-Left (0,0) connects Right (3) and Down (0) internally. Has external door Left (1).
	var top_left_1 = dungeon_room.new(Vector2i(0, 0), [2, 3], 3, "3_way_junction", 1)
	# Top-Right (1,0) connects Left (1) and Down (0) internally.
	var top_right_1 = dungeon_room.new(Vector2i(1, 0), [1, 2], 2, "Corner_Junction", 1)
	# Bottom-Left (0,1) connects Right (3) and Up (2) internally.
	var bottom_left_1 = dungeon_room.new(Vector2i(0, 1), [0, 3], 2, "Corner_Junction", 1)
	# Bottom-Right (1,1) connects Left (1) and Up (2) internally, plus external Right (3) for exit.
	var bottom_right_1 = dungeon_room.new(Vector2i(1, 1), [0, 1], 3, "3_way_junction", 1)
	
	potential_rooms.append(room_template.new([top_left_1, top_right_1, bottom_left_1, bottom_right_1], Vector2i(2,2)))
	
	# TEMPLATE 2: 2x2 with 3 corners and 1 3-way
	var top_left_2 = dungeon_room.new(Vector2i(0, 0), [3, 0], 2, "Corner_Junction", 2)
	var top_right_2 = dungeon_room.new(Vector2i(1, 0), [1, 0], 2, "Corner_Junction", 2)
	var bottom_left_2 = dungeon_room.new(Vector2i(0, 1), [3, 2], 2, "Corner_Junction", 2)
	var bottom_right_2 = dungeon_room.new(Vector2i(1, 1), [1, 2], 3, "3_way_junction", 2)
	
	potential_rooms.append(room_template.new([top_left_2, top_right_2, bottom_left_2, bottom_right_2], Vector2i(2,2)))

var potential_rooms: Array[room_template]

var walk_path: Array[Vector2i]

func build_rooms(room_storage):
	var rng = RandomNumberGenerator.new()
	
	
	# Sets up spawn location
	var spawn_location: Vector2i = Vector2i(0, 0)

	var spawn_room = dungeon_room.new(spawn_location, [], 1, "Spawn_Room")
	room_storage[spawn_location] = spawn_room
	var main_walker_lifetime: int = 15 # randi_range(10, 15)
	var main_walker_setps: int = 0
	
	var walker_current_location: Vector2i = spawn_location
	
	var valid_critical_path_found: bool = false
	
	# Iterates until all steps have found a valid position
	while not valid_critical_path_found:
		# walker_algorithm can return false, true, and current location
		var end_location = walker_algorithm(main_walker_lifetime, walker_current_location, room_storage, true)
		
		if end_location is bool:
			if not end_location:
				room_storage.clear()
				spawn_location = Vector2i(0, 0)
		
				spawn_room = dungeon_room.new(spawn_location, [], 1, "Spawn_Room")
				room_storage[spawn_location] = spawn_room
				continue
				
		var placed_stairs_down: bool = false
		for dir in [0, 1, 2, 3]:
			if room_storage.has(end_location + DIR_VECTORS[dir]):
				if dir in room_storage[end_location + DIR_VECTORS[dir]].required_directions:
					room_storage[end_location] = dungeon_room.new(end_location, [dir], 1, "Down")
					placed_stairs_down = true
					break
					
		if placed_stairs_down:
			valid_critical_path_found = true
		else:
			room_storage.clear()
			spawn_location = Vector2i(0, 0)
			spawn_room = dungeon_room.new(spawn_location, [], 1, "Spawn_Room")
			room_storage[spawn_location] = spawn_room
			continue
	
	var has_all_directions_been_satisfied: bool = false

	while not has_all_directions_been_satisfied:
		# Check all current rooms to see if the amount of directions that have matches the number they should
		#    If it doesn't then they need a continuation
		var num_of_other_walkers: Array[Vector2i] = []
		for room_: dungeon_room in room_storage.values():
			if (room_.required_directions.size()) != room_.total_direction_count:
				num_of_other_walkers.append(room_.room_pos)
		if num_of_other_walkers.size() == 0:
			has_all_directions_been_satisfied = true
			continue
			
		var small_walker_allowed_steps= 10
		for pos in num_of_other_walkers:
			var valid_path_found: bool = false
			
			var max_attempts: int = 10
			var attempts: int = 0
			
			while not valid_path_found:
				attempts += 1
				if attempts == max_attempts:
					return false
				var simulated_storage = duplicate_dungeon_dict(room_storage)
				
				# walker_algorithm can return false, true, and current location
				var end_location = walker_algorithm(small_walker_allowed_steps, pos, simulated_storage, false)
				
				if typeof(end_location) == TYPE_BOOL and end_location:
					room_storage = simulated_storage
					valid_path_found = true
				elif typeof(end_location) == TYPE_BOOL and not end_location:
					valid_path_found = false
					continue
			
				valid_path_found = true
				
				var chance = rng.randf()
				
				var correct_direction = 0
				for dir in [0, 1, 2, 3]:
					var adjacent_pos = end_location + DIR_VECTORS[dir]
					
					if simulated_storage.has(adjacent_pos):
						var adjacent_room = simulated_storage[adjacent_pos]
						
						var dir_from_cap_to_adj = dir
						var dir_from_adj_to_cap = same_directions[dir]
						
						# If the adjacent room has a door pointing AT us, we point our door back AT it!
						if dir_from_adj_to_cap in adjacent_room.required_directions:
							correct_direction = dir_from_cap_to_adj
							break
				
				# Spawn end room template
				if chance < 0.2:
					simulated_storage[end_location] = dungeon_room.new(end_location, [correct_direction], 1, "T")
				# Spawn basic treasure room
				elif chance < 0.3:
					simulated_storage[end_location] = dungeon_room.new(end_location, [correct_direction], 1, "T")
				else:
					simulated_storage[end_location] = dungeon_room.new(end_location, [correct_direction], 1, "R")

				for room_pos in simulated_storage:
					room_storage[room_pos] = simulated_storage[room_pos].duplicate()
			if not valid_path_found:
				room_storage[pos].total_direction_count = room_storage[pos].required_directions.size()

	evaluate_room_names(room_storage)
	return true

func duplicate_dungeon_dict(original_dict: Dictionary) -> Dictionary:
	var new_dict: Dictionary[Vector2i, dungeon_room] = {}
	for key in original_dict:
		var old_room = original_dict[key]
		# Deep copy the array so the doors are truly isolated
		var copied_dirs = old_room.required_directions.duplicate() 
		
		var new_room = dungeon_room.new(
			old_room.room_pos, 
			copied_dirs, 
			old_room.total_direction_count, 
			old_room.room_name_type, 
			old_room.group_id
		)
		new_dict[key] = new_room
		
	return new_dict

func evaluate_room_names(room_storage):
	for room_: dungeon_room in room_storage.values():
		if room_.room_name_type == "Spawn_Room" or room_.group_id != -1 or room_.room_name_type == "Down" or room_.room_name_type == "T":
			room_.update_asset_path()
			continue
			
		var doors = room_.total_direction_count
		
		if doors == 1:
			room_.room_name_type = "Room_Cap"
		elif doors == 3:
			room_.room_name_type = "3_way_junction"
		elif doors == 4:
			room_.room_name_type = "4_way_junction"
		elif doors == 2:
			var d1 = room_.required_directions[0]
			var d2 = room_.required_directions[1]
			
			if (d1 == 0 and d2 == 2) or (d1 == 2 and d2 == 0):
				room_.room_name_type = "|Room"
			elif (d1 == 1 and d2 == 3) or (d1 == 3 and d2 == 1):
				room_.room_name_type = "-Room"
			else:
				room_.room_name_type = "Corner_Junction"
				
		room_.update_asset_path()

func walker_algorithm(step_limit, start_location, room_storage, is_main_path):
	var rng = RandomNumberGenerator.new()
	var walker_current_location: Vector2i = start_location
	
	var last_direction: int = -1
	var last_direction_count: int = 0
	
	var changed_directions: bool = false
	
	var needs_to_change_directions: bool = false
	
	# Given the starting room, figuring the directions that we are allowed to step in
	var dirs = [0, 1, 2, 3]
	for pot_dir in room_storage[start_location].required_directions:
		dirs.erase(pot_dir)
	
	if dirs.size() == 0:
		return false
	
	var currently_heading_in_x_direction: int = dirs.pick_random()
	
	# Take a step until we reach the max amount of alloted steps
	var current_steps: int = 0
	var straight_limit = rng.randi_range(2, 5)
	while current_steps < step_limit:
		var turns_attempted_this_step: int = 0
		var need_to_place_junction: bool = false
		var valid_position_was_found: bool = false
		# Tries to make a move until a valid one is found
		while not valid_position_was_found:
			# If all possible directions have been tried then you can't move on from this spot
			if turns_attempted_this_step == 4:
				return false
			
			# Causes the walker to change directions either if they are required too because they have been 
			#     walking in a straight line for too long or rolled a 50% 
			var turn_chance = rng.randf()
			if currently_heading_in_x_direction == last_direction or needs_to_change_directions:
				last_direction_count += 1
				# If they've moved in a straight line for too long or 50% turn chance
				if last_direction_count > straight_limit or needs_to_change_directions or turn_chance > 0.5:
					# If going left or right, choose to go up or down
					if currently_heading_in_x_direction == 3 or currently_heading_in_x_direction == 1:
						currently_heading_in_x_direction = [0, 2].pick_random()

					# If going up or down, choose to go left or right
					elif currently_heading_in_x_direction == 2 or currently_heading_in_x_direction == 0:
						currently_heading_in_x_direction = [1, 3].pick_random()
					changed_directions = true
					last_direction_count = 1
				elif turn_chance < 0.4 and last_direction_count >= 2:
					need_to_place_junction = true
				needs_to_change_directions = false
			else:
				last_direction = currently_heading_in_x_direction
				last_direction_count = 1
		
			var next_step_location: Vector2i = DIR_VECTORS[currently_heading_in_x_direction] + walker_current_location

			# If the place we are trying to step to is not a location that's already taken
			if not (next_step_location in room_storage):
				# If the current location does not contain the direction we are currently walking in, add it
				#    For instance, if we choose to walk up but the spawn room doesn't have up, it needs to be added to it
				if not room_storage[walker_current_location].required_directions.has(currently_heading_in_x_direction):
					room_storage[walker_current_location].add_direction(currently_heading_in_x_direction)
				
				# Chance to terminate early
				#    Can only terminate early iff it's not the main path
				var chance = rng.randf()
				if not is_main_path and chance < 0.02:
					return next_step_location
				
				# Random chance to spawn tiles other than straight aways and corners
				var room_chance = rng.randf()
				# Chance to spawn a room template
				#    Currently only 2x2
				if room_chance < 0.08 and not need_to_place_junction:
					if room_storage[walker_current_location].group_id != -1:
						continue
					# If the current position belongs to another room, don't spawn
					var can_place_room: bool = true
					for dir_ in [0, 1, 2, 3]:
						if not (next_step_location + DIR_VECTORS[dir_] in room_storage):
							continue
						if room_storage[next_step_location + DIR_VECTORS[dir_]].group_id != -1:
							can_place_room = false
							break
					if not can_place_room:
						room_storage[walker_current_location].required_directions.erase(currently_heading_in_x_direction)
						continue
					var new_temp: room_template = potential_rooms[0].duplicate()
					
					var valid_room_rotations: Array[room_template]
					
					# Tries all possible room rotations, centered around pivot point
					var found_valid_positioning: bool = false
					for i in range(4):
						var is_valid: bool = true
						if i != 0:
							new_temp.clock_wise_rotation()

						# Checks if the position is already taken
						for room_: dungeon_room in new_temp.sub_rooms.values():
							if (room_.room_pos + next_step_location) in room_storage:
								is_valid = false
								break
						# If the position isn't taken then append this template rotation 
						if is_valid:
							found_valid_positioning = true
							valid_room_rotations.append(new_temp.duplicate())
					
					# If a valid positioning was found, go ahead and try to place it
					if found_valid_positioning:
						var rand_rot: room_template = valid_room_rotations.pick_random()
						for room_: dungeon_room in rand_rot.sub_rooms.values():
							# If it is the pivot room, make sure that it has the required direction
							if room_.room_pos == Vector2i(0, 0):
								room_.add_direction(same_directions[currently_heading_in_x_direction])
							
							# Update the position (so like 0, 0 to 1, 1 or what not)
							room_.update_location(room_.room_pos + next_step_location)
							room_storage[room_.room_pos] = room_
							
							# Add a random direction to the exit room for the walker to continue out of
							if room_.required_directions.size() != room_.total_direction_count:
								var all_dir = [0, 1, 2, 3]
								for dir in room_.required_directions:
									all_dir.erase(dir)
								
								var valid_dirs = []
								for dir in all_dir:
									if not ((room_.room_pos + DIR_VECTORS[dir]) in room_storage):
										valid_dirs.append(dir)
								
								var rand_dir = 0
								if valid_dirs.size() > 0:
									rand_dir = valid_dirs.pick_random()
								else:
									rand_dir = all_dir.pick_random()
								
								walker_current_location = room_.room_pos
								room_.add_direction(rand_dir)
								currently_heading_in_x_direction = rand_dir
								
							valid_position_was_found = true
						break
					# If they were not able to find a spot that the 2x2 fit, then try to place something else
					else:
						continue
				else:
					var incoming_dir = same_directions[currently_heading_in_x_direction]
					var new_room = dungeon_room.new(next_step_location, [incoming_dir], 1, "Generic_Path")
					
					# Check that the location is not intruding on any unfinished junctions
					var should_turn: bool = false
					for dir_ in [0, 1, 2, 3]:
						if (next_step_location + DIR_VECTORS[dir_]) in room_storage:
							if room_storage[next_step_location + DIR_VECTORS[dir_]].required_directions.size() != room_storage[next_step_location + DIR_VECTORS[dir_]].total_direction_count:
								room_storage[next_step_location + DIR_VECTORS[dir_]].required_directions.erase(currently_heading_in_x_direction)
								should_turn = true
								break
					if should_turn:
						need_to_place_junction = false
						turns_attempted_this_step += 1
						needs_to_change_directions = true
						continue
					
					# Randomly select a junction to place down
					var available_directions: int = 1
					var should_place_junction: bool = false
					if need_to_place_junction:
						var chance_j = rng.randf()
						if chance_j <= 0.5:
							new_room.total_direction_count = 3
						elif chance_j > 0.5:
							new_room.total_direction_count = 4
						need_to_place_junction = false
						should_place_junction = true
					else:
						if room_chance < 0.2:
							should_place_junction = true
							new_room.total_direction_count = 3
						elif room_chance < 0.3 :
							should_place_junction = true
							new_room.total_direction_count = 4
						else:
							new_room.total_direction_count = 2
					
					# If the chance placing a junction was met, try to place the junction
					if should_place_junction:
						var is_too_close_to_junction: bool = false
						
						# Check all adjacent positions of the junction, if it's next to another junction or a room, don't place
						for check_dir in DIR_VECTORS.values():
							var neighbor_pos = next_step_location + check_dir
							if room_storage.has(neighbor_pos):
								if room_storage[neighbor_pos].total_direction_count > 2:
									is_too_close_to_junction = true
									break
									
						if is_too_close_to_junction:
							new_room.total_direction_count = 2
							should_place_junction = false
					
					# Verify that you can indeed place the junction
					if should_place_junction:
						# Remove the connecting direction and 
						var dir = [0, 1, 2, 3]
						dir.erase(same_directions[currently_heading_in_x_direction])
						for dir_ in dir:
							if not room_storage.has(next_step_location + DIR_VECTORS[dir_]):
								available_directions += 1
						if available_directions == 0:
							return next_step_location
						if available_directions < (new_room.total_direction_count):
							new_room.total_direction_count = 2
							should_place_junction = false

					room_storage[next_step_location] = new_room
					valid_position_was_found = true
		
				walker_current_location = next_step_location
			else:
				# If this isn't the main walker, check to see if it should create a loop
				if not is_main_path and false:
					var loop_chance = rng.randf()
					
					if loop_chance < 0.5:
						if not room_storage[walker_current_location].required_directions.has(currently_heading_in_x_direction):
							room_storage[walker_current_location].add_direction(currently_heading_in_x_direction)
							
						var incoming_dir = same_directions[currently_heading_in_x_direction]
						if not room_storage[next_step_location].required_directions.has(incoming_dir):
							room_storage[next_step_location].add_direction(incoming_dir)
					current_steps = step_limit
					return true
				
				needs_to_change_directions = true
				turns_attempted_this_step += 1
		current_steps += 1
		if room_storage[walker_current_location].group_id != -1 and current_steps == step_limit:
			current_steps -= 1
	return walker_current_location
