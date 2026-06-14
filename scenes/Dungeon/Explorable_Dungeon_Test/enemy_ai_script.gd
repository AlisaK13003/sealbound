extends CharacterBody3D

enum State { PATROL, CHASE, RETURN }
var current_state: State = State.PATROL

@export var speed: float = 3.0
@export var patrol_radius: float = 12.0 
@export var return_speed: float = 4.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player_detector: Area3D = $Area3D
@onready var los_ray: RayCast3D = $RayCast3D     

var start_position: Vector3
var target_player: Node3D = null

var p_ref: explorable_dungeon

var still_setting_up = true

var dungeon_to_use = load("res://assets/Resources/Dungeon Stuff/Dungeon_25D.tscn")
var dungeon_type_ = load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Creepy_Dungeon.tres")

func _setup(parent_reference) -> void:
	p_ref = parent_reference
	start_position = global_position
	player_detector.body_entered.connect(_on_player_detected)
	player_detector.body_exited.connect(_on_player_lost)
	
	await get_tree().physics_frame
	_pick_new_patrol_point()
	still_setting_up = false

@export var gravity: float = 20.0 

func _physics_process(delta: float) -> void:
	if still_setting_up:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	match current_state:
		State.PATROL:
			if nav_agent.is_navigation_finished():
				_pick_new_patrol_point()
			_move_along_path(speed)
			
		State.CHASE:
			if target_player:
				nav_agent.target_position = target_player.global_position
				if not _has_line_of_sight():
					_start_returning()
			_move_along_path(speed)
			
		State.RETURN:
			if nav_agent.is_navigation_finished():
				current_state = State.PATROL
			_move_along_path(return_speed)

func _move_along_path(current_speed: float) -> void:
	var next_path_pos = nav_agent.get_next_path_position()
	
	var current_flat_pos = Vector3(global_position.x, 0.0, global_position.z)
	var next_flat_pos = Vector3(next_path_pos.x, 0.0, next_path_pos.z)
	var direction = (next_flat_pos - current_flat_pos).normalized()
	
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	move_and_slide()

func _pick_new_patrol_point() -> void:
	var random_offset = Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0,
		randf_range(-patrol_radius, patrol_radius)
	)
	var target_point = start_position + random_offset
	
	var map = get_world_3d().navigation_map
	nav_agent.target_position = NavigationServer3D.map_get_closest_point(map, target_point)

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

func _on_player_lost(body: Node3D) -> void:
	if body == target_player:
		_start_returning()

func _start_returning() -> void:
	target_player = null
	current_state = State.RETURN
	nav_agent.target_position = start_position
	
	
func _on_area_3d_2_body_entered(body):
	return
	if body.is_in_group("3D_Player"):
		await Fade.fade_in(1)
		await GlobalCombatInformation.load_items()
		GlobalCombatInformation.transition_to_dungeon(0)
