extends Resource

class_name generic_combatants

@export var combatant_name: String
@export var party_member_portrait: Texture2D
@export var combatant_sprite: Texture2D
@export var combatant_stats: stats
@export var is_combatant_enemy: bool
var is_dead: bool
@export var stored_weapon : weapon
@export var stored_equipment : equipment

@export var combatant_skills : Array[moves]

@export var sprite_frames: SpriteFrames
@export var idle_speed: float
@export var death_speed: float
@export var walk_speed: float
@export var attack_speed: Array[float]
