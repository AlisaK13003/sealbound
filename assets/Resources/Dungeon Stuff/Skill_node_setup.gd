extends Control

@onready var skill_name = $HBoxContainer/Container/Skill_Name
@onready var skill_texture = $HBoxContainer/Container/Skill_Texture
@onready var mana_cost = $HBoxContainer/Container/Control/Mana_Cost
@onready var selection_arrow = $HBoxContainer/AnimatedSprite2D
@onready var disabled = $ColorRect

var p_ref
var s_num
var can_be_selected
var can_be_unselected = true
var held_skill: moves

func _setup(skill: moves, skill_num, parent_ref):
	p_ref = parent_ref
	s_num = skill_num
	held_skill = skill
	skill_name.text = skill.move_name
	skill_texture.texture = skill.normal_sprite
	if p_ref.p_ref.mana < skill.mana_cost:
		disabled.visible = true
	for mana in range(skill.mana_cost):
		mana_cost.get_child(mana).visible = true
			
func _on_panel_mouse_entered():
	if disabled.visible:
		return
	p_ref.unselect_all()
	select()

	can_be_unselected = false
	
func _on_panel_mouse_exited():
	can_be_unselected = true

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
	p_ref.p_ref.skill_selected(held_skill)

func execute_selection():
	p_ref.p_ref.confirmation.emit(true)
	
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selection_confirmed()
			
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			p_ref.unselect_all()
			select()
			can_be_unselected = false
			
		NOTIFICATION_MOUSE_EXIT:
			can_be_unselected = true
