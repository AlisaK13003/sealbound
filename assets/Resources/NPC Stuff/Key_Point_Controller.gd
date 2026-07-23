@tool
extends Node2D

@export var location_name: Global.locations
@onready var location_position: Transform2D = Transform2D(0.0, global_position)
@onready var matrix_index: int = self.get_index()
@export var template_sprite: Texture2D
@export_enum("none", "down", "up", "left", "right") var arrival_facing: String = "none"
@onready var spriteNode: Sprite2D = $Sprite2D
@onready var labelNode: Label = $Label

@export_storage var connected_node_names: Array[String] = []

func _ready():
	spriteNode.texture = template_sprite

func get_arrival_facing() -> String:
	return arrival_facing

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
		connected_node_names.clear()
		if value is Array:
			for node_name in value:
				var cleaned_node_name := "" if node_name == null else str(node_name).strip_edges()
				connected_node_names.append(cleaned_node_name)
		return true
	return false

func _get(property):
	if property == "Connected To":
		return connected_node_names
	return null

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	var options = get_sibling_names_string()

	properties.append({
		"name": "Connected To",
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_ARRAY_TYPE,
		"hint_string": "4/2:%s" % options,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	return properties
