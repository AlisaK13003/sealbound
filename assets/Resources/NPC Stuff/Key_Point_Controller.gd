@tool
extends Node2D

@export var location_name: Global.locations
@onready var location_position: Transform2D = Transform2D(0.0, global_position)
@onready var matrix_index: int = self.get_index()
@export var connected_to_places: Array[int]
@export var template_sprite: Texture2D
@onready var spriteNode: Sprite2D = $Sprite2D
@onready var labelNode: Label = $Label

@export var hi : String
@export var run_my_function: bool = false:
	set(value):
		if value: # Only trigger when clicked (set to true)
			collect_locations()


func _ready():
	spriteNode.texture = template_sprite
	for location in self.get_parent().get_children():
		print(location.name)

@export var _connected_to_spots : Array[String]

func collect_locations():
	
	for location in self.get_parent().get_children():
		print(location.name)
	
	hi = "HII"
	return "HII"
