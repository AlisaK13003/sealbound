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

@export_range(0, 1000, 1, "prefer_slider", "or_greater") var crit_chance: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var crit_damage: int

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

signal health_changed(new_value)
signal speed_changed(new_value)

func _init():
	altered_speed = speed

# Don't need to return actual stat values just yet since there are no planned items to permanently boost stats
# Can just alter stats in the experience function
# Like simulate level ups on boot
func export_to_JSON():
	return {
		"path": resource_path,
	}
