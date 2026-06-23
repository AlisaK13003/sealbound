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
				await remove_old_dungeon()

		setting_up = false
	print("FADING OUT")
	setting_up_new_floor = false
	await Fade.fade_out(2)
	movement_locked = false
	
func generate_dungeon():
	var new_room_generation: dungeon_generation = dungeon_generation.new()
	
	var room_storage = new_room_generation.build_dungeon()	

	var ret_val = await instantiate_rooms(room_storage)
	return true
	if not ret_val:
		return false
	mini_map._setup(room_storage)

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
	
	player.position = Vector3(0, 5.0, 0)

	#player.position.x += (generated_rooms[0].room_x_coord * tile_size)
	#player.position.z += (generated_rooms[0].room_y_coord * tile_size)
	
	var current_start = 0 #get_room_node_at(index_to_pos(spawn_room_location))
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
		
		new_room._setup(self)
		
		new_room.rotation_degrees.y = room_storage[room_].get_rotation_degrees_()
		
		navigation_region.add_child(new_room)
		
		

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
