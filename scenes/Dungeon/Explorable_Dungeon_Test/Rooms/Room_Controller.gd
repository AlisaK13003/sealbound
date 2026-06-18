extends Node3D

class_name room

@onready var walls = $Walls

@export_enum("Spawn_Room", "Stair_Room", "Room_Cap", "Corner_Junction", "3-Way_Junction", "4-Way_Junction", "Straight_Room", "T_Chest_Room") var room_classification
var has_been_entered = false

var room_coords: Vector2 = Vector2(0, 0)

var room_directions

signal entered

var p_ref: explorable_dungeon
	
func _setup(p_ref: explorable_dungeon):
	self.p_ref = p_ref
	var wall_children = $Walls.get_children()
	if room_classification == 1:
		get_node("StairDownTeleporter").go_down_floor.connect(p_ref.entered_new_floor)
		
	print(p_ref.current_dungeon.type_of_dungeon)
	for floor_panel in $Floor.get_children():
		if floor_panel.get_index() == p_ref.current_dungeon.type_of_dungeon - 1:
			floor_panel.visible = true
		else:
			floor_panel.visible = false
		
	for child in wall_children:
		child._setup(p_ref.current_dungeon.type_of_dungeon)
