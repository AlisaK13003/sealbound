extends Control

func _setup(cur_dungeon_texture):
	$Panel/TextureRect.texture = cur_dungeon_texture

func highlight(hi):
	if hi:
		$TextureRect.visible = true
	else:
		$TextureRect.visible = false
