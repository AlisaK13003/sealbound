extends Node2D

@export var location_name: String
@onready var location_position: Transform2D = Transform2D(0.0, global_position)
@onready var matrix_index: int = self.get_index()
@export var connected_to_places: Array[int]
@export var template_sprite: Texture2D
@onready var spriteNode: Sprite2D = $Sprite2D
@onready var labelNode: Label = $Label

func _ready():
	spriteNode.texture = template_sprite
	labelNode.text = location_name
