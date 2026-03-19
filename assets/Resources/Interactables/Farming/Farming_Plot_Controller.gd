extends Node2D

@export var width: int
@export var height: int

@export var horizontal_separation: int
@export var vertical_separation: int

@onready var tile_resource = load("D:/sealbound/assets/Resources/Interactables/Farming/Farming_Tile.tscn")

# Sets up a grid of farming plots
func _ready():
	Global.planted_crops.resize(width * height)
	for i in range(width):
		for j in range(height):
			add_child(tile_resource.instantiate())
			
			get_child(i * width + j).position += Vector2(horizontal_separation * j, vertical_separation * i)
			
			get_child(i * width + j)._setup(i * width + j)
