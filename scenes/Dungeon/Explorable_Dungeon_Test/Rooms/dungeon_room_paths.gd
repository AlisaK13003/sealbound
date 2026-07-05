extends Node

class_name room_paths

var room_symbol_mapping: Dictionary = {
	"S": "Spawn_Room",
	"E": "Stair_Room",
	"R": "Room_Cap",
	"C": "Corner_Junction",
	"3": "3-Way_Junction",
	"4": "4-Way_Junction",
	"2": "2x2_Room",
	"T": "T_Chest_Room",            

	# --- Hallways & Corridors ---
	"H": "Generic_Hallway",      
	"h": "Room_Cap",        
	"-": "Straight_Room",
	"|": "Straight_Room",  
	"c": "Corner_Junction",      
	"t": "3-Way_Junction", 
	"+": "4-Way_Junction", 

	"0": "Empty_Space"      
}

var room_names = ["Spawn_Room", "Room_Cap", "4-Way_Junction", "3-Way_Junction", "Corner_Junction", "2x2_Room", "T_Chest_Room", "Stair_Room", "Straight_Room"]
var rooms : Dictionary = {
	"Spawn_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Spawn_Room.tscn",
	"Room_Cap": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Room_Cap.tscn",
	"4-Way_Junction": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/4-Way_Junction2.tscn",
	"3-Way_Junction": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/3-way-junction.tscn",
	"Corner_Junction": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Corner_Junction.tscn",
	"2x2_Room": "",
	"T_Chest_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Chest_Room_.tscn",
	"Stair_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/Stair_Room.tscn",
	"Straight_Room": "res://scenes/Dungeon/Explorable_Dungeon_Test/Rooms/Forest_Dungeon/Fix_Scenes/straight_room_.tscn"
}

var room_sizing : Dictionary = {
	"Spawn_Room": 1,
	"Room_Cap": 1,
	"Horizontal_Corridor": 1,
	"4-Way_Junction": 1,
	"3-Way_Junction": 1,
	"Corner_Junction": 1,
	"2x2_Room": 2,
	"Stair_Room": 1,
	"T_Chest_Room": 1,
}

var room_exits: Dictionary = {
	"Spawn_Room": 1,
	"Room_Cap": 1,
	"Horizontal_Corridor": 2,
	"4-Way_Junction": 4,
	"3-Way_Junction": 3,
	"Corner_Junction": 2,
	"T_Chest_Room": 1,
	"2x2_Room": 2,
	"Stair_Room": 1
}

var same_directions: Dictionary = {
	0: 1,
	1: 0,
	2: 3, 
	3: 2
}

var valid_directions: Dictionary = {
	"Spawn_Room": [], 
	"Room_Cap": [
		[0], [1], [2], [3] 
	],
	"T_Chest_Room":
		[
		[0], [1], [2], [3]		
	],
	"Horizontal_Corridor": [
		[0, 1], [1, 0], 
		[2, 3], [3, 2]  
	],
	"4-Way_Junction": [], 
	"3-Way_Junction": [
		[0, 1, 2], [0, 1, 3], [0, 2, 3], 
		[1, 0, 2], [1, 0, 3], [1, 2, 3], 
		[2, 0, 1], [2, 0, 3], [2, 1, 3], 
		[3, 0, 1], [3, 0, 2], [3, 1, 2]  
	],
	"Corner_Junction": [
		[0, 2], [2, 0], 
		[1, 2], [2, 1], 
		[0, 3], [3, 0], 
		[1, 3], [3, 1]  
	],
	"2x2_Room": [], 
	"Stair_Room": [] 
}

const DIR_VECTORS = {
	0: Vector2i(-1, 0), # Left
	1: Vector2i(1, 0),  # Right
	2: Vector2i(0, -1), # Up
	3: Vector2i(0, 1)   # Down
}
