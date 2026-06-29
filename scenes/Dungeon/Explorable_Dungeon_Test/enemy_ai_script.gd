extends CharacterBody3D

enum State { PATROL, CHASE, RETURN }
var current_state: State = State.PATROL

@export var speed: float = 3.0
@export var patrol_radius: float = 12.0 
@export var return_speed: float = 4.0
@export var gravity: float = 20.0 

@export var enemy_detection_range: float = 1.0 
@export var enemy_check_interval: float = 3  
var enemy_check_timer: float = 0.0

@export var stuck_time_limit: float = 5.0
var stuck_timer: float = 0.0
var last_position: Vector3 = Vector3.ZERO
var last_move_direction: Vector3 = Vector3.FORWARD

var last_known_player_position: Vector3 = Vector3.ZERO

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player_detector: Area3D = $Area3D
@onready var los_ray: RayCast3D = $RayCast3D     

@onready var player_combat_detector: Area3D = $Player_Detector

@export var time_to_wait_after_completing_path: float = 0.0

@onready var animator = $AnimatedSprite3D
var enemy_sprite_frames: SpriteFrames

var start_position: Vector3
var target_player: Node3D = null
var p_ref: explorable_dungeon
var still_setting_up = true

var stored_enemy: generic_combatants

func _ready() -> void:
	_auto_tune_navigation_agent()
	nav_agent.velocity_computed.connect(_on_navigation_agent_3d_velocity_computed)

func _setup(parent_reference, enemy_that_I_am: generic_combatants) -> void:
	p_ref = parent_reference
	start_position = global_position
	last_position = global_position
	player_detector.body_entered.connect(_on_player_detected)
	player_detector.body_exited.connect(_on_player_exited)
	add_to_group("enemies")
	stored_enemy = enemy_that_I_am
	enemy_sprite_frames = enemy_that_I_am.sprite_frames
	animator.sprite_frames = enemy_sprite_frames
	animator.play("Idle")
	await get_tree().physics_frame
	_pick_new_patrol_point()
	still_setting_up = false

var wait_timer = 0.0
var disabled_timer = 0.0
func _physics_process(delta: float) -> void:
	if still_setting_up:
		return
	_check_for_new_tile()

	if disable_monitoring:
		return
	
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if p_ref.movement_locked:
		return
		
	
	if not nav_agent.is_navigation_finished():
		_check_if_stuck(delta)	
	else:
		stuck_timer = 0.0
		last_position = global_position
		
	match current_state:
		State.PATROL:
			if target_player and _has_line_of_sight():
				current_state = State.CHASE
			else:
				if nav_agent.is_navigation_finished():
					wait_timer += delta
					if wait_timer >= time_to_wait_after_completing_path:
						wait_timer = 0.0
						
						var dist_to_start = global_position.distance_to(start_position)
						if dist_to_start >= (2.0 * p_ref.tile_size):
							nav_agent.target_position = start_position
						else:
							_pick_new_patrol_point()
					return
				_move_along_path(speed)

		State.CHASE:
			if target_player:
				var room_class = p_ref.get_room_node_at(p_ref.player.current_grid_pos).room_classification
				if room_class in [0, 1]:
					current_state = State.PATROL
					nav_agent.target_position = global_position 
					wait_timer = 0.0
					return
				
				if _has_line_of_sight():
					last_known_player_position = target_player.global_position
					
					var dist_to_player = nav_agent.target_position.distance_to(target_player.global_position)
					if dist_to_player > 1.0:
						nav_agent.target_position = target_player.global_position
					
					_move_along_path(speed) 
				
				else:
					current_state = State.PATROL
					wait_timer = 0.0
					
					nav_agent.target_position = last_known_player_position # Walk to last known spot first

var current_grid_pos: Vector2i

func _check_for_new_tile() -> void:
	if still_setting_up:
		return
		
	var offset = p_ref.tile_size / 2.0
	
	var grid_x = int(floor((global_position.x + offset) / p_ref.tile_size))
	var grid_y = int(floor((global_position.z + offset) / p_ref.tile_size)) 
	
	var calculated_pos = Vector2i(grid_x, grid_y)

	if calculated_pos != current_grid_pos:
		current_grid_pos = calculated_pos
		
	if not p_ref.get_room_node_at(current_grid_pos).is_visible:
		self.visible = false
		#disable_monitoring = true
	else:
		self.visible = true
		#disable_monitoring = false


func _move_along_path(current_speed: float) -> void:
	var next_path_pos = nav_agent.get_next_path_position()
	
	var current_flat_pos = Vector3(global_position.x, 0.0, global_position.z)
	var next_flat_pos = Vector3(next_path_pos.x, 0.0, next_path_pos.z)
	var direction = (next_flat_pos - current_flat_pos).normalized()
	
	if direction.length_squared() > 0.001:
		last_move_direction = direction
	
	var calculated_velocity = direction * current_speed
	
	if nav_agent.avoidance_enabled:
		nav_agent.velocity = calculated_velocity
	else:
		velocity.x = calculated_velocity.x
		velocity.z = calculated_velocity.z
		move_and_slide()

func _check_if_stuck(delta: float) -> void:
	var distance_moved = global_position.distance_to(last_position)
	last_position = global_position
	
	var expected_movement = speed * delta * 0.1
	
	if distance_moved < expected_movement:
		stuck_timer += delta
		if stuck_timer >= stuck_time_limit:
			_handle_stuck_recovery()
	else:
		stuck_timer = 0.0

func _handle_stuck_recovery() -> void:
	stuck_timer = 0.0
	
	target_player = null
	current_state = State.PATROL
		
	var backward_dir = -last_move_direction.normalized()
	var backup_target = global_position + (backward_dir * 4.0)
	
	var map = get_world_3d().navigation_map
	nav_agent.target_position = NavigationServer3D.map_get_closest_point(map, backup_target)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()

func _auto_tune_navigation_agent() -> void:
	var collision_shape: CollisionShape3D = $CollisionShape3D
	if not collision_shape or not collision_shape.shape:
		return
		
	var r_phys: float = 0.5
	var h_phys: float = 1.0
	
	if collision_shape.shape is CapsuleShape3D:
		r_phys = collision_shape.shape.radius
		h_phys = collision_shape.shape.height
	elif collision_shape.shape is SphereShape3D:
		r_phys = collision_shape.shape.radius
		h_phys = collision_shape.shape.radius * 2.0
		
	var map: RID = get_world_3d().navigation_map
	var c_size: float = NavigationServer3D.map_get_cell_size(map)
	if c_size <= 0.0:
		c_size = 0.25
	
	nav_agent.path_desired_distance = max(r_phys * 1.5, c_size)
	nav_agent.target_desired_distance = max(r_phys, c_size)
	nav_agent.path_height_offset = h_phys / 2.0

func _pick_new_patrol_point() -> void:
	var patrol_radius = (2 * p_ref.tile_size)
	
	var random_angle = randf() * TAU # TAU is 2 * PI
	var random_distance = randf_range(0.0, patrol_radius)
	
	var offset = Vector3(
		cos(random_angle) * random_distance,
		0,
		sin(random_angle) * random_distance
	)
	
	var target_candidate = start_position + offset
	
	var walkable_target = NavigationServer3D.map_get_closest_point(
		nav_agent.get_navigation_map(),
		target_candidate
	)
	
	nav_agent.target_position = walkable_target

func _has_line_of_sight() -> bool:
	if not target_player:
		return false
		
	los_ray.target_position = los_ray.to_local(target_player.global_position + Vector3(0, 0.5, 0))
	los_ray.force_raycast_update()
	
	if not los_ray.is_colliding():
		return true
	return los_ray.get_collider() == target_player

func _on_player_detected(body: Node3D) -> void:
	if body.is_in_group("3D_Player"): 
		target_player = body
		if _has_line_of_sight():
			current_state = State.CHASE

func _check_nearby_enemies() -> void:
	var active_enemies = get_tree().get_nodes_in_group("enemies")
	
	for other_enemy in active_enemies:
		if other_enemy == self:
			continue 
		
		var distance_to_other = global_position.distance_to(other_enemy.global_position)
		
		if distance_to_other < enemy_detection_range:
			_flee_from_enemy(other_enemy)
			break 

func _on_player_exited(body: Node3D) -> void:
	if body == target_player:
		target_player = null
		if current_state == State.CHASE or current_state == State.RETURN:
			current_state = State.PATROL
			_pick_new_patrol_point()

func _flee_from_enemy(other_enemy: Node3D) -> void:
	var away_dir = (global_position - other_enemy.global_position).normalized()
	away_dir.y = 0.0 
	away_dir = away_dir.normalized()
	
	var flee_point = global_position + (away_dir * 5.0)
	
	var map = get_world_3d().navigation_map
	nav_agent.target_position = NavigationServer3D.map_get_closest_point(map, flee_point)
	
	if current_state == State.CHASE:
		target_player = null
		current_state = State.PATROL

func _on_area_3d_2_body_entered(body):
	return
	if disable_monitoring:
		return
	if body.is_in_group("3D_Player"):
		print("BATTLE INITIATED")
		p_ref.movement_locked = true
		p_ref.battle_initiated(stored_enemy, self.get_instance_id())

var disable_monitoring = false
func disable_player_detection():
	disable_monitoring = true
	player_combat_detector.set_deferred("monitoring", false)

func enable_player_detection():
	disable_monitoring = false
	player_combat_detector.set_deferred("monitoring", true)
