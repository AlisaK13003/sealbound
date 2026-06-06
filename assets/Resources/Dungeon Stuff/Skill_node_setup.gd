extends Control

@onready var skill_name = $HBoxContainer/Container/HBoxContainer/Skill_Name
@onready var skill_texture = $HBoxContainer/Container/HBoxContainer/Skill_Texture
@onready var selection_arrow = $HBoxContainer/AnimatedSprite2D
@onready var mana_cost_label = $"HBoxContainer/Container/HBoxContainer/Mana Cost"

var p_ref
var s_num
var can_be_selected = true
var can_be_unselected = true
var held_skill: moves

func _setup(skill: moves, skill_num, parent_ref):
	p_ref = parent_ref
	s_num = skill_num
	held_skill = skill
	skill_name.text = skill.move_name
	skill_texture.texture = skill.normal_sprite
	mana_cost_label.text = str(skill.mana_cost)
	if p_ref.p_ref.current_bond_points < skill.mana_cost:
		can_be_selected = false
		self.modulate = Color.GRAY
	else:
		can_be_selected = true
	
func select():
	if not can_be_unselected:
		return
	can_be_selected = true
	p_ref.update_description(held_skill.move_description)
	selection_arrow.visible = true
	selection_arrow.play("default")
	p_ref.update_selected_child(s_num)
	
func unselect():
	can_be_selected = false
	selection_arrow.visible = false
	selection_arrow.stop()

func selection_confirmed():
	if can_be_selected:
		p_ref.p_ref.skill_selected(held_skill)

func execute_selection():
	if can_be_selected and self.modulate != Color.GRAY:
		p_ref.p_ref.confirmation.emit(true)
		p_ref.p_ref.gui.update_action_hints()
	
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_be_selected:
			selection_confirmed()
			p_ref.p_ref.gui.update_action_hints()
			
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			if self.modulate == Color.GRAY:
				print("RETURN")
				return
			p_ref.unselect_all()
			select()
			can_be_unselected = false
			
		NOTIFICATION_MOUSE_EXIT:
			if can_be_selected:
				can_be_unselected = true
