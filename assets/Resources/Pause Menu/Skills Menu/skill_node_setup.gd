extends Control

signal skill_clicked

var is_selected: bool = false

func _setup(move: moves):
	$HBoxContainer/TextureRect.texture = move.move_sprite
	if move.move_sprite == null:
		$HBoxContainer/TextureRect.texture = load("res://assets/tile sheets/Move Sprites/Crowd_Breaker.png")
	$HBoxContainer/Label.text = move.move_name
	$HBoxContainer/Label2.text = str(move.mana_cost) + " BP"
	$AnimatedSprite2D.play("default")



func update_selection(selected):
	if selected:
		$AnimatedSprite2D.visible = true
		is_selected = true
	else:
		$AnimatedSprite2D.visible = false
		is_selected = false


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			update_selection(true)
			skill_clicked.emit(self.get_instance_id())
