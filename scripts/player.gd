class_name Player extends CharacterBody2D

var in_menu : bool = false
var move_speed : float = 300.0

@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var full_inventory = $CanvasLayer/VillageInventory
@onready var over_the_head_sprite = $OvertheHead

func _ready() -> void:
	Global.load_save_data()
	
func _process(_delta: float) -> void:
	if Global.is_in_menu:
		velocity = Vector2.ZERO
		return
	var direction : Vector2 = Vector2.ZERO
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
		
	velocity = direction * move_speed
	
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
	if not in_menu:
		if event.is_action_pressed("Mouse Scroll Up"):
			full_inventory.update_selection(-1)
		if event.is_action_pressed("Mouse Scroll Down"):
			full_inventory.update_selection(1)
	
func _physics_process(_delta):
	move_and_slide()
