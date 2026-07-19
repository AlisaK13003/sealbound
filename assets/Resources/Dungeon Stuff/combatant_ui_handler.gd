extends Control

class_name combatant_ui

@onready var health_bar = $TextureProgressBar
@onready var status_container = $NinePatchRect/GridContainer
@onready var status_visible_container = $NinePatchRect
@onready var health_differential_label = $Health_Differential
@onready var status_timer_node = load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Status_Timer.tscn")
@onready var current_health_label = $TextureProgressBar/Label
@onready var animation_player = $AnimationPlayer

enum statuses {
	STUN = 1 << 0,
	SLEEP = 1 << 1,
	SHOCK = 1 << 2,
	POISON = 1 << 3,
	BURN = 1 << 4,
	FREEZE = 1 << 5,
	SLOW = 1 << 6,
	AGRO = 1 << 7,
	ATTACKdown = 1 << 8,
	DEFENSEdown = 1 << 9,
	EVASIONdown = 1 << 10,
	CRITCHANCEdown = 1 << 11,
	ACCURACYdown = 1 << 12,
	MOMENTUM = 1 << 13,
	REGEN = 1 << 14,
	STUNIMMUNITY = 1 << 15,
	ATTACKup = 1 << 16,
	DEFENSEup = 1 << 17,
	EVASIONup = 1 << 18,
	CRITCHANCEup = 1 << 19,
	ACCURACYup = 1 << 20,
}

@onready var status_color_chart: Dictionary = {
	statuses.STUN: Color.YELLOW,
	statuses.SLEEP: Color.DIM_GRAY,
	statuses.SHOCK: Color.YELLOW,
	statuses.POISON: Color.WEB_PURPLE,
	statuses.BURN: Color.ORANGE_RED,
	statuses.FREEZE: Color.LIGHT_CYAN,
	statuses.SLOW: 5,
	statuses.AGRO: Color.INDIAN_RED,
	statuses.ATTACKdown: Color.RED,
	statuses.DEFENSEdown: Color.BLUE,
	statuses.EVASIONdown: Color.YELLOW,
	statuses.CRITCHANCEdown: Color.GREEN,
	statuses.ACCURACYdown: Color.CADET_BLUE,
	statuses.MOMENTUM: 5,
	statuses.REGEN: 5,
	statuses.STUNIMMUNITY: 5,
	statuses.ATTACKup: Color.RED,
	statuses.DEFENSEup: Color.BLUE,
	statuses.EVASIONup: Color.YELLOW,
	statuses.CRITCHANCEup: Color.GREEN,
	statuses.ACCURACYup: Color.CADET_BLUE
}

var parent_reference

var hovered_over: bool = false

func setup(parent_ref, stored_combatant, all_active_effects):
	parent_reference = parent_ref
	remove_active_status(all_active_effects)
	health_bar.max_value = stored_combatant.combatant_stats.max_health
	health_bar.value = stored_combatant.combatant_stats.health
	current_health_label.text = str(int(health_bar.value))

func remove_active_status(status_to_remove):
	var status_found: bool
	for child in status_container.get_children():
		if child.get_meta("status_type") == status_to_remove:
			child.get_parent().remove_child(child)
			child.queue_free()
			await get_tree().process_frame
			update_grid_size()

func update_active_status(status_to_update: status):
	if status_to_update == null:
		return
	if status_to_update.status_type <= statuses.AGRO:
		return
	var child_found
	for child in status_container.get_children():
		if child.get_meta("status_type") == status_to_update.status_type:
			child_found = child
			break
			
	if child_found != null:
		child_found.get_node("Time_Left").text = str(status_to_update.remaining_turns)
	else:
		var new_child: Control = status_timer_node.instantiate()
		new_child.set_meta("status_type", status_to_update.status_type)
		new_child.get_node("Status_Indicator").modulate = Color(status_color_chart[status_to_update.status_type] * 10)

		status_container.add_child(new_child)
		if status_to_update.status_type > statuses.AGRO and status_to_update.status_type < statuses.MOMENTUM:
			new_child.get_node("Status_Indicator").flip_v = true
		elif status_to_update.status_type > statuses.STUNIMMUNITY:
			new_child.get_node("Status_Indicator").flip_v = false
	update_grid_size()

func update_grid_size():
	if status_container.get_child_count() >= 1:
		status_visible_container.visible = true
	else:
		status_visible_container.visible = false
	if status_container.get_child_count() <= 4:
		status_visible_container.custom_minimum_size = Vector2(15 + (13 * (status_container.get_child_count() - 1)), 29)
	else:
		status_visible_container.custom_minimum_size = Vector2(54, 29 + (9 * ((status_container.get_child_count() / 4 if status_container.get_child_count() & 4 == 0 else ceili(float(status_container.get_child_count()) / 4))) - 1))
	
func update_damage_label(health_differential, type_of_damage):
	animation_player.play("Take_Damage")
	match type_of_damage:
		"BP":
			health_differential_label.modulate = Color.PALE_VIOLET_RED
		"HEAL":
			health_differential_label.modulate = Color.LAWN_GREEN
		"MISS":
			health_differential_label.modulate = Color.MAGENTA
			health_differential_label.text = "MISS"
		"STATUS":
			health_differential_label.modulate = Color.WEB_PURPLE
		"CRIT":
			health_differential_label.modulate = Color.RED
			health_differential_label.text = "CRIT"
			if not parent_reference.training:	
				await get_tree().create_timer(0.5).timeout
		"DAMAGE":
			health_differential_label.modulate = Color.WHITE_SMOKE
	var previous_y_level =	health_differential_label.position.y
	health_differential_label.visible = true
	if type_of_damage != "MISS":
		health_differential_label.text = str(int(health_differential if health_differential > 0 else -1 * health_differential))
	health_bar.value -= health_differential
	current_health_label.text = str(int(health_bar.value))
	
	var tween = create_tween()
	
	tween.tween_property(health_differential_label, "position", Vector2(health_differential_label.position.x, previous_y_level - 20.0), 0.3)
	
	await tween.finished

	await get_tree().create_timer(0.1).timeout

	tween = create_tween()
	tween.tween_property(health_differential_label, "position", Vector2(health_differential_label.position.x, previous_y_level + 10.0), 0.6)
	await tween.finished
	health_differential_label.visible = false
	health_differential_label.position.y = previous_y_level
	health_differential_label.modulate = Color.WHITE_SMOKE
	await get_tree().create_timer(0.5).timeout

func play_use_item_animation(which_item: Items):
	$Sprite2D.texture = which_item.item_sprite
	$AnimationPlayer.play("Use_Item")
	print("PLAYING ANIMATION")
