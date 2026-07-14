extends Resource

class_name dungeon_type

@export var dungeon_name : String
@export var dungeon_background : Texture2D
@export var max_number_of_floors: int
@export var minimum_number_of_floors: int
@export var potential_encounters : Array[dungeon_wave]

@export var dungeon_light_color: Color = Color.WHITE

@export var first_time_floor_count: int = 10

@export var type_of_dungeon: GlobalCombatInformation.dungeon_types_names

@export var quest_dungeon: bool = false

var is_this_dungeon_unlocked: bool = false

@export var chest_drops: Dictionary[Array, float]

@export var does_dungeon_have_boss: bool = false
@export var boss_encounter: dungeon_wave

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
