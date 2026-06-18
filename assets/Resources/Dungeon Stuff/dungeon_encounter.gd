extends Resource

class_name dungeon_type

@export var dungeon_name : String
@export var dungeon_background : Texture2D
@export var max_number_of_floors: int
@export var minimum_number_of_floors: int
@export var potential_encounters : Array[dungeon_wave]

@export var first_time_floor_count: int = 10

@export_flags("Creepy_Dungeon", "Forest_Dungeon") var type_of_dungeon = 0

var is_this_dungeon_unlocked: bool = false

@export var does_dungeon_have_boss: bool = false
var has_beaten_boss: bool = false

func load_save_data(save_data):
	is_this_dungeon_unlocked = save_data["is_dungeon_unlocked"]
	if does_dungeon_have_boss:
		has_beaten_boss = save_data["beaten_boss"]

func export_to_JSON():
	var ret_dict: Dictionary = {}
	
	ret_dict["path"] = resource_path
	ret_dict["is_dungeon_unlocked"] = is_this_dungeon_unlocked
	if does_dungeon_have_boss:
		ret_dict["beaten_boss"] = has_beaten_boss
	
	return ret_dict
