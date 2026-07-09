extends Control

var texture_rec: TextureRect

func _setup(texture_for_texture):
	texture_rec = $TextureRect
	texture_rec.texture = texture_for_texture

	$Vertical.play("default")
	$Horizontal.play("default")

func update_highlight(highlight):
	if highlight:
		if get_parent().columns == 1:
			$Vertical.visible = true
			$Horizontal.visible = false
		else:
			$Vertical.visible = false
			$Horizontal.visible = true
	else:
		$Horizontal.visible = false
		$Vertical.visible = false
