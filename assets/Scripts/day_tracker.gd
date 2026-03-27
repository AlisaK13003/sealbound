extends Label

@onready var clock_label: Label = self

func _ready():
	Global.time_updated.connect(update_time)

func update_time():
	var clock_label_text = str(Global.current_day) + " day " + str(Global.current_year) + " year\n" + ("%02d" % (12 if Global.current_hour % 12 == 0 else (Global.current_hour % 12))) + ":" + ("%02d" % Global.current_minute)
	clock_label.text = clock_label_text
