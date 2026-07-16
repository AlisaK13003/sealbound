extends CharacterBody3D

@export var move_speed : float = 5.0 # (Note: In 3D, 300.0 is extremely fast unless scale is massive)
@onready var animated_sprite: AnimatedSprite3D = $SpritePivot/AnimatedSprite3D
@export var gravity: float = 20.0

@onready var camera = $Node3D/Camera3D
@onready var camera_ray = $Node3D/Camera3D/RayCast3D
@onready var camera_pivot = $Node3D

@onready var sprite_pivot = $SpritePivot
@onready var dungeon_overlay = $DungeonOverlay

signal entered_new_tile()

var current_grid_pos: Vector2i = Vector2i(-1, -1)

var is_moving
var p_ref: explorable_dungeon

var has_been_setup = false

func display_obtained_items(obtained_items):
	for item: Items in obtained_items:
		print(item.item_name)
	dungeon_overlay.display_gotten_chest_items(obtained_items)

func _setup(parent_reference):
	p_ref = parent_reference
	entered_new_tile.connect(dungeon_overlay.mini_map._new_room_entered)

	has_been_setup = true
	dungeon_overlay._setup(parent_reference)

func setup_fs():
	await dungeon_overlay._setup_dungeon_pause()
	if not entered_new_tile.is_connected(dungeon_overlay.pause_menu.mini_map._new_room_entered):
		entered_new_tile.connect(dungeon_overlay.pause_menu.mini_map._new_room_entered)	

func update_pivot_rotation(spawn_room):
	match spawn_room.required_directions[0]:
		0:
			camera_pivot.rotation_degrees.y = 0.0
		1:
			camera_pivot.rotation_degrees.y = -90.0
		2:
			camera_pivot.rotation_degrees.y = -180.0
		3:
			camera_pivot.rotation_degrees.y = -270.0
	#camera_pivot.rotation_degrees.y = 0.0

func clear_mini_map():
	dungeon_overlay.mini_map.clear_mini_map()

func _setup_mini_map(parent_ref, room_storage):
	dungeon_overlay.mini_map._setup(parent_ref, room_storage)
	dungeon_overlay._setup_dungeon_pause()

func store_enemy_list(enemy_array):
	dungeon_overlay.mini_map.store_current_enemy_list(enemy_array)
	dungeon_overlay.pause_menu.mini_map.store_current_enemy_list(enemy_array)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	if not has_been_setup:
		return
	if p_ref.movement_locked:
		return

	var input_dir : Vector2 = Vector2.ZERO
	if not Global.using_controller:
		input_dir = Input.get_vector("left", "right", "up", "down")
	else:
		input_dir = Input.get_vector(
			Global.controller_mapping["left"], 
			Global.controller_mapping["right"], 
			Global.controller_mapping["up"], 
			Global.controller_mapping["down"]
		)
		
	var forward: Vector3 = -camera.global_transform.basis.z
	var right: Vector3 = camera.global_transform.basis.x
	
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	sprite_pivot.rotation_degrees.y = camera_pivot.rotation_degrees.y
	var direction: Vector3 = (forward * (-input_dir.y) + right * (input_dir.x)).normalized()
	
	if direction != Vector3.ZERO:
		is_moving = true
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		var deceleration = move_speed * 10.0 * delta 
		velocity.x = move_toward(velocity.x, 0, deceleration)
		velocity.z = move_toward(velocity.z, 0, deceleration)
		
	if velocity.x == 0 and velocity.z == 0:
		is_moving = false
		
	move_and_slide()
	_check_for_new_tile()
	sync_animation(input_dir)
	update_sprite_scale()

func update_sprite_scale():
	if camera:
		var pitch_rad = camera.global_rotation.x 
		var compression_factor = abs(cos(pitch_rad))

		if compression_factor < 0.1: 
			compression_factor = 0.1 
			
		#animated_sprite.scale.y = 1.0 / compression_factor


func _check_for_new_tile() -> void:
	if not has_been_setup:
		return
	var offset = p_ref.tile_size / 2.0
	
	var grid_x = int(floor((global_position.x + offset) / p_ref.tile_size))
	var grid_y = int(floor((global_position.z + offset) / p_ref.tile_size)) 
	
	var calculated_pos = Vector2i(grid_x, grid_y)
	
	if calculated_pos != current_grid_pos:
		current_grid_pos = calculated_pos
		_on_tile_entered(current_grid_pos)
		
func _on_tile_entered(coords: Vector2i):
	entered_new_tile.emit(coords)
	# camera_pivot._on_player_entered_new_tile(p_ref.get_room_node_at(coords))
	
var last_direction: String = "down"

var anim_name: String = "idle"

var last_animation = "idle"
func sync_animation(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		anim_name = last_animation
	else:
		if abs(input_dir.x) >= abs(input_dir.y):
			if input_dir.x > 0:
				anim_name = "walk_right"
			else:
				anim_name = "walk_left"
		else:
			if input_dir.y < 0:
				anim_name = "walk_up"
			else:
				anim_name = "walk_down"
				
	if anim_name == "walk_left":
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	last_animation = anim_name
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
