extends Resource

class_name quest

@export_category("Quest Criteria")
@export var quest_name: String
@export var quest_giver: String
@export var quest_description: String
@export var dungeon_location: GlobalCombatInformation.dungeon_types_names
@export var difficult_level: GlobalCombatInformation.difficulty_multiplier

@export var unlock_seal_requirement: Array[Global.Progression_Flags]
# Will be filled in when bond is sorted
@export var unlock_bond_requirements: int

@export_category("Spot")
# If put in enemy and int it will require that enemies quest item to that quantity
# If you put in a normal item it will require that quantity of it
@export var completion_requirements: Dictionary
@export var should_spawn_dungeon_room: bool = false
var does_player_have_special_item: bool = false
@export var item_sprite: Texture2D

@export_category("Quest Rewards")
@export var reward_money: Vector2i
@export var reward_bond: Vector2i
@export var reward_items: Array[Items]
@export var reward_weapons: Array[weapon]
@export var reward_equipment: Array[equipment]
