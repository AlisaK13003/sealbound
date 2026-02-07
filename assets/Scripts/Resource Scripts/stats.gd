extends Resource
class_name stats

@export_range(0, 1000, 1, "prefer_slider", "or_greater") var max_health: int = 0
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var health: int = 0: 
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health) 
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var max_magic_points: int = 0
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var magic_points: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var strength: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var defense: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var speed: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var altered_speed: int = speed
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var luck: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var evasion: int
@export_range(0, 1000, 1, "prefer_slider", "or_greater") var magic: int

signal health_changed(new_value)
signal speed_changed(new_value)
