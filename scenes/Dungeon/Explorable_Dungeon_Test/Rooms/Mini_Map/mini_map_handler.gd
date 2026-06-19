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
@export_enum("Spawn_Room", "Stair_Room", "Room_Cap", "Corner_Junction", "3-Way_Junction", "4-Way_Junction", "Straight_Room", "T_Chest_Room") var room_classification

var room_lookup: Dictionary = {
	0: "S",
	1: "E",
	2: "R",
	3: "C",
	4: "3", 
	5: "4",
	6: "-",
	7: "T",
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
		f_grid.size = p_ref.max_grid_size * 40
		
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

		current_enemy_2.position.x = (float($Full_Screen_Map/Panel.size.x) / (float(p_ref.max_grid_size.x) * float(p_ref.tile_size))) * (float(enemy_list[enemy].position.x)) / ((float($Full_Screen_Map/Panel.size.x) * float(1.0 / float($Full_Screen_Map/Panel/GridContainer.scale.x))) / float($Full_Screen_Map/Panel/GridContainer.size.x))
		current_enemy_2.position.y = (float($Full_Screen_Map/Panel.size.y) / (float(p_ref.max_grid_size.y) * float(p_ref.tile_size))) * (float(enemy_list[enemy].position.z)) / ((float($Full_Screen_Map/Panel.size.y) * float(1.0 / float($Full_Screen_Map/Panel/GridContainer.scale.y))) / float($Full_Screen_Map/Panel/GridContainer.size.y))
		current_enemy_2.position.x += f_grid.scale.x * 20
		current_enemy_2.position.y += f_grid.scale.y * 20

	if has_entered_start_room and p_ref.player.is_moving:
		grid_container.position.x = -1 * (p_ref.player.position.x - (2 * p_ref.tile_size)) * x_scale_factor
		grid_container.position.y = -1 * (p_ref.player.position.z - (2 * p_ref.tile_size)) * y_scale_factor
		
		#$Full_Screen_Map/Panel/GridContainer.position.x = -1 * (p_ref.player.position.x - (2 * p_ref.tile_size)) * x_scale_factor
		#f_grid.position.y = -1 * (p_ref.player.position.z - (2 * p_ref.tile_size)) * y_scale_factor
		
		f_rect.position.x = (float($Full_Screen_Map/Panel.size.x) / (float(p_ref.max_grid_size.x) * float(p_ref.tile_size))) * (float(p_ref.player.position.x)) / ((float($Full_Screen_Map/Panel.size.x) * float(1.0 / float($Full_Screen_Map/Panel/GridContainer.scale.x))) / float($Full_Screen_Map/Panel/GridContainer.size.x))
		f_rect.position.y = (float($Full_Screen_Map/Panel.size.y) / (float(p_ref.max_grid_size.y) * float(p_ref.tile_size))) * (float(p_ref.player.position.z)) / ((float($Full_Screen_Map/Panel.size.y) * float(1.0 / float($Full_Screen_Map/Panel/GridContainer.scale.y))) / float($Full_Screen_Map/Panel/GridContainer.size.y))
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
	var max_y = p_ref.max_grid_size.y
	
	var child_index = (grid_y * p_ref.max_grid_size.x) + grid_x
	
	return child_index

var has_setup_run = false
func _setup(parent_reference: explorable_dungeon, bounding_box_arr, generated_rooms, spawn_coords):
	p_ref = parent_reference
	
	grid_container.columns = p_ref.max_grid_size.x
	full_screen_map.columns = p_ref.max_grid_size.x
	
	f_grid.size = (40 * f_grid.scale) * Vector2(p_ref.max_grid_size.x, p_ref.max_grid_size.y) 
	mov_cont.size = f_grid.size
	
	
	var room_lookup = {}
	for room_ in generated_rooms:
		room_lookup[Vector2i(room_.room_x_coord, room_.room_y_coord)] = room_
	
	for y in range(p_ref.max_grid_size.y):
		for x in range(p_ref.max_grid_size.x):
			
			var cell_string = str(bounding_box_arr[x][y])
			
			var new_map_node = load(tile_)
			var new_map_node_instance: Control = new_map_node.instantiate()
			
			var new_map_node_2 = load(tile_)
			var new_map_node_instance_2: Control = new_map_node_2.instantiate()
			
			full_screen_map.add_child(new_map_node_instance_2)
			grid_container.add_child(new_map_node_instance)
	has_setup_run = true
	_new_room_entered(spawn_coords)

const ASSET_OFFSETS = {
	"Spawn_Room": 0.0,
	"Stair_Room": 0.0,
	"Room_Cap": 0.0,             
	"Corner_Junction": 180.0,    
	"Hallway_Corner": 0.0,
	"Horizontal_Corridor": 0.0,  
	"Vertical_Corridor": 0.0,
	"3-Way_Junction": -270.0,       
	"Hallway_3-Way_Junction": 0.0,
	"Straight_Room": 0.0,
	"T_Chest_Room": 0.0,
}

func get_rotation_degrees_(room_type: String, previous_rotation) -> float:
	
	var calculated_rot = 0.0 
	if room_type in ["Room_Cap", "Spawn_Room", "Stair_Room", "T_Chest_Room"]:
		match previous_rotation:
			180.0: calculated_rot = 0.0   # Facing Up 
			90.0: calculated_rot = 90.0  # Facing Down 
			360.0: calculated_rot = 180.0 # Facing Left 
			270.0: calculated_rot = -90.0  # Facing Right 
			0.0: calculated_rot = 180.0

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
				
		grid_container.get_child(index).main_room_texture.rotation_degrees = get_rotation_degrees_(room_symbol_mapping_2[room_lookup[current_room.room_classification]], current_room.rotation_degrees.y)
		full_screen_map.get_child(index).main_room_texture.rotation_degrees = get_rotation_degrees_(room_symbol_mapping_2[room_lookup[current_room.room_classification]], current_room.rotation_degrees.y)
