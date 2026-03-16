class_name Player extends CharacterBody2D

@onready var pause_menu = $CanvasLayer/PauseMenu

@export var item_to_add : Items
@export var item_to_add2 : Items

var in_menu : bool = false

var move_speed : float = 300.0

# -------------------------------------------
# TEMPORARY GLOBAL SETUP

@export var entire_party : Array[PartyMember]

@export var money : int

@export var party_slot_1 : PartyMember
@export var party_slot_2 : PartyMember
@export var party_slot_3 : PartyMember

@export var item_list : Array[Items]
@export var equipment_list : Array[equipment]
@export var weapon_list : Array[weapon]

# -------------------------------------------

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.load_save_data()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Global.is_in_menu or in_menu:
		velocity = Vector2.ZERO
		return
	var direction : Vector2 = Vector2.ZERO
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
		
	velocity = direction * move_speed
	
	
func _input(event):
	if event.is_action_pressed("Open Menu"):
		Global.add_item(item_to_add)
		Global.add_item(item_to_add2)

	if event.is_action_pressed("Pause"):
		if Global.is_in_menu:
			return
		if not in_menu:
			pause_menu.visible = true
			in_menu = true
		else:
			pause_menu.visible = false
			in_menu = false
			
func _physics_process(_delta):
	move_and_slide()
