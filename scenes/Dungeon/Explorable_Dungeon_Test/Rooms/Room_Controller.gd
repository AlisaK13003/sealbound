extends Node3D

class_name room

@export_enum("Spawn_Room", "Stair_Room", "Room_Cap", "Corner_Junction", "3-Way_Junction", "4-Way_Junction", "Straight_Room") var room_classification
var has_been_entered = false

signal entered

var p_ref: explorable_dungeon
	
func _setup(p_ref: explorable_dungeon):
	self.p_ref = p_ref
	print(room_classification)
	if room_classification == 1:
		print("CONNECTED")
		get_node("StairDownTeleporter").go_down_floor.connect(p_ref.entered_new_floor)
