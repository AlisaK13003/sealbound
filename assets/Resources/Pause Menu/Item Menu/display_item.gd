extends Control

var item_name
var item_sprite
var count

var what_am_i

signal item_clicked

func _setup(thing):
	item_name = $Label
	item_sprite = $TextureRect
	count = $HBoxContainer/Item_Count2
	
	if thing is Items:
		item_name.text = thing.item_name
		item_sprite.texture = thing.item_sprite
		count.text = str(thing.stack)
		what_am_i = thing
		
func highlight(selected):
	if selected:
		$TextureRect2.visible = true
		$Background/NinePatchRect.modulate = Color.BEIGE
	else:
		$TextureRect2.visible = false
		$Background/NinePatchRect.modulate = Color.WHITE

func was_hovered():
	pass

func _on_gui_input(event):
	return
	#item_clicked.emit(self.get_instance_id())
