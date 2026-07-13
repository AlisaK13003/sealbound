extends Control

class_name player_portraits

@onready var cur_health_num = $HBoxContainer/Health_Num
@onready var max_health_num = $HBoxContainer/Health_Num3
@onready var party_portrait = $Portrait
#@onready var portrait_name = $VBoxContainer/Name
@onready var portrait_status = $Statuses
@onready var health_bar = $TextureProgressBar

var person_max_health = 0
var current_health = 0

var person_frames
var inflicted_with_status: bool = false

func _setup(person_to_setup: generic_combatants):
	person_max_health = int(person_to_setup.actual_stats.max_health)
	current_health = int(person_to_setup.actual_stats.health)
	cur_health_num.text = str(current_health)
	max_health_num.text = str(person_max_health)
	health_bar.max_value = person_max_health
	health_bar.value = current_health
	var health_percentage = float(current_health) / person_max_health
	person_frames = person_to_setup.party_member_portrait
	
	if not inflicted_with_status:
		if health_percentage > 0.5:
			party_portrait.texture = person_frames.get_frame_texture(0)
		else:
			party_portrait.texture = person_frames.get_frame_texture(2)
	
	#portrait_name.text = person_to_setup.combatant_name
	
func _update_health(health_value):
	health_value *= -1
	current_health = clamp(current_health + health_value, 0, person_max_health)
	cur_health_num.text = str(current_health)
	health_bar.value = current_health
	var health_percentage = float(current_health) / person_max_health

	if not inflicted_with_status:
		if health_percentage > 0.5:
			party_portrait.texture = person_frames.get_frame_texture(0)
		else:
			party_portrait.texture = person_frames.get_frame_texture(2)

func update_statuses(person_to_do_it_for: combat_template):
	reset_ui()
	
	var count = 0
	for status_ in person_to_do_it_for.active_statuses:
		inflicted_with_status = true
		match status_.status_name:
			"Stun":
				portrait_status.get_child(0).visible = true
				self.modulate = Color.DIM_GRAY
				count += 1	
			"Sleep":
				portrait_status.get_child(1).visible = true
				self.modulate = Color.GAINSBORO
				count += 1
			"Shock":
				portrait_status.get_child(2).visible = true
				self.modulate = Color.YELLOW
				count += 1
			"Poison":
				portrait_status.get_child(3).visible = true
				self.modulate = Color.PURPLE
				count += 1
			"Freeze":
				portrait_status.get_child(4).visible = true
				self.modulate = Color.LIGHT_SKY_BLUE
				count += 1
			"Burn":
				portrait_status.get_child(5).visible = true
				self.modulate = Color.FIREBRICK
				count += 1
	if count == 0:
		party_portrait.texture = person_frames.get_frame_texture(1)
		self.modulate = Color.WHITE

func reset_ui():
	for status_ in portrait_status.get_children():
		status_.visible = false
