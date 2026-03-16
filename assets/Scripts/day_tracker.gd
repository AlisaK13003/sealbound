extends Label

var current_time_minutes: int
var current_time_hours: int = 6

@onready var clock_label: Label = self

# false is am and true is pm
var am_or_pm: bool = false

func _ready():
	Global.time_updated.connect(update_time)

func update_time(day_advanced):
	if day_advanced:
		current_time_minutes = 0
		current_time_hours = 6
	else:
		current_time_minutes += 5
		if current_time_minutes >= 60:
			current_time_hours += 1
			current_time_minutes -= 60
		
		if current_time_hours % 12 == 1:
			am_or_pm = true
		elif am_or_pm and current_time_hours % 12 == 0:
			Global.player_advanced_day(true)
			am_or_pm = false
	
	var clock_label_text = str(Global.current_day) + " day " + str(Global.current_year) + " year\n" + ("%02d" % (12 if current_time_hours % 12 == 0 else (current_time_hours % 12))) + ":" + ("%02d" % current_time_minutes)
	clock_label.text = clock_label_text
