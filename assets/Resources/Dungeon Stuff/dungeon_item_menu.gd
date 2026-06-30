extends Control

@export var node_to_instantiate: String
@onready var item_container = $NinePatchRect3/MarginContainer/GridContainer
@onready var menu_name = $NinePatchRect/Label
@onready var description = $Panel3/Description_Label
var p_ref

var which_child_is_selected = -1
	
func drop_and_swing_in():
	self.visible = true
	pivot_offset = Vector2(size.x / 2, 0)
	position.x = -size.x
	rotation_degrees = -15.0
	
	var target_x = 200.0 
	
	var pos_tween = create_tween()
	pos_tween.tween_property(self, "position:x", target_x, 0.6)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	var rot_tween = create_tween()
	
	rot_tween.tween_property(self, "rotation_degrees", 20.0, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	rot_tween.tween_property(self, "rotation_degrees", -10.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	rot_tween.tween_property(self, "rotation_degrees", 4.0, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	rot_tween.tween_property(self, "rotation_degrees", 0.0, 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func _setup(items_to_setup, parent_reference, m_name):
	await clear_children()
	p_ref = parent_reference
	menu_name.text = m_name
	var list_item_scene = load(node_to_instantiate)

	var already_selected = false
	var index_difference = 0
	if items_to_setup[0] is Items:
		item_container.columns = 2
		item_container.add_theme_constant_override("v_separation", -11)
		item_container.add_theme_constant_override("h_separation", 40)

	for item in range(items_to_setup.size()):
		var item_to_create = items_to_setup[item]
		if item_to_create is moves:
			if not item_to_create.is_unlocked:
				index_difference += 1
				continue
		var new_item = list_item_scene.instantiate()
		item_container.add_child(new_item)
		
		
		await new_item._setup(items_to_setup[item], item - index_difference, self)
		if not already_selected and items_to_setup[item] is moves:
			if p_ref.current_bond_points >= items_to_setup[item].mana_cost:
				which_child_is_selected = 0
				already_selected = true
				new_item.select()
		elif item == 0:
			which_child_is_selected = 0
			new_item.select()

func clear_children():
	for child in item_container.get_children():
		item_container.remove_child(child)
		child.queue_free()

func update_selected_child(what_child_got_selected):
	which_child_is_selected = what_child_got_selected

func update_description(new_description):
	description.text = new_description

func update_selection(up_or_down):
	var child_to_check = item_container.get_child(which_child_is_selected)
	if child_to_check.can_be_unselected:
		var updated_index = (which_child_is_selected + up_or_down)
		var child_count = item_container.get_child_count() - 1
		var newly_selected_child = updated_index if updated_index < child_count and updated_index >= 0 else (0 if updated_index > child_count else child_count)
		if item_container.get_child(newly_selected_child).modulate != Color.GRAY:
			unselect_all()
			item_container.get_child(newly_selected_child).select()

func make_visible():
	self.visible = true
	unselect_all()
	var current_index: int = 0
	var highlighted_someone: bool = false
	for child in item_container.get_children():
		if child.visible and child.get_index() == current_index and not highlighted_someone:
			which_child_is_selected = 0
			highlighted_someone = true
		else:
			current_index += 1

func selection_confirmed():
	if item_container.get_child(which_child_is_selected).can_be_selected:
		item_container.get_child(which_child_is_selected).selection_confirmed()
		return true
	else:
		return false

func execute_selection():
	if which_child_is_selected != -1:
		item_container.get_child(which_child_is_selected).execute_selection()

func unselect_all():
	for child in item_container.get_children():
		child.unselect()
