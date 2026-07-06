extends Control

var texture_rec: TextureRect
var selection_arrow: TextureRect

func _setup(texture_for_texture):
	texture_rec = $HBoxContainer/TextureRect
	texture_rec.texture = texture_for_texture

	selection_arrow = $HBoxContainer/TextureRect2
	selection_arrow.visible = false

func update_highlight(highlight):
	if highlight:
		selection_arrow.visible = true
	else:
		selection_arrow.visible = false
