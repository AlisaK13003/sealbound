extends Resource

class_name quest

@export var quest_name: String
@export var quest_giver: String
@export var quest_description: String
@export var quest_location: Global.locations
@export var difficult_level : int

@export var unlock_seal_requirement: Array[Global.Progression_Flags]

# Will be filled in when bond is sorted
@export var unlock_bond_requirements: int

@export var completion_requirements: Array[quest_item]

@export var reward_money: int
@export var reward_items: Array[Items]
@export var reward_weapons: Array[weapon]
@export var reward_equipment: Array[equipment]
