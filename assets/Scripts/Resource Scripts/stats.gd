@tool
extends Resource
class_name stats

@export var level : int = 1
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var max_health: int = 0
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var health: int = 0: 
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health) 
# @export_range(0, 1000, 1, "prefer_slider", "or_greater") var max_magic_points: int = 0
# @export_range(0, 1000, 1, "prefer_slider", "or_greater") var magic_points: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var attack: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var defense: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var magic: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var resistance: int

@export_range(0, 100, 1, "prefer_slider", "or_greater") var crit_chance: int
@export_range(0, 2, 0.01, "prefer_slider", "or_greater") var crit_damage: float = 0.5

@export_range(0, 1000, 1, "prefer_slider", "or_greater") var speed: int:
	set(value):
		speed = clamp(value, 0, 10000)
		self.altered_speed = speed
var altered_speed: int:
	set(value):
		altered_speed = clamp(value, 0, 10000)
		speed_changed.emit(altered_speed)
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var luck: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var evasion: int

@export var growth_rates: Dictionary = {
	"max_health": 70,  
	"attack": 40,
	"defense": 30,
	"magic": 15,
	"resistance": 20,
	"speed": 45,
	"luck": 30,
	"evasion": 20,
	"crit_chance": 10,
	"crit_damage": 10
}

signal health_changed(new_value)
signal speed_changed(new_value)

func _init():
	altered_speed = speed

func export_to_JSON():
	return {
		"level": str(level),
		"max_health": str(max_health),  
		"attack": str(attack),
		"defense": str(defense),
		"magic": str(magic),
		"resistance": str(resistance),
		"speed": str(speed),
		"luck": str(luck),
		"evasion": str(evasion),
		"crit_chance": str(crit_chance),
		"crit_damage": str(crit_damage),
		"path": str(resource_path)
	}

func load_information(save_data):
	level = int(save_data.get("level", "0"))
	max_health = int(save_data.get("max_health", "0"))
	health = max_health
	attack = int(save_data.get("attack", "0"))
	defense = int(save_data.get("defense", "0"))
	magic = int(save_data.get("magic", "0"))
	resistance = int(save_data.get("resistance", "0"))
	speed = int(save_data.get("speed", "0"))
	luck = int(save_data.get("luck", "0"))
	evasion = int(save_data.get("evasion", "0"))
	crit_chance = int(save_data.get("crit_chance", "0"))
	crit_damage = int(save_data.get("crit_damage", "0"))

func add_stats(stats_to_combine_with: stats):
	var new_stats = stats.new()
	new_stats.max_health = stats_to_combine_with.max_health + max_health
	new_stats.health = stats_to_combine_with.health + health
	new_stats.attack = stats_to_combine_with.attack + attack
	new_stats.defense = stats_to_combine_with.defense + defense
	new_stats.resistance = stats_to_combine_with.resistance + resistance
	new_stats.crit_chance = stats_to_combine_with.crit_chance + crit_chance
	new_stats.crit_damage = stats_to_combine_with.crit_damage + crit_damage
	new_stats.speed = stats_to_combine_with.speed + speed
	new_stats.luck = stats_to_combine_with.luck + luck
	new_stats.evasion = stats_to_combine_with.evasion + evasion
	return new_stats
