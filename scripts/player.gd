class_name Player extends CharacterBody2D

var in_menu : bool = false
@export var move_speed : float = 300.0


@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var full_inventory = $CanvasLayer/VillageInventory
@onready var over_the_head_sprite = $OvertheHead
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var animation_driver: CharacterAnimationDriver = CharacterAnimationDriver.new()

func _ready() -> void:
	print("[PLAYER] scene=", get_tree().current_scene.scene_file_path,
		" parent=", get_parent().get_path(),
		" total=", get_tree().get_nodes_in_group("Overworld_Player").size())
	$Camera2D.reset_smoothing()
	Global.load_save_data()
	animation_driver.sync(animated_sprite, Vector2.ZERO)

func _process(_delta: float) -> void:
	var direction : Vector2 = Vector2.ZERO
	if Global.is_in_menu or Fade.is_fading:
		velocity = Vector2.ZERO
		animation_driver.sync(animated_sprite, Vector2.ZERO)
		return
		
	if not Global.using_controller:
		direction = Input.get_vector("left", "right", "up", "down")
	else:
		direction = Input.get_vector(Global.controller_mapping["left"], Global.controller_mapping["right"], Global.controller_mapping["up"], Global.controller_mapping["down"])
		
	velocity = direction * move_speed
	animation_driver.sync(animated_sprite, velocity)
	
	if Global.player_head_sprite != null:
		over_the_head_sprite.texture = Global.player_head_sprite
	else:
		over_the_head_sprite.texture = null
	
func _input(event):
	
	if event.is_action_pressed("Inventory"):
		if Global.is_in_menu:
			return
		if not in_menu:
			full_inventory.manage_visibility(true)
			in_menu = true
		else:
			full_inventory.manage_visibility(false)
			in_menu = false
			
# In Player _input
	if event.is_action_pressed("Pause"):
		if Global.is_in_menu:
			return
		if not pause_menu.visible:
			pause_menu.visible = true
			get_tree().paused = true
			in_menu = true
			full_inventory.manage_visibility(false)
			get_viewport().set_input_as_handled()
				
	if not Global.is_in_menu:
		if event.is_action_pressed("Mouse Scroll Up"):
			full_inventory.update_selection(-1)
		if event.is_action_pressed("Mouse Scroll Down"):
			full_inventory.update_selection(1)
	
func _physics_process(_delta):
	move_and_slide()
