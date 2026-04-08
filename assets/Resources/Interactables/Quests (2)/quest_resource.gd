extends Resource

class_name quests

@export var quest_name: String
@export var quest_giver: String
@export var quest_description: String
@export var quest_difficulty: int

@export var quest_completion_requirements: Dictionary = {}
@export var quest_rewards: drop_tables
@export var quest_location: Global.dungeon_location
@export var quest_location_descriptor: String
