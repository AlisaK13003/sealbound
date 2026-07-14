extends CanvasModulate
class_name DayNightController

@export var day_color: Color      = Color(1.0, 1.0, 1.0)        # noon
@export var dawn_color: Color     = Color(1.0, 0.86, 0.72)      # 6am, warm
@export var dusk_color: Color     = Color(0.95, 0.68, 0.52)     # 18:00, orange
@export var night_color: Color    = Color(0.28, 0.32, 0.55)     # deep blue
@export var tween_time: float     = 1.0

var _tween: Tween

func _ready() -> void:
	Global.time_updated.connect(_on_time_updated)
	color = _color_for_time(Global.current_hour, Global.current_minute)  # no pop on load

func _on_time_updated() -> void:
	var target := _color_for_time(Global.current_hour, Global.current_minute)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "color", target, tween_time)

func _color_for_time(hour: int, minute: int) -> Color:
	var t := float(hour) + (float(minute) / 60.0)

	if t < 5.0:                          # 0:00–5:00  night
		return night_color
	elif t < 7.0:                        # 5:00–7:00  night -> dawn
		return night_color.lerp(dawn_color, (t - 5.0) / 2.0)
	elif t < 11.0:                       # 7:00–11:00 dawn -> day
		return dawn_color.lerp(day_color, (t - 7.0) / 4.0)
	elif t < 17.0:                       # 11:00–17:00 full day
		return day_color
	elif t < 19.0:                       # 17:00–19:00 day -> dusk
		return day_color.lerp(dusk_color, (t - 17.0) / 2.0)
	elif t < 21.0:                       # 19:00–21:00 dusk -> night
		return dusk_color.lerp(night_color, (t - 19.0) / 2.0)
	else:                                # 21:00–24:00 night
		return night_color
