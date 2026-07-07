extends Control

var item_name
var item_sprite

var what_am_i

signal item_clicked

func change_color(new_color):
	if not is_node_ready():
		await ready
	
func _setup(thing):
	item_name = $Label
	item_sprite = $TextureRect
	
	if thing is Items:
		item_name.text = thing.item_name
		item_sprite.texture = thing.item_sprite
		what_am_i = thing

func swap_orientation(should_flip):
	var new_sb = StyleBoxFlat.new()
	if should_flip:
		new_sb.skew = Vector2(0.1, 0.0)
	else:
		new_sb.skew = Vector2(-0.1, 0.0)
	$Panel.add_theme_stylebox_override("panel", new_sb)

func is_selected(selected):
	if selected:
		$TextureRect2.visible = true
	else:
		$TextureRect2.visible = false


func _on_gui_input(event):
	item_clicked.emit(self.get_instance_id())
