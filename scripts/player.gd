class_name Player extends CharacterBody2D

var in_menu : bool = false
@export var move_speed : float = 300.0


@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var full_inventory = $CanvasLayer/VillageInventory
@onready var over_the_head_sprite = $OvertheHead
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var camera_zoom: Vector2 = Vector2(1, 1)

var animation_driver: CharacterAnimationDriver = CharacterAnimationDriver.new()

func _ready() -> void:
	if Global.loading_from_save:
		global_position = Global.saved_position
		Global.loading_from_save = false
	$Camera2D.reset_smoothing()
	animation_driver.sync(animated_sprite, Vector2.ZERO)
	$Camera2D.zoom = camera_zoom
	pause_menu.visible = false

func _process(_delta: float) -> void:
	if Global.is_paused:
		return
	var direction : Vector2 = Vector2.ZERO
	if Global.is_in_menu or Fade.is_fading or AreaStateManager.currently_transitioning:
		velocity = Vector2.ZERO
		animation_driver.sync(animated_sprite, Vector2.ZERO)
		return
		
	if not Global.using_controller:
		direction = Input.get_vector("left", "right", "up", "down")
	else:
		pass
		#direction = Input.get_vector(Global.controller_mapping["left"], Global.controller_mapping["right"], Global.controller_mapping["up"], Global.controller_mapping["down"])
		
	velocity = direction * move_speed
	animation_driver.sync(animated_sprite, velocity)
	
	if Global.player_head_sprite != null:
		over_the_head_sprite.texture = Global.player_head_sprite
	else:
		over_the_head_sprite.texture = null
	
func _input(event):
	# In Player _input
	if event.is_action_pressed("Pause"):
		print("HIII")
		if not pause_menu.visible:
			if Global.is_in_menu:
				return
			Global.is_paused = true
			pause_menu.visible = true
			get_tree().paused = true
			in_menu = true
			#full_inventory.manage_visibility(false)
			get_viewport().set_input_as_handled()
		else:
			print("HIII")
			Global.is_paused = false
			get_tree().paused = false
			in_menu = false
			pause_menu.visible = false
			
	if not Global.is_in_menu:
		if event.is_action_pressed("Mouse Scroll Up"):
			full_inventory.update_selection(-1)
		if event.is_action_pressed("Mouse Scroll Down"):
			full_inventory.update_selection(1)
	
func _physics_process(_delta):
	move_and_slide()
