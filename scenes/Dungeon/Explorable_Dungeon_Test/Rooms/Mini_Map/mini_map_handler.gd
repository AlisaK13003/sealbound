extends Control

@onready var grid_container = $MiniMap/Panel/GridContainer
@onready var rect = $MiniMap/Panel/ColorRect
@onready var f_rect = $Full_Screen_Map/Panel/Container/ColorRect
@onready var enemy_dots = $MiniMap/Panel/Enemy_Locators
@onready var f_dots = $Full_Screen_Map/Panel/Container/Enemy_Locators
@onready var full_screen_fots = $Full_Screen_Map/Panel/Container/Enemy_Locators
@onready var full_screen_map = $Full_Screen_Map/Panel/GridContainer
@onready var actual_full_screen_map = $Full_Screen_Map

@onready var mov_cont = $Full_Screen_Map/Panel/Container

@onready var f_grid = $Full_Screen_Map/Panel/GridContainer

@onready var mini_map = $MiniMap
@onready var map_button = $Map_Button

var p_ref: explorable_dungeon

var tile_ = "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/MiniMapNode.tscn"

var room_start = "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room Start.png"
var stairs_down = "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Stairs Down.png"
var chest_room = "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Treasure_Room_Overlay.png"

var room_symbol_mapping: Dictionary = {
	"S": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room_Cap.png",
	"E": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room_Cap.png",
	"R": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room_Cap.png",
	"C": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Corner_Junction.png",
	"3": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/3-way_Junction.png",
	"4": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/4-way_Junction.png",
	"2": "2x2_Room",
	"T": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room_Cap.png",   
	"Q": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Mini_Map/Room_Cap.png",

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
	"D": "Stair_Room",
	"E": "Stair_Room",
	"R": "Room_Cap",
	"C": "Corner_Junction",
	"3": "3-Way_Junction",
	"4": "4-Way_Junction",
	"2": "2x2_Room",     
	"T": "T_Chest_Room",    
	"Q": "Quest_Room",   

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
@export_enum("Spawn_Room", "Stair_Room", "Room_Cap", "Corner_Junction", "3-Way_Junction", "4-Way_Junction", "Straight_Room", "T_Chest_Room", "Quest_Room") var room_classification

var room_lookup: Dictionary = {
	0: "S",
	1: "E",
	2: "R",
	3: "C",
	4: "3", 
	5: "4",
	6: "-",
	7: "T",
	8: "Q"
}

@onready var original_panel_position = $Full_Screen_Map/Panel.position

var spawn_index = 0

var offset_ = 20

var grid_offset

var x_scale_factor
var y_scale_factor

var pointer_offset = 0

var enemy_dot = "res://assets/tile sheets/Enemy_locator.png"

@onready var previous_color_rot = rect.rotation_degrees

var found_offset = false

var enemy_list: Array

func _ready():
	map_button.activated.connect(open_map)

func hide_mini_map():
	$MiniMap.visible = false

func open_mini_map():
	$MiniMap.visible = true

func store_current_enemy_list(e_list):
	enemy_list.clear()
	for dot in f_dots.get_children():
		dot.queue_free()
	for dot in enemy_dots.get_children():
		dot.queue_free()
	
	enemy_list = e_list.duplicate()
	
	for enemy in enemy_list:
		var new_dot = Sprite2D.new()
		new_dot.texture = load(enemy_dot)
		new_dot.scale = Vector2(0.25, 0.25)
		enemy_dots.add_child(new_dot)
		
		var new_dot_2 = Sprite2D.new()
		new_dot_2.texture = load(enemy_dot)
		new_dot_2.scale = Vector2(0.25, 0.25)
		full_screen_fots.add_child(new_dot_2)

@onready var full_panel = $Full_Screen_Map/Panel
@onready var off = f_grid.scale.x * 40
var max_zoom_in = 2.0
var max_zoom_out = 0.5
func _process(delta):
	var boundary = f_grid.size * f_grid.scale
	var bounds = full_panel.size - boundary
	
	if not mini_map.visible and has_setup_run and not p_ref.in_combat:
		if Global.get_continuous_input_mapping("up"):
			f_grid.position.y = clamp(f_grid.position.y - 1, -off * 3 + bounds.y if bounds.y <= 0 else 0 , off * 3 if bounds.y <= 0 else bounds.y)
			mov_cont.position.y = clamp(mov_cont.position.y - 1, -off * 3 + bounds.y if bounds.y <= 0 else 0 , off * 3 if bounds.y <= 0 else bounds.y)

		if Global.get_continuous_input_mapping("down"):
			f_grid.position.y = clamp(f_grid.position.y + 1, -off * 3 + bounds.y if bounds.y <= 0 else 0, off * 3 if bounds.y <= 0 else bounds.y)
			mov_cont.position.y = clamp(mov_cont.position.y + 1, -off * 3 + bounds.y if bounds.y <= 0 else 0, off * 3 if bounds.y <= 0 else bounds.y)

		if Global.get_continuous_input_mapping("left"):
			f_grid.position.x = clamp(f_grid.position.x - 1, -off * 3 + bounds.x if bounds.x <= 0 else 0, off * 3 if bounds.x <= 0 else bounds.x)
			mov_cont.position.x = clamp(mov_cont.position.x - 1, -off * 3 + bounds.x if bounds.x <= 0 else 0, off * 3 if bounds.x <= 0 else bounds.x)

		if Global.get_continuous_input_mapping("right"):
			f_grid.position.x = clamp(f_grid.position.x + 1, -off * 3 + bounds.x if bounds.x <= 0 else 0, off * 3 if bounds.x <= 0 else bounds.x)
			mov_cont.position.x = clamp(mov_cont.position.x + 1, -off * 3 + bounds.x if bounds.x <= 0 else 0, off * 3 if bounds.x <= 0 else bounds.x)
		
		return
		if Global.get_input_mapping("Camera_Zoom_In"):
			if $Full_Screen_Map/Panel.scale == (Vector2(1, 1)):
				$Full_Screen_Map/Panel.scale = Vector2(1, 1) * max_zoom_in
				$Full_Screen_Map/Panel.size /= max_zoom_in
			elif $Full_Screen_Map/Panel.scale == (Vector2(1, 1) * max_zoom_out):
				$Full_Screen_Map/Panel.scale = Vector2(1, 1)
				$Full_Screen_Map/Panel.size = Vector2(500, 250)
			$Full_Screen_Map/Panel.position = original_panel_position
		if Global.get_input_mapping("Camera_Zoom_Out"):
			if $Full_Screen_Map/Panel.scale == (Vector2(1, 1) * max_zoom_in):
				$Full_Screen_Map/Panel.scale = Vector2(1, 1)
				$Full_Screen_Map/Panel.size = Vector2(500, 250)
			elif $Full_Screen_Map/Panel.scale == (Vector2(1, 1)):
				$Full_Screen_Map/Panel.scale = Vector2(1, 1) * max_zoom_out
				$Full_Screen_Map/Panel.size *= 1.0 / max_zoom_out
			$Full_Screen_Map/Panel.position = original_panel_position
		f_grid.size = Vector2(grid_size_x, grid_size_y) * 40
		
func _physics_process(delta):
	if not has_setup_run:
		return
	if p_ref.in_combat:
		return

	rect.rotation_degrees = -1 * (p_ref.player.camera_pivot.rotation_degrees.y + pointer_offset)
	f_rect.rotation_degrees = -1 * (p_ref.player.camera_pivot.rotation_degrees.y + pointer_offset)
	for enemy in range(enemy_list.size()):
		var current_enemy: Sprite2D = enemy_dots.get_child(enemy)
		var current_enemy_2: Sprite2D = full_screen_fots.get_child(enemy)
		
		if grid_container.get_child(get_minimap_index(enemy_list[enemy].current_grid_pos.x, enemy_list[enemy].current_grid_pos.y)).main_room_texture.texture == null:
			current_enemy.visible = false
			current_enemy_2.visible = false
		else:
			current_enemy.visible = true
			current_enemy_2.visible = true
		
		current_enemy.position.x = (enemy_list[enemy].position.x * x_scale_factor) - (p_ref.player.position.x * x_scale_factor)
		current_enemy.position.y = (enemy_list[enemy].position.z * y_scale_factor) - (p_ref.player.position.z * y_scale_factor)

		var shifted_enemy_x = enemy_list[enemy].position.x - (min_grid_x * p_ref.tile_size)
		var shifted_enemy_z = enemy_list[enemy].position.z - (min_grid_y * p_ref.tile_size)

		current_enemy_2.position.x = (float($Full_Screen_Map/Panel.size.x) / (float(grid_size_x) * float(p_ref.tile_size))) * (float(shifted_enemy_x)) / ((float($Full_Screen_Map/Panel.size.x) * float(1.0 / float($Full_Screen_Map/Panel/GridContainer.scale.x))) / float($Full_Screen_Map/Panel/GridContainer.size.x))
		current_enemy_2.position.y = (float($Full_Screen_Map/Panel.size.y) / (float(grid_size_y) * float(p_ref.tile_size))) * (float(shifted_enemy_z)) / ((float($Full_Screen_Map/Panel.size.y) * float(1.0 / float($Full_Screen_Map/Panel/GridContainer.scale.y))) / float($Full_Screen_Map/Panel/GridContainer.size.y))
		current_enemy_2.position.x += f_grid.scale.x * 20
		current_enemy_2.position.y += f_grid.scale.y * 20

	if has_entered_start_room and p_ref.player.is_moving:
		grid_container.position.x = ((2 * p_ref.tile_size - p_ref.player.position.x) * x_scale_factor) + (min_grid_x * offset_)
		grid_container.position.y = ((2 * p_ref.tile_size - p_ref.player.position.z) * y_scale_factor) + (min_grid_y * offset_)
		
		$Full_Screen_Map/Panel/GridContainer.position.x = -1 * (p_ref.player.position.x - (2 * p_ref.tile_size)) * x_scale_factor
		f_grid.position.y = -1 * (p_ref.player.position.z - (2 * p_ref.tile_size)) * y_scale_factor
		
		var shifted_player_x = p_ref.player.position.x - (min_grid_x * p_ref.tile_size)
		var shifted_player_z = p_ref.player.position.z - (min_grid_y * p_ref.tile_size)
		
		f_rect.position.x = (float($Full_Screen_Map/Panel.size.x) / (float(grid_size_x) * float(p_ref.tile_size))) * (float(shifted_player_x)) / ((float($Full_Screen_Map/Panel.size.x) * float(1.0 / float($Full_Screen_Map/Panel/GridContainer.scale.x))) / float($Full_Screen_Map/Panel/GridContainer.size.x))
		f_rect.position.y = (float($Full_Screen_Map/Panel.size.y) / (float(grid_size_y) * float(p_ref.tile_size))) * (float(shifted_player_z)) / ((float($Full_Screen_Map/Panel.size.y) * float(1.0 / float($Full_Screen_Map/Panel/GridContainer.scale.y))) / float($Full_Screen_Map/Panel/GridContainer.size.y))
		
		f_rect.position.x += f_grid.scale.x * 20
		f_rect.position.y += f_grid.scale.y * 20
		
# 460, -20
# 39.484 0.755 0.014

func clear_mini_map():
	for child in grid_container.get_children():
		var child_to_remove = child
		#grid_container.remove_child.call_deferred(child)
		child_to_remove.queue_free()
	enemy_list.clear()
	for enemy in enemy_dots.get_children():
		enemy.queue_free()
	
	for dot in f_dots.get_children():
		dot.queue_free()
	for child in full_screen_map.get_children():
		child.queue_free()
	

var open = false

func open_map():
	mov_cont.position = Vector2(0, 0)
	full_screen_map.position = Vector2(0, 0)
	if not open:
		mini_map.visible = false
		actual_full_screen_map.visible = true
		open = true
		p_ref.movement_locked = true
	else:
		mini_map.visible = true
		actual_full_screen_map.visible = false
		open = false
		p_ref.movement_locked = false

func get_minimap_index(grid_x: int, grid_y: int) -> int:
	var shifted_x = grid_x - min_grid_x
	var shifted_y = grid_y - min_grid_y
	
	return (shifted_y * grid_size_x) + shifted_x

var has_setup_run = false
var grid_size_x: int
var grid_size_y: int
var min_grid_x: int = 0
var min_grid_y: int = 0

func _setup(parent_reference: explorable_dungeon, generated_rooms):
	p_ref = parent_reference
	
	if generated_rooms.is_empty():
		return
		
	var max_x_key: int = 0
	var max_y_key: int = 0
	
	var first = true
	for key: Vector2i in generated_rooms.keys():
		if first:
			min_grid_x = key.x
			max_x_key = key.x
			min_grid_y = key.y
			max_y_key = key.y
			first = false
		else:
			if key.x < min_grid_x: min_grid_x = key.x
			elif key.x > max_x_key: max_x_key = key.x
			
			if key.y < min_grid_y: min_grid_y = key.y
			elif key.y > max_y_key: max_y_key = key.y
	
	print("INSIDE MINI MAP")
	
	grid_size_x = max_x_key - min_grid_x + 1
	grid_size_y = max_y_key - min_grid_y + 1

	print("Grid Size: ", grid_size_x, "x", grid_size_y)
	
	grid_container.columns = grid_size_x 
	full_screen_map.columns = grid_size_x
	
	f_grid.size = (40 * f_grid.scale) * Vector2(grid_size_x, grid_size_y) 
	mov_cont.size = f_grid.size
	
	for y in range(grid_size_y):
		for x in range(grid_size_x):
			var new_map_node = load(tile_)
			var new_map_node_instance: Control = new_map_node.instantiate()
			
			var new_map_node_2 = load(tile_)
			var new_map_node_instance_2: Control = new_map_node_2.instantiate()
			
			full_screen_map.add_child(new_map_node_instance_2)
			grid_container.add_child(new_map_node_instance)
			
	has_setup_run = true
	_new_room_entered(Vector2(0, 0)) 

const ASSET_OFFSETS = {
	"Spawn_Room": 180.0,
	"Stair_Room": 0.0,
	"Room_Cap": 180.0,             
	"Corner_Junction": 0.0,    
	"Hallway_Corner": 0.0,
	"Horizontal_Corridor": 0.0,  
	"Vertical_Corridor": 0.0,
	"3-Way_Junction": 180.0,       
	"Hallway_3-Way_Junction": 0.0,
	"4-Way_Junction": 0.0,
	"Straight_Room": 0.0,
	"T_Chest_Room": 0.0,
	"Quest_Room": 0.0,
}

const DIR_VECTORS = {
	0: Vector2i(0, -1), # Up    (North) - Y decreases going up
	1: Vector2i(-1, 0), # Left  (West)
	2: Vector2i(0, 1),  # Down  (South) - Y increases going down  
	3: Vector2i(1, 0),  # Right (East)
}


func update_room_visibility(player_grid_pos: Vector2i):
	var visible_rooms: Array[Vector2i] = []
	
	var queue: Array = [{"pos": player_grid_pos, "depth": 0}]
	
	var visited: Dictionary = {player_grid_pos: true}
	
	var current_group = p_ref.generated_rooms[player_grid_pos].group_id
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_pos = current["pos"]
		var current_depth = current["depth"]
		
		visible_rooms.append(current_pos)
		
		if current_depth <= 5:
			if p_ref.generated_rooms.has(current_pos):
				var room_data = p_ref.generated_rooms[current_pos]
				
				for dir in room_data.required_directions:
					var neighbor_pos = current_pos + DIR_VECTORS[dir]
					
					if p_ref.generated_rooms.has(neighbor_pos) and not visited.has(neighbor_pos):
						if p_ref.generated_rooms[neighbor_pos].group_id != -1:
							visited[neighbor_pos] = true
							queue.append({"pos": neighbor_pos, "depth": current_depth + 1})
						else:
							if p_ref.generated_rooms[neighbor_pos].group_id == current_group:
								if current_group == -1 and ((neighbor_pos.x == player_grid_pos.x or neighbor_pos.y == player_grid_pos.y)):
									visited[neighbor_pos] = true
									queue.append({"pos": neighbor_pos, "depth": current_depth + 1})
								elif current_group != -1:
									visited[neighbor_pos] = true
									queue.append({"pos": neighbor_pos, "depth": current_depth + 1})
							elif ((neighbor_pos.x == player_grid_pos.x or neighbor_pos.y == player_grid_pos.y)) and (p_ref.generated_rooms[neighbor_pos].group_id == -1 or p_ref.generated_rooms[neighbor_pos].group_id == -2):
								visited[neighbor_pos] = true
								queue.append({"pos": neighbor_pos, "depth": current_depth + 1})
						
	for pos in p_ref.generated_rooms.keys():
		var room_node = p_ref.get_room_node_at(pos) 
		if room_node != null:
			if pos in visible_rooms:
				#room_node.set_room_visible(true, 0.5)
				room_node.visible = true
				room_node.is_visible = true
				# e.g., enable_enemies_in_room(room_node)
			else:
				#room_node.set_room_visible(false, 0.5)
				room_node.visible = false
				room_node.is_visible = false
				# e.g., disable_enemies_in_room(room_node)

func get_rotation_degrees_(room_type: String, previous_rotation) -> float:
	var calculated_rot = 0.0 
	if room_type in ["Room_Cap", "Spawn_Room", "Stair_Room", "T_Chest_Room", "Quest_Room"]:
		match previous_rotation:
			180.0: calculated_rot = 0.0   # Facing Up 
			90.0: calculated_rot = 90.0  # Facing Down 
			360.0: calculated_rot = 180.0 # Facing Left 
			270.0: calculated_rot = -90.0  # Facing Right 
			0.0: calculated_rot = 180.0
			-90.0: calculated_rot = -90.0

	elif room_type in ["Corner_Junction", "Hallway_Corner"]:
		match previous_rotation:
			90.0: calculated_rot = 90.0   # Connects Left & Up
			0.0: calculated_rot = -180.0  # Connects Left & Down
			270.0: calculated_rot = -90.0 # Connects Right & Down
			180.0: calculated_rot = 0.0  # Connects Right & Up
			-90.0: calculated_rot = -90.0

	elif room_type in ["Horizontal_Corridor", "Vertical_Corridor", "Straight_Room"]:
		match previous_rotation:
			180.0 : calculated_rot = 90.0   # Vertical
			90.0 : calculated_rot = 0.0  # Horizontal
			0.0: calculated_rot = 90.0

	elif room_type in ["3-Way_Junction", "Hallway_3-Way_Junction"]:
		match previous_rotation:
			180.0 : calculated_rot = 0.0   # Solid wall is Right (South)
			90.0: calculated_rot = 90.0  # Solid wall is Left (West)
			360.0: calculated_rot = 180.0 # Solid wall is Up (North)
			270.0: calculated_rot = 270.0  # Solid wall is Down (East)
			-90.0: calculated_rot = -90.0
			0.0: calculated_rot = 180.0
	
	return calculated_rot
var has_entered_start_room = false

var x_scale_factor_lower = 0
var x_scale_factor_upper = 0

var y_scale_factor_lower = 0
var y_scale_factor_upper = 0

func center_around_spawn(spawn_coords):
	x_scale_factor = float(offset_) / float(p_ref.tile_size)
	y_scale_factor = float(offset_) / float(p_ref.tile_size)
	
	var shifted_x = spawn_coords.x - min_grid_x
	var shifted_y = spawn_coords.y - min_grid_y
	
	grid_container.position.x = (2.0 * offset_) - (shifted_x * offset_)
	grid_container.position.y = (2.0 * offset_) - (shifted_y * offset_)
	
	grid_offset = Vector2(grid_container.position.x, grid_container.position.y)
	

func _new_room_entered(coords):
	if has_setup_run:
		update_room_visibility(coords)
		var index = get_minimap_index(coords.x, coords.y)

		var current_room = p_ref.get_room_node_at(coords)
		
		if current_room == null:
			return
		
		match current_room.room_classification:
			0:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["S"]), load(room_start))
				full_screen_map.get_child(index)._change_texture(load(room_symbol_mapping["S"]), load(room_start))
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
				full_screen_map.get_child(index)._change_texture(load(room_symbol_mapping["S"]), load(stairs_down))
			2:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["R"]))
				full_screen_map.get_child(index)._change_texture(load(room_symbol_mapping["R"]))

			3:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["C"]))
				full_screen_map.get_child(index)._change_texture(load(room_symbol_mapping["C"]))
			4:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["3"]))
				full_screen_map.get_child(index)._change_texture(load(room_symbol_mapping["3"]))
			5:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["4"]))
				full_screen_map.get_child(index)._change_texture(load(room_symbol_mapping["4"]))
			6:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["-"]))
				full_screen_map.get_child(index)._change_texture(load(room_symbol_mapping["-"]))
			7:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["T"]), load(chest_room))
				full_screen_map.get_child(index)._change_texture(load(room_symbol_mapping["T"]), load(chest_room))
			8:
				grid_container.get_child(index)._change_texture(load(room_symbol_mapping["R"]))
				full_screen_map.get_child(index)._change_texture(load(room_symbol_mapping["R"]))
				
				
		grid_container.get_child(index).main_room_texture.rotation_degrees = get_rotation_degrees_(room_symbol_mapping_2[room_lookup[current_room.room_classification]], current_room.rotation_degrees.y)
		full_screen_map.get_child(index).main_room_texture.rotation_degrees = get_rotation_degrees_(room_symbol_mapping_2[room_lookup[current_room.room_classification]], current_room.rotation_degrees.y)
