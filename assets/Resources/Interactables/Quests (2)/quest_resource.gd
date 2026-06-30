extends Resource

class_name quests

@export var quest_name: String
@export var quest_giver: String
@export var quest_description: String
@export var quest_difficulty: int

@export var needs_to_spawn_quest_room: bool = false

# Pass in an enemy and a number to have it require you to gather that many enemy quest_drops 
# Pass in an standard item and a amount and that will be dropped from a chest
# Pass in a special item and a special room will spawn for it

@export var quest_completion_requirements: Dictionary = {}
@export var quest_rewards: drop_tables
@export var quest_location: GlobalCombatInformation.dungeon_types_names
@export var quest_location_descriptor: String

var quest_completed: bool = false
