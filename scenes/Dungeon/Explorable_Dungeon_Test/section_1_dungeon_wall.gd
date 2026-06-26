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
	
	
	match pivot_rotation:
		0.0:
			direction = direction
		-90.0:
			direction = posmod(direction - 1, 4)
		-180.0:
			direction = posmod(direction - 2, 4)
		-270.0:
			direction = posmod(direction - 3, 4)
			
	match parent_rotation:
		-90.0:
			if direction == 1 or direction == 2:
				self.position.y = -0.8
		0.0:
			if direction == 3 or direction == 2:
				self.position.y = -0.8
			elif get_parent().get_parent().room_classification == 3 and direction == 1:
				self.position.y -= 0.8
		90.0:
			if direction == 0 or direction == 3:
				self.position.y = -0.8
		180.0:
			if direction == 1 or direction == 0:
				self.position.y = -0.8
