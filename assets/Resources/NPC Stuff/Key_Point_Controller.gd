@tool
extends Node2D

@export var location_name: Global.locations
@onready var location_position: Transform2D = Transform2D(0.0, global_position)
@onready var matrix_index: int = self.get_index()
@export var connected_to_places: Array[int]
@export var template_sprite: Texture2D
@onready var spriteNode: Sprite2D = $Sprite2D
@onready var labelNode: Label = $Label

@export var connected_node_names: Array = []
@export var run_my_function: bool = false:
	set(value):
		if value: # Only trigger when clicked (set to true)
			notify_property_list_changed() 

func _ready():
	spriteNode.texture = template_sprite

func get_sibling_names_string() -> String:
	var names = []
	if get_parent():
		for child in get_parent().get_children():
			if child != self:
				names.append(child.name)
	return ",".join(names)
	
var location_list


func _set(property, value):
	if property == "Connected To":
		connected_node_names = value
		return true
	return false

func _get(property):
	if property == "Connected To":
		return connected_node_names
	return null

func _get_property_list():
	var properties = []
	var options = get_sibling_names_string()

	properties.append({
		"name": "Connected To",
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_ARRAY_TYPE,
		"hint_string": "4/2:%s" % options,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	return properties
