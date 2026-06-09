extends CharacterBody3D

@export var move_speed : float = 5.0 # (Note: In 3D, 300.0 is extremely fast unless scale is massive)
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@export var gravity: float = 20.0

var p_ref: explorable_dungeon

func _setup(parent_reference):
	p_ref = parent_reference

func _physics_process(delta: float) -> void:
	if p_ref.free_cam:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

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
		
	var direction = Vector3(input_dir.x, 0, input_dir.y)
	
	if direction != Vector3.ZERO:
		direction = direction.normalized() 
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		
	var anim_direction = Vector2(velocity.x, velocity.z)
	sync(animated_sprite, anim_direction)
	move_and_slide()

var last_direction: String = "down"

func sync(sprite: Node, velocity: Vector2) -> void:
	var anim_name: String = "idle"
	
	if velocity.length_squared() > 0.1:
		var angle: float = velocity.angle()
		var index: int = wrapi(int(round(angle / (PI / 2))), 0, 4)
		var directions: Array[String] = ["right", "down", "left", "up"]
		last_direction = directions[index]
		
		anim_name = "walk_" + last_direction
	else:
		anim_name = "idle"
	
	if anim_name == "walk_left":
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	
	if sprite.animation != anim_name:
		sprite.play(anim_name)
