extends Resource

class_name quest

@export_category("Quest Criteria")
@export var quest_name: String
@export var quest_giver: String
@export var quest_giver_sprite: Texture2D
@export var quest_description: String
@export var dungeon_location: GlobalCombatInformation.dungeon_types_names
@export var difficult_level: GlobalCombatInformation.difficulty_multiplier

@export var state_to_set_upon_completion: StateManager.story_beats_lookup

@export_category("Spot")
# If put in enemy and int it will require that enemies quest item to that quantity
# If you put in a normal item it will require that quantity of it
@export var completion_requirements: Dictionary
@export var should_spawn_dungeon_room: bool = false
@export var required_spawn: bool = false
@export var special_dungeon: dungeon_type = null
var does_player_have_special_item: bool = false
@export var item_sprite: Texture2D
@export var item_sprite_pixel_size: float = 0.005

@export_category("Quest Rewards")
@export var reward_money: int
@export var reward_bond: int
@export var reward_items: Array[Items]
@export var reward_weapons: Array[weapon]
@export var reward_equipment: Array[equipment]

@export var custom_resource_path: String

func export_to_JSON():
	if resource_path == "":
		return {"path": custom_resource_path}
	else:
		return {"path": resource_path}
