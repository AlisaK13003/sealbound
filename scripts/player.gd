class_name Player extends CharacterBody2D

var in_menu : bool = false
@export var move_speed : float = 300.0
@export var idle_texture: Texture2D = preload("res://assets/Sprites/FEMC_Stand.tres")
@export var walk_texture: Texture2D
@export var idle_frame_size: Vector2i = Vector2i.ZERO
@export var walk_frame_size: Vector2i = Vector2i.ZERO
@export var walk_frames_per_row: int = 0
@export var walk_down_row: int = 0
@export var walk_side_row: int = 1
@export var walk_up_row: int = 2
@export var animation_speed: float = 8.0

@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var full_inventory = $CanvasLayer/VillageInventory
@onready var over_the_head_sprite = $OvertheHead
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var animation_driver: CharacterAnimationDriver = CharacterAnimationDriver.new()

func _ready() -> void:
	Global.load_save_data()
	animation_driver.setup_sprite(
		animated_sprite,
		idle_texture,
		walk_texture,
		idle_frame_size,
		walk_frame_size,
		walk_frames_per_row,
		walk_down_row,
		walk_side_row,
		walk_up_row,
		animation_speed
	)
			
func _process(_delta: float) -> void:
	var direction : Vector2 = Vector2.ZERO
	if Global.is_in_menu or Fade.is_fading:
		velocity = Vector2.ZERO
		animation_driver.sync(animated_sprite, Vector2.ZERO)
		return
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
		
	velocity = direction * move_speed
	animation_driver.sync(animated_sprite, velocity)
	
	if Global.player_head_sprite != null:
		over_the_head_sprite.texture = Global.player_head_sprite
	else:
		over_the_head_sprite.texture = null
	
func _input(event):
	if event.is_action_pressed("Pause"):
		if Global.is_in_menu:
			return
		if not in_menu:
			full_inventory.manage_visibility(true)
			in_menu = true
		else:
			full_inventory.manage_visibility(false)
			in_menu = false
	if not Global.is_in_menu:
		if event.is_action_pressed("Mouse Scroll Up"):
			full_inventory.update_selection(-1)
		if event.is_action_pressed("Mouse Scroll Down"):
			full_inventory.update_selection(1)
	
func _physics_process(_delta):
	move_and_slide()
