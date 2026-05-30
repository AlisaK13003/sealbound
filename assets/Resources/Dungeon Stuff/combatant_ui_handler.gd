extends Control

class_name combatant_ui

@onready var health_bar = $TextureProgressBar
@onready var status_container = $NinePatchRect/GridContainer
@onready var status_visible_container = $NinePatchRect
@onready var status_timer_node = load("res://assets/Resources/Dungeon Stuff/Dungeon_resources/Status_Timer.tscn")

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

func setup(parent_ref):
	parent_reference = parent_ref

func remove_active_status(status_to_remove):
	var status_found: bool
	for child in status_container.get_children():
		if child.get_meta("status_type") == status_to_remove:
			child.queue_free()
			update_grid_size()
			return

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
	if status_container.get_child_count() < 4:
		status_visible_container.custom_minimum_size = Vector2(15 + (13 * (status_container.get_child_count() - 1)), 29)
	else:
		status_visible_container.custom_minimum_size = Vector2(54, 29 + ((status_container.get_child_count() / 4) if status_container.get_child_count() % 4 == 0 else status_container.get_child_count() % 4))

	
	
