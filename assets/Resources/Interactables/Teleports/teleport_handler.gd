@tool
extends Node

@onready var loading_zone_position = self.global_position

@export var location_data: Dictionary = {
	"Village": ["Potion Shop", "Infirmary", "Library"],
	"Forest": ["Left Side", "Right Side"]
}:
	set(value):
		location_data = value
		notify_property_list_changed() 

var _current_region: String = "Forest"
var _current_spot: String = ""

var _target_region: String = "Forest"
var _target_spot: String = ""

func _set(property, value):
	match property:
		"Current Location/Region":
			_current_region = value
			_current_spot = location_data[_current_region][0] if location_data.has(_current_region) else ""
			notify_property_list_changed()
			return true
		"Current Location/Spot":
			_current_spot = value
			return true
			
		"Destination Location/Region":
			_target_region = value
			_target_spot = location_data[_target_region][0] if location_data.has(_target_region) else ""
			notify_property_list_changed()
			return true
		"Destination Location/Spot":
			_target_spot = value
			return true
	return false

func _get(property):
	match property:
		"Current Location/Region": return _current_region
		"Current Location/Spot":   return _current_spot
		"Destination Location/Region": return _target_region
		"Destination Location/Spot":   return _target_spot
	return null

func _get_property_list():
	var properties = []
	var region_list = ",".join(location_data.keys())

	# Current Location
	properties.append({
		"name": "Current Location/Region",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": region_list,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	if location_data.has(_current_region):
		properties.append({
			"name": "Current Location/Spot",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(location_data[_current_region]),
			"usage": PROPERTY_USAGE_DEFAULT
		})

	# Destination
	properties.append({
		"name": "Destination Location/Region",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": region_list,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	if location_data.has(_target_region):
		properties.append({
			"name": "Destination Location/Spot",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(location_data[_target_region]),
			"usage": PROPERTY_USAGE_DEFAULT
		})
		
	return properties

func _on_area_2d_body_entered(body):
	if body.is_in_group("Overworld_Player"):
		if Global.current_loading_zone != "":
			Global.current_loading_zone = ""
			return
		Global.current_loading_zone = _target_spot
		get_tree().change_scene_to_file.call_deferred(Global.location_paths[_target_region])
