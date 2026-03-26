extends Resource

class_name npc_schedule

# Needs however many days this repeats, so 1-7 days
# Needs the hour and time it happens
# Needs the locations they go to

@export var what_are_they_doing: String
@export_range(1,7) var repeats_every_x_days: int = 1
@export_range(6, 24) var what_hour: int = 6
@export_range(0, 60, 5) var what_minute: int = 0

@export var start_location: Global.locations
@export var end_location: Global.locations
@export var weather_conditions: Global.weather
