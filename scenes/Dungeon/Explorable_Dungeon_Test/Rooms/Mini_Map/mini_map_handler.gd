extends Control

@onready var grid_container = $Panel/GridContainer
@onready var rect = $Panel/ColorRect

var p_ref: explorable_dungeon

var tile_ = "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/MiniMapNode.tscn"

var room_start = "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room Start.png"
var stairs_down = "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Stairs Down.png"

var room_symbol_mapping: Dictionary = {
	"S": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room_Cap.png",
	"E": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room_Cap.png",
	"R": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room_Cap.png",
	"C": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Corner_Junction.png",
	"3": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/3-way_Junction.png",
	"4": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/4-way_Junction.png",
	"2": "2x2_Room",            

	# --- Hallways & Corridors ---
	"H": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Straight_Room.png",      
	"h": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room_Cap.png",        
	"-": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Straight_Room.png",
	"|": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Straight_Room.png",  
	"c": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Corner_Junction.png",      
	"t": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/3-way_Junction.png", 
	"+": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/4-way_Junction.png", 

	"0": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Empty_Room.png"      
}

var room_symbol_mapping_2: Dictionary = {
	"S": "Spawn_Room",
	"E": "Stair_Room",
	"R": "Room_Cap",
	"C": "Corner_Junction",
	"3": "3-Way_Junction",
	"4": "4-Way_Junction",
	"2": "2x2_Room",            

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
@export_enum("Spawn_Room", "Stair_Room", "Room_Cap", "Corner_Junction", "3-Way_Junction", "4-Way_Junction", "Straight_Room") var room_classification

var room_lookup: Dictionary = {
	0: "S",
	1: "E",
	2: "R",
	3: "C",
	4: "3", 
	5: "4",
	6: "-"
}

var spawn_index = 0

var offset_ = 20

var grid_offset

var x_scale_factor
var y_scale_factor

var pointer_offset = 0

@onready var previous_color_rot = rect.rotation_degrees

var found_offset = false

func _physics_process(delta):
	if not has_setup_run:
		return
	
	rect.rotation_degrees = -1 * (p_ref.player.camera_pivot.rotation_degrees.y + pointer_offset)

	if has_entered_start_room and p_ref.player.is_moving:
		var player_offset = Vector2(0, 0)
		if p_ref.player_start_position.x >= p_ref.player.position.x:
			player_offset.x = float(p_ref.player_start_position.x) - p_ref.player.position.x
		else:
			player_offset.x = float(p_ref.player.position.x) - p_ref.player_start_position.x
			
		if p_ref.player_start_position.y >= p_ref.player.position.z:
			player_offset.y = float(p_ref.player_start_position.y) - p_ref.player.position.z
		else:
			player_offset.y = float(p_ref.player.position.z) - p_ref.player_start_position.y

		var x_scale_factor_lower = (2 * offset_ + (float(offset_) / 2))
		var x_scale_factor_upper = (p_ref.max_grid_size.x * offset_) - x_scale_factor_lower

		grid_container.position.x = -1 * (p_ref.player.position.x - (2 * p_ref.tile_size)) * x_scale_factor
		grid_container.position.y = -1 * (p_ref.player.position.z - (2 * p_ref.tile_size)) * y_scale_factor

# 460, -20
# 39.484 0.755 0.014

func clear_mini_map():
	for child in grid_container.get_children():
		var child_to_remove = child
		#grid_container.remove_child.call_deferred(child)
		child_to_remove.queue_free()

func get_minimap_index(grid_x: int, grid_y: int) -> int:
	var max_y = p_ref.max_grid_size.y
	
	var child_index = (grid_y * p_ref.max_grid_size.x) + grid_x
	
	return child_index

var has_setup_run = false
func _setup(parent_reference: explorable_dungeon, bounding_box_arr, generated_rooms, spawn_coords):
	p_ref = parent_reference
	
	grid_container.columns = p_ref.max_grid_size.x
	
	var room_lookup = {}
	for room_ in generated_rooms:
		room_lookup[Vector2i(room_.room_x_coord, room_.room_y_coord)] = room_
	
	for y in range(p_ref.max_grid_size.y):
		for x in range(p_ref.max_grid_size.x):
			
			var cell_string = str(bounding_box_arr[x][y])
			
			var new_map_node = load(tile_)
			var new_map_node_instance: Control = new_map_node.instantiate()
			
			grid_container.add_child(new_map_node_instance)
	has_setup_run = true
	_new_room_entered(spawn_coords)

const ASSET_OFFSETS = {
	"Spawn_Room": 0.0,
	"Stair_Room": 0.0,
	"Room_Cap": 0.0,              # Adjust if Room_Cap is modeled incorrectly [1]
	"Corner_Junction": 180.0,       # Adjust if Corner is modeled incorrectly [1]
	"Hallway_Corner": 0.0,
	"Horizontal_Corridor": 0.0,   # Adjust if straight corridor is modeled incorrectly [1]
	"Vertical_Corridor": 0.0,
	"3-Way_Junction": -270.0,        # Adjust if T-Junction is modeled incorrectly [1]
	"Hallway_3-Way_Junction": 0.0,
	"Straight_Room": 0.0
}

func get_rotation_degrees_(room_type: String, previous_rotation) -> float:
	
	var calculated_rot = 0.0 
	if room_type in ["Room_Cap", "Spawn_Room", "Stair_Room"]:
		match previous_rotation:
			180.0: calculated_rot = 0.0   # Facing Up 
			90.0: calculated_rot = 90.0  # Facing Down 
			360.0: calculated_rot = 180.0 # Facing Left 
			270.0: calculated_rot = -90.0  # Facing Right 

	elif room_type in ["Corner_Junction", "Hallway_Corner"]:
		match previous_rotation:
			90.0: calculated_rot = 90.0   # Connects Left & Up
			0.0: calculated_rot = -180.0  # Connects Left & Down
			270.0: calculated_rot = -90.0 # Connects Right & Down
			180.0: calculated_rot = 0.0  # Connects Right & Up

	elif room_type in ["Horizontal_Corridor", "Vertical_Corridor", "Straight_Room"]:
		match previous_rotation:
			180.0 : calculated_rot = 90.0   # Vertical
			90.0 : calculated_rot = 0.0  # Horizontal

	elif room_type in ["3-Way_Junction", "Hallway_3-Way_Junction"]:
		match previous_rotation:
			180.0 : calculated_rot = 0.0   # Solid wall is Right (South)
			90.0: calculated_rot = 90.0  # Solid wall is Left (West)
			360.0: calculated_rot = 180.0 # Solid wall is Up (North)
			270.0: calculated_rot = 270.0  # Solid wall is Down (East)
	
	# Return the calculated rotation combined with the asset offset [1]
	return calculated_rot
var has_entered_start_room = false

var x_scale_factor_lower = 0
var x_scale_factor_upper = 0

var y_scale_factor_lower = 0
var y_scale_factor_upper = 0

func center_around_spawn(spawn_coords):
	if spawn_coords.x < 3.0:
		grid_container.position = Vector2(clamp((2 - spawn_coords.x), -2, p_ref.max_grid_size.x) * -1 *offset_, clamp((spawn_coords.y - 2 if spawn_coords.y < 3 else spawn_coords.y - 2), -2, p_ref.max_grid_size.y) * offset_) * Vector2(-1, -1)
	else:
		grid_container.position = Vector2(clamp((spawn_coords.x - 2), -2, p_ref.max_grid_size.x) * offset_, clamp((spawn_coords.y - 2 if spawn_coords.y < 3 else spawn_coords.y - 2), -2, p_ref.max_grid_size.y) * offset_) * Vector2(-1, -1)
	grid_offset = Vector2(grid_container.position.x, grid_container.position.y)
	#Starts centered at 3
	var x_scale_factor_lower = ((2 * offset_) + (float(offset_) / 2))
	var x_scale_factor_upper = (p_ref.max_grid_size.x * offset_) - x_scale_factor_lower
	
	var y_scale_factor_lower = ((2 * offset_) + (float(offset_) / 2))
	var y_scale_factor_upper = (p_ref.max_grid_size.y * offset_) - y_scale_factor_lower
		
	var main_grid_x_range = p_ref.max_grid_size.x * p_ref.tile_size
	var main_grid_y_range = p_ref.max_grid_size.y * p_ref.tile_size
	
	x_scale_factor = float((abs(x_scale_factor_lower) + x_scale_factor_upper)) / main_grid_x_range
	y_scale_factor = float((abs(y_scale_factor_lower) + y_scale_factor_upper)) / main_grid_y_range

	
func _new_room_entered(coords):
	if has_setup_run:
		if coords.x >= p_ref.max_grid_size.x or coords.y >= p_ref.max_grid_size.y:
			return
		var index = p_ref.pos_to_index(coords)

		var current_room = p_ref.get_room_node_at(coords)
		
		if current_room == null:
			return
		
		match current_room.room_classification:
			0:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["S"]), load(room_start))
				spawn_index = index
				center_around_spawn(coords)
				has_entered_start_room = true
				pointer_offset = get_rotation_degrees_(room_symbol_mapping_2[room_lookup[current_room.room_classification]], current_room.rotation_degrees.y)
				if pointer_offset == 180.0:
					pointer_offset = 0.0
				elif pointer_offset == 0.0:
					pointer_offset = 180.0
			1:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["S"]), load(stairs_down))
			2:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["R"]))

			3:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["C"]))
			4:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["3"]))

			5:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["4"]))
			6:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["-"]))
				
		grid_container.get_child(index).main_room_texture.rotation_degrees = get_rotation_degrees_(room_symbol_mapping_2[room_lookup[current_room.room_classification]], current_room.rotation_degrees.y)
