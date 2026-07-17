extends Control

@onready var portrait = $HBoxContainer/TextureRect
@onready var member_name = $HBoxContainer/VBoxContainer/HBoxContainer/Name
@onready var total_exp = $HBoxContainer/VBoxContainer/HBoxContainer/Total_EXP
@onready var current_level = $HBoxContainer/VBoxContainer/HBoxContainer2/Current_Level
@onready var points_to_next_level = $HBoxContainer/VBoxContainer/HBoxContainer2/Points_to_next_level
@onready var bond = $HBoxContainer/VBoxContainer/HBoxContainer3/Bond_Level

func _setup(active_member: generic_combatants):
	if active_member == null:
		return
	portrait.texture = active_member.party_member_portrait.get_frame_texture(0)
	member_name.text = active_member.combatant_name
	total_exp.text = str(active_member.total_experience_points)
	if active_member.combatant_stats == null:
		current_level.text = "1"
		points_to_next_level.text = "0"
		return
	if active_member.actual_stats == null:
		active_member.gather_actual_stats()
	current_level.text = str(active_member.combatant_stats.level)
	points_to_next_level.text = str(active_member.add_experience(0))
