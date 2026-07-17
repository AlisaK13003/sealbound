extends Label

@onready var clock_label: Label = self

func _ready() -> void:
	if not Global.time_updated.is_connected(update_time):
		Global.time_updated.connect(update_time)
	update_time()

func update_time() -> void:
	clock_label.text = "%s\n%s" % [_format_date(), _format_time()]

func _format_date() -> String:
	return "Day %d, Year %d" % [Global.current_day + 1, Global.current_year + 1]

func _format_time() -> String:
	var display_hour := Global.current_hour % 12
	if display_hour == 0:
		display_hour = 12
	var period := "AM" if Global.current_hour < 12 else "PM"
	return "%d:%02d %s" % [display_hour, Global.current_minute, period]
