extends Node3D

@onready var dungeon_0: Node3D = $Creepy_Dungeon_Section_1
@onready var dungeon_1: MeshInstance3D = $Section_1_Forest_Wall

func _setup(what_dungeon_to_use):
	for child in get_children():
		if child is NavigationObstacle3D:
			continue
		elif child.get_index() == what_dungeon_to_use:
			child.visible = true
		else:
			child.visible = false
