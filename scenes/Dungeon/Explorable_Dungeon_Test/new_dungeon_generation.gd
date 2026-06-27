extends Node3D

class_name dungeon_generation

var storage

class dungeon_room:
	var room_pos: Vector2i
	var required_directions: Array[int]
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
		required_directions = []
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
			
		if group_id == -2 and required_directions.size() == total_direction_count:
			return false
			
		if required_directions.size() >= total_direction_count and group_id != -2:
			if total_direction_count < 4:
				total_direction_count += 1 
			else:
				return false 
		
				
		required_directions.push_front(new_direction)
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
				0: return 0.0   # Facing Up (North)
				3: return -90.0    # Facing Right (East)
				2: return 180.0     # Facing Down (South)
				1: return 90.0   # Facing Left (West)  #asdf

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

		var new_sub_rooms: Dictionary[Vector2i, dungeon_room] = {}
		for room_: dungeon_room in sub_rooms.values():
			new_sub_rooms[room_.room_pos] = room_

		sub_rooms = new_sub_rooms
		cur_rotation += 1


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

const FULL_COMPASS_DIR_VECTORS = {
	0: Vector2i(0, -1), # Up    (North) - Y decreases going up
	1: Vector2i(-1, 0), # Left  (West)
	2: Vector2i(0, 1),  # Down  (South) - Y increases going down  
	3: Vector2i(1, 0),  # Right (East)
	4: Vector2i(1, 1),
	5: Vector2i(-1, 1),
	6: Vector2i(-1, -1),
	7: Vector2i(1, -1),
}

var same_directions: Dictionary = {
	0: 2,
	1: 3,
	2: 0, 
	3: 1
}

func _ready():
	print("HELLO")
	build_dungeon()

func build_dungeon():
	build_room_templates()

	var room_storage: Dictionary[Vector2i, dungeon_room]

	var valid_room_layout_generated: bool = false
	while not valid_room_layout_generated:
		if await build_rooms(room_storage):
			valid_room_layout_generated = true
		else:
			room_storage.clear()
	
	storage = room_storage

func build_room_templates():
	# TEMPLATE 1: 2x2 with 2 corners and 2 3-ways
	var bottom_left_1 = dungeon_room.new(Vector2i(0, 0), [2, 3], 3, "3_way_junction", 1)
	var bottom_right_1 = dungeon_room.new(Vector2i(1, 0), [1, 2], 2, "Corner_Junction", 1)
	var top_left_1 = dungeon_room.new(Vector2i(0, 1), [0, 3], 2, "Corner_Junction", 1)
	var top_right_1 = dungeon_room.new(Vector2i(1, 1), [0, 1], 3, "3_way_junction", 1)
	
	potential_rooms.append(room_template.new([bottom_left_1, bottom_right_1, top_left_1, top_right_1], Vector2i(2,2)))
	
	# TEMPLATE 2: 2x2 with 3 corners and 1 3-way
	var top_left_2 = dungeon_room.new(Vector2i(0, 0), [3, 0], 2, "Corner_Junction", 2)
	var top_right_2 = dungeon_room.new(Vector2i(1, 0), [1, 0], 2, "Corner_Junction", 2)
	var bottom_left_2 = dungeon_room.new(Vector2i(0, 1), [3, 2], 2, "Corner_Junction", 2)
	var bottom_right_2 = dungeon_room.new(Vector2i(1, 1), [1, 2], 3, "3_way_junction", 2)
	
	room_cap_templates.append(room_template.new([top_left_2, top_right_2, bottom_left_2, bottom_right_2], Vector2i(2,2)))

	# Directions
	# 0:  DOWN
	# 1:  LEFT
	# 2:  UP
	# 3:  RIGHT

	# TEMPLATE 3: 3x3 
	var bottom_left_3 = dungeon_room.new(Vector2i(-1, 0), [2, 3], 2, "Corner_Junction", 3)
	var bottom_center_3 = dungeon_room.new(Vector2i(0, 0), [1, 2, 3], 4, "4_way_junction", 3)
	var bottom_right_3 = dungeon_room.new(Vector2i(1, 0), [1, 2], 2, "Corner_Junction", 3)
	
	var middle_left_3 = dungeon_room.new(Vector2i(-1, 1), [0, 2, 3], 4, "4_way_junction", 3)
	var middle_center_3 = dungeon_room.new(Vector2i(0, 1), [0, 1, 2, 3], 4, "4_way_junction", 3)
	var middle_right_3 = dungeon_room.new(Vector2i(1, 1), [0, 1, 2], 4, "4_way_junction", 3)
	
	var top_left_3 = dungeon_room.new(Vector2i(-1, 2), [0, 3], 2, "Corner_Junction", 3)
	var top_center_3 = dungeon_room.new(Vector2i(0, 2), [0, 1, 3], 4, "4_way_junction", 3)
	var top_right_3 = dungeon_room.new(Vector2i(1, 2), [0, 1], 2, "Corner_Junction", 3)
	
	potential_rooms.append(room_template.new([bottom_center_3, bottom_left_3, bottom_right_3, middle_left_3, middle_center_3, middle_right_3, top_left_3, top_center_3, top_right_3], Vector2i(3, 3)))

	# TEMPLATE 4: 2x2 with 4 way as pivot
	
	var bottom_left_4 = dungeon_room.new(Vector2i(0, 0), [2, 3], 4, "4_way_junction", 4)
	var bottom_right_4 = dungeon_room.new(Vector2i(1, 0), [1, 2], 3, "3_way_junction", 4)
	var top_left_4 = dungeon_room.new(Vector2i(0, 1), [0, 3], 2, "Corner_Junction", 4)
	var top_right_4 = dungeon_room.new(Vector2i(1, 1), [0, 1], 2, "Corner_Junction", 4)

	potential_rooms.append(room_template.new([bottom_left_4, bottom_right_4, top_left_4, top_right_4], Vector2i(2, 2)))
	
	# Template 5: 2x2 with 3 way as pivot

	var bottom_left_5 = dungeon_room.new(Vector2i(0, 0), [2, 3], 4, "4_way_junction", 5)
	var bottom_right_5 = dungeon_room.new(Vector2i(1, 0), [1, 2], 3, "3_way_junction", 5)
	var top_left_5 = dungeon_room.new(Vector2i(0, 1), [0, 3], 2, "Corner_Junction", 5)
	var top_right_5 = dungeon_room.new(Vector2i(1, 1), [0, 1], 2, "Corner_Junction", 5)

	potential_rooms.append(room_template.new([bottom_right_5, bottom_left_5, top_left_5, top_right_5], Vector2i(2, 2)))

var potential_rooms: Array[room_template]
var room_cap_templates: Array[room_template]

var walk_path: Array[Vector2i]

var current_three_way_count = 0
var current_four_way_count = 0
var current_room_count = 0

signal down_has_been_placed

func build_rooms(room_storage):
	print("BUILDING ROOMS")
	var rng = RandomNumberGenerator.new()
	randomize()
	rng.randomize()

	# Sets up spawn location
	var spawn_location: Vector2i = Vector2i(0, 0)

	var spawn_room = dungeon_room.new(spawn_location, [], 1, "Spawn_Room", -2)
	room_storage[spawn_location] = spawn_room
	var main_walker_lifetime: int = rng.randi_range(15, 40)
	var main_walker_setps: int = 0
	
	var walker_current_location: Vector2i = spawn_location
	
	var valid_critical_path_found: bool = false
	
	var template_chance = rng.randf_range(0.4, 0.16)
	var t_way_chance = rng.randf_range(template_chance, 0.25)
	var four_way_chance = rng.randf_range(t_way_chance, 0.3)
	
	var max_three_way_count = rng.randi_range(2, 5) * clamp(int(main_walker_lifetime / 15), 1, 3)

	var max_four_way_count = rng.randi_range(2, 4) * clamp(int(main_walker_lifetime / 20), 1, 3)

	var max_room_count = rng.randi_range(2, 4) * clamp(int(main_walker_lifetime / 20), 1, 2)
	
	var chances = [template_chance, t_way_chance, four_way_chance, max_three_way_count, max_four_way_count, max_room_count]
	

	
	# Iterates until all steps have found a valid position
	while not valid_critical_path_found:
		# walker_algorithm can return false, true, and current location
		var end_location = await walker_algorithm(main_walker_lifetime, walker_current_location, room_storage, true, chances)

		if end_location is bool and not end_location:
			continue

		if end_location == spawn_location:
			# Failed to build a critical path from spawn, reset and try again
			room_storage.clear()
			spawn_location = Vector2i(0, 0)
			spawn_room = dungeon_room.new(spawn_location, [], 1, "Spawn_Room", -2)
			room_storage[spawn_location] = spawn_room
			continue
		var placed_stairs_down: bool = false
		for dir in [0, 1, 2, 3]:
			var adjacent_pos = end_location + DIR_VECTORS[dir]
			if room_storage.has(adjacent_pos):
				var adjacent_room = room_storage[adjacent_pos]
				var door_to_stairs = same_directions[dir]
				
				# Simplify: Just check if the door is in the array!
				if door_to_stairs in adjacent_room.required_directions:
					room_storage[end_location] = dungeon_room.new(end_location, [door_to_stairs], 1, "Down", -2)
					placed_stairs_down = true
					break
					
		if placed_stairs_down:
			valid_critical_path_found = true
			#down_has_been_placed.emit()
		else:
			room_storage.clear()
			spawn_location = Vector2i(0, 0)
			spawn_room = dungeon_room.new(spawn_location, [], 1, "Spawn_Room")
			room_storage[spawn_location] = spawn_room
			continue
	#evaluate_room_names(room_storage)
	#return true
	var has_all_directions_been_satisfied: bool = false
	var num_of_other_walkers: Array[Vector2i] = []
	print("STARTED OTHER PATHS")
	#await down_has_been_placed

	while not has_all_directions_been_satisfied:
		# Check all current rooms to see if the amount of directions that have matches the number they should
		#    If it doesn't then they need a continuation
		num_of_other_walkers.clear()
		for room_: dungeon_room in room_storage.values():
			if room_.group_id == -2:
				continue
				
			if (room_.required_directions.size()) != room_.total_direction_count:
				num_of_other_walkers.append(room_.room_pos)
				
		if num_of_other_walkers.size() == 0:
			has_all_directions_been_satisfied = true
			continue
			
		var small_walker_allowed_steps = randi_range(2, 6)
		if current_four_way_count == max_four_way_count:
			small_walker_allowed_steps = 2
		elif current_three_way_count == max_three_way_count:
			small_walker_allowed_steps = 2
		elif max_room_count == current_room_count:
			small_walker_allowed_steps = 2
		for pos in num_of_other_walkers:
			if room_storage[pos].required_directions.size() == room_storage[pos].total_direction_count:
				continue
			
			var valid_path_found: bool = false
			
			var max_attempts: int = 10
			var attempts: int = 0
			while not valid_path_found:
				attempts += 1
				if attempts == max_attempts:
					room_storage[pos].total_direction_count = room_storage[pos].required_directions.size()
					valid_path_found = true
					print("MAX ATTEMPTED REACHED at ", pos)
					break
				
				
				var simulated_storage = duplicate_dungeon_dict(room_storage)
				
				# walker_algorithm can return false, true, and current location
				var end_location = walker_algorithm(small_walker_allowed_steps, pos, simulated_storage, false, chances)
				
				if end_location is bool:
					if end_location:
						valid_path_found = true
						room_storage.clear()
						room_storage.merge(simulated_storage)
					else:
						valid_path_found = false
					continue
				
				if end_location == pos:
					# Walker was trapped and didn't move
					valid_path_found = false
					continue
				elif simulated_storage.has(end_location) and simulated_storage[end_location].group_id != -1:
					valid_path_found = false
					continue

					
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
					simulated_storage[end_location] = dungeon_room.new(end_location, [correct_direction], 1, "T", -2)
				# Spawn basic treasure room
				elif chance < 0.3:
					simulated_storage[end_location] = dungeon_room.new(end_location, [correct_direction], 1, "T", -2)
				else:
					simulated_storage[end_location] = dungeon_room.new(end_location, [correct_direction], 1, "R")

				room_storage.clear()
				room_storage.merge(simulated_storage)
				valid_path_found = true
				#for room_pos in simulated_storage:
				#	room_storage[room_pos] = simulated_storage[room_pos].duplicate()
				
			if not valid_path_found:
				room_storage[pos].total_direction_count = room_storage[pos].required_directions.size()


	return true

func get_writeable_room(sim_storage: Dictionary, pos: Vector2, room_storage) -> dungeon_room:
	if room_storage.has(pos) and sim_storage[pos] == room_storage[pos]:
		sim_storage[pos] = room_storage[pos].duplicate()
	return sim_storage[pos]

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
			if room_.required_directions.size() != doors:
				continue
			var d1 = room_.required_directions[0]
			var d2 = room_.required_directions[1]
			
			if (d1 == 0 and d2 == 2) or (d1 == 2 and d2 == 0):
				room_.room_name_type = "|Room"
			elif (d1 == 1 and d2 == 3) or (d1 == 3 and d2 == 1):
				room_.room_name_type = "-Room"
			else:
				room_.room_name_type = "Corner_Junction"
				
		room_.update_asset_path()

func walker_algorithm(step_limit, start_location, room_storage, is_main_path, chances):
	var rng = RandomNumberGenerator.new()
	randomize()
	rng.randomize()
	
	#if is_main_path:
	#	print("TRYING TO PLACE ON MAIN PATH")
	#else:
	#	print("TRYING TO PLACE ON NON MAIN PATH")
	
	var template_chance = chances[0]
	var t_way_chance = chances[1]
	var four_way_chance = chances[2]
	
	var max_three_way_count = chances[3]
	var max_four_way_count = chances[4]
	var max_room_count = chances[5]
	
	if not is_main_path:
		max_four_way_count = 0
	
	var walker_current_location: Vector2i = start_location

	var steps_without_placing_junction: int = 0

	var current_steps: int = 0
	var currently_heading_in_x_direction: int = -1
	var tried_directions: Array[int] = []

	var just_placed_junction: bool = false

	var steps_without_turning: int = 0

	while current_steps <= step_limit:
		var valid_position_was_found: bool = false
		
		tried_directions.clear()
		
		while not valid_position_was_found:
			var dirs: Array[int] = [0, 1, 2, 3]
			
			#print()
			#print("DIRS BEFORE ERASING")
			#print(dirs)
			for pot_dir in room_storage[walker_current_location].required_directions:
				dirs.erase(pot_dir)
			
			#print()
			#print("DIRS AFTER ERASING REQUIRED")
			#print(dirs)
			#print()
			for dir in tried_directions:
				dirs.erase(dir)

			#for pos in DIR_VECTORS.values():
			#	if room_storage.has(walker_current_location + pos):
			#		dirs.erase(DIR_VECTORS.find_key(pos))

			#print()
			#print("DIRS AFTER ERASING SHIT")
			#print(dirs)
			
			if dirs.size() == 0:
				if is_main_path:
					return false
				if room_storage[walker_current_location].group_id != -1:
					return false
				return walker_current_location
			
			if just_placed_junction or walker_current_location == start_location or not dirs.has(currently_heading_in_x_direction):
				var chance_to_swap_directions: float = rng.randf()
				if chance_to_swap_directions > 0.5 and dirs.size() > 1:
					dirs.erase(currently_heading_in_x_direction)
				
				if dirs.size() == 0:
					steps_without_turning += 1
				else:
					var new_direction = dirs.pick_random()
					
					if new_direction == currently_heading_in_x_direction:
						steps_without_turning += 1
					else:
						steps_without_turning = 0 
					currently_heading_in_x_direction = new_direction
				just_placed_junction = false
			else:
				steps_without_turning += 1
				
			var need_to_place_junction: bool = false
			if steps_without_turning > 2 and dirs.size() > 1 and is_main_path:
				need_to_place_junction = true
				if steps_without_turning > 5:
					var new_direction = dirs.pick_random()
					while new_direction == currently_heading_in_x_direction:
						new_direction = dirs.pick_random()
						
					currently_heading_in_x_direction = new_direction
					tried_directions.append(currently_heading_in_x_direction)
					just_placed_junction = false
					steps_without_turning = 0
			elif steps_without_turning > 2 and dirs.size() > 1 and not is_main_path:
				var new_direction = dirs.pick_random()
				while new_direction == currently_heading_in_x_direction:
					new_direction = dirs.pick_random()
				currently_heading_in_x_direction = new_direction
				tried_directions.append(currently_heading_in_x_direction)
				just_placed_junction = false
				steps_without_turning = 0

			var next_step_location: Vector2i = DIR_VECTORS[currently_heading_in_x_direction] + walker_current_location

			if not (next_step_location in room_storage):
				if not room_storage[walker_current_location].required_directions.has(currently_heading_in_x_direction):
					room_storage[walker_current_location] = room_storage[walker_current_location].duplicate()
					room_storage[walker_current_location].add_direction(currently_heading_in_x_direction)

				var early_termination_change = rng.randf()
				if (not is_main_path and early_termination_change < 0.05 + (room_storage.size() * 0.001)) and room_storage[walker_current_location].group_id == -1:
					return next_step_location

				var room_chance = rng.randf()

				if room_chance < 0.1 and current_room_count <= max_room_count:
					if room_storage[walker_current_location].group_id == -1:
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
							tried_directions.append(currently_heading_in_x_direction)
							continue
						var new_temp: room_template = potential_rooms.pick_random().duplicate()
						
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
							steps_without_placing_junction += 1
							var potential_position: Array[Vector2i]
							for room_: dungeon_room in rand_rot.sub_rooms.values():
								# If it is the pivot room, make sure that it has the required direction
								var old_pos = room_.room_pos
								if room_.room_pos == Vector2i(0, 0):
									room_.add_direction(same_directions[currently_heading_in_x_direction])
									room_.update_location(room_.room_pos + next_step_location)
								else:
									room_.update_location(room_.room_pos + next_step_location)
									if room_.required_directions.size() != room_.total_direction_count:
										var unused_dirs = [0, 1, 2, 3]
										for dir__ in room_.required_directions:
											unused_dirs.erase(dir__)
											
										for dir_ in unused_dirs:
											if room_storage.has(room_.room_pos + DIR_VECTORS[dir_]):
												valid_position_was_found = false
												break
										if not valid_position_was_found:
											break
										potential_position.append(room_.room_pos)
								# Update the position (so like 0, 0 to 1, 1 or what not)
								#room_storage[room_.room_pos] = room_
	
								valid_position_was_found = true
								
							if valid_position_was_found:
								for room_: dungeon_room in rand_rot.sub_rooms.values():
									room_storage[room_.room_pos] = room_
								
								
								walker_current_location = potential_position.pick_random()
								current_room_count += 1
								if current_steps + 1 == step_limit:
									current_steps -= 1
							else:
								print("FAILED TO PLACE A ROOM AT ", next_step_location)
								var result = place_generic_path(
									next_step_location, 
									currently_heading_in_x_direction, 
									is_main_path, 
									need_to_place_junction, 
									room_chance, 
									steps_without_placing_junction, 
									room_storage, 
									rng,
									max_three_way_count, 
									max_four_way_count, 
									current_three_way_count, 
									current_four_way_count
								)
								
								if result["terminated"] == true:
									return result["location"]
									
								steps_without_placing_junction = result["steps_without_junction"]
								just_placed_junction = result["just_placed_junction"]
								current_three_way_count = result["current_3_way"]
								current_four_way_count = result["current_4_way"]
								
								valid_position_was_found = true
								walker_current_location = next_step_location
							
						# If they were not able to find a spot that the 2x2 fit, then try to place something else
						else:
							if not is_main_path:
								return walker_current_location
							
							var result = place_generic_path(
								next_step_location, 
								currently_heading_in_x_direction, 
								is_main_path, 
								need_to_place_junction, 
								room_chance, 
								steps_without_placing_junction, 
								room_storage, 
								rng,
								max_three_way_count, 
								max_four_way_count, 
								current_three_way_count, 
								current_four_way_count
							)
							
							if result["terminated"] == true:
								return result["location"]
								
							steps_without_placing_junction = result["steps_without_junction"]
							just_placed_junction = result["just_placed_junction"]
							current_three_way_count = result["current_3_way"]
							current_four_way_count = result["current_4_way"]
							
							valid_position_was_found = true
							walker_current_location = next_step_location
					else:
						var result = place_generic_path(
							next_step_location, 
							currently_heading_in_x_direction, 
							is_main_path, 
							need_to_place_junction, 
							room_chance, 
							steps_without_placing_junction, 
							room_storage, 
							rng,
							max_three_way_count, 
							max_four_way_count, 
							current_three_way_count, 
							current_four_way_count
						)
						
						if result["terminated"] == true:
							return result["location"]
							
						steps_without_placing_junction = result["steps_without_junction"]
						just_placed_junction = result["just_placed_junction"]
						current_three_way_count = result["current_3_way"]
						current_four_way_count = result["current_4_way"]
						
						valid_position_was_found = true
						walker_current_location = next_step_location
				else:
					var result = place_generic_path(
						next_step_location, 
						currently_heading_in_x_direction, 
						is_main_path, 
						need_to_place_junction, 
						room_chance, 
						steps_without_placing_junction, 
						room_storage, 
						rng,
						max_three_way_count, 
						max_four_way_count, 
						current_three_way_count, 
						current_four_way_count
					)
					
					if result["terminated"] == true:
						return result["location"]
						
					steps_without_placing_junction = result["steps_without_junction"]
					just_placed_junction = result["just_placed_junction"]
					current_three_way_count = result["current_3_way"]
					current_four_way_count = result["current_4_way"]
					
					valid_position_was_found = true
					walker_current_location = next_step_location
			else:
				tried_directions.append(currently_heading_in_x_direction)
				if not is_main_path:
					var loop_chance: float = rng.randf()
					if loop_chance > 0.5 and (room_storage[next_step_location].group_id == -1) and (room_storage[walker_current_location].group_id == -1):
						var success_1 = room_storage[next_step_location].add_direction(same_directions[currently_heading_in_x_direction])
						var success_2 = room_storage[walker_current_location].add_direction(currently_heading_in_x_direction)
						
						if success_1 and success_2:
							print("LOOPED AT ", walker_current_location, " room there is ", room_storage[walker_current_location].room_name_type)
							print("LOOKED WITH ", next_step_location, " room there is ", room_storage[next_step_location].room_name_type)
							return true
						else:
							return walker_current_location
					return walker_current_location
						
		current_steps += 1
		if current_steps == step_limit and room_storage[walker_current_location].group_id != -1:
			current_steps -= 1
	
	return walker_current_location

func place_generic_path(
	next_step_location: Vector2i, 
	heading_dir: int, 
	is_main_path: bool, 
	need_to_place_junction: bool, 
	room_chance: float, 
	steps_without_junction: int, 
	room_storage: Dictionary, 
	rng: RandomNumberGenerator,
	max_3_way: int, 
	max_4_way: int, 
	current_3_way: int, 
	current_4_way: int
) -> Dictionary:
	
	var incoming_dir = same_directions[heading_dir]
	var new_room = dungeon_room.new(next_step_location, [incoming_dir], 1, "Generic_Path")

	var available_directions: int = 1
	var should_place_junction: bool = false
	var just_placed_junction: bool = false
	
	var can_place_junction: bool = true
	if not is_main_path:
		if current_3_way >= max_3_way:
			can_place_junction = false
	
	if need_to_place_junction and is_main_path:
		var chance: float = rng.randf()
		if (chance < 0.5 and max_3_way >= current_3_way) or not is_main_path:
			should_place_junction = true
			new_room.total_direction_count = 3
		elif max_4_way >= current_4_way:
			should_place_junction = true
			new_room.total_direction_count = 4
	else:
		if need_to_place_junction and (((max_4_way >= current_4_way) and is_main_path) or (max_3_way >= current_3_way)):
			var chance: float = rng.randf()
			if (chance < 0.5 and max_3_way >= current_3_way) or not is_main_path:
				should_place_junction = true
				new_room.total_direction_count = 3
			elif max_4_way >= current_4_way:
				should_place_junction = true
				new_room.total_direction_count = 4
		else:
			if room_chance < (0.25 + steps_without_junction * 0.15) and can_place_junction and (max_3_way >= current_3_way):
				should_place_junction = true
				new_room.total_direction_count = 3
			elif room_chance < (0.3 + steps_without_junction * 0.15) and can_place_junction and (max_4_way >= current_4_way) and is_main_path: 
				should_place_junction = true
				new_room.total_direction_count = 4
			else:
				should_place_junction = false
				new_room.total_direction_count = 2
				steps_without_junction += 1

	if should_place_junction:
		var is_too_close_to_junction: bool = false
		for check_dir in DIR_VECTORS.values():
			if room_storage.has(next_step_location + check_dir) and room_storage[next_step_location + check_dir].total_direction_count > 2:
				is_too_close_to_junction = true
				break
		if is_too_close_to_junction:
			new_room.total_direction_count = 2
			should_place_junction = false

	if should_place_junction:
		var dir = [0, 1, 2, 3]
		dir.erase(incoming_dir)
		for dir_ in dir:
			var neighbor_pos = next_step_location + DIR_VECTORS[dir_]
			if not room_storage.has(neighbor_pos):
				available_directions += 1
			else:
				if room_storage[neighbor_pos].required_directions.has(same_directions[dir_]):
					available_directions += 1

		# Safety Exit Trigger
		if available_directions == 0:
			return {"terminated": true, "location": next_step_location}
			
		if available_directions < new_room.total_direction_count:
			new_room.total_direction_count = 2
			should_place_junction = false
			
		steps_without_junction = 0
		just_placed_junction = true
	
	if new_room.total_direction_count == 3:
		current_3_way += 1
	elif new_room.total_direction_count == 4:
		current_4_way += 1
	
	room_storage[next_step_location] = new_room
	
	# Package the updated state variables and return them
	return {
		"terminated": false,
		"steps_without_junction": steps_without_junction,
		"just_placed_junction": just_placed_junction,
		"current_3_way": current_3_way,
		"current_4_way": current_4_way
	}
