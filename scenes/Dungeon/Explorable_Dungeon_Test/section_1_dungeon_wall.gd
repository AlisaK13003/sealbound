extends Node3D

@onready var dungeon_0: Node3D = $Creepy_Dungeon_Section_1
@onready var dungeon_1: MeshInstance3D = $Section_1_Forest_Wall

@export_enum("Down", "Left", "Up", "Right") var what_direction: int = 0

func _setup(what_dungeon_to_use, pivot_rotation, parent_rotation):
	var direction = what_direction
	
	for child in get_children():
		if child is NavigationObstacle3D:
			continue
		elif child.get_index() == what_dungeon_to_use:
			child.visible = true
		else:
			child.visible = false

	
	match parent_rotation:
		0.0:
			direction = direction
		90.0:
			direction = posmod(direction + 1, 4)
		180.0:
			direction = posmod(direction + 2, 4)
		-90.0:
			direction = posmod(direction - 1, 4)
			
	what_direction = direction		
	match pivot_rotation:
		0.0: 
			if direction == 2 or direction == 1:  
				self.position.y = -0.8 
		-90.0:
			if direction == 2 or direction == 1:   
				self.position.y = -0.8
		-180.0:
			if direction == 1 or direction == 0:
				self.position.y = -0.8
		-270.0: 
			if direction == 2 or direction == 1: 
				self.position.y = -0.8
