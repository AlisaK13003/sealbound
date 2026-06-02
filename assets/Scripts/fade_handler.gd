extends CanvasLayer

@onready var fade_thing = $Panel
var is_fading : bool

var duration = 2

func change_scene(target_path: String, _duration: float = 2):
	get_tree().change_scene_to_file(target_path)

	await get_tree().process_frame
	await get_tree().process_frame

	var new_scene: Node = get_tree().current_scene
	return new_scene

func fade_in():
	is_fading = true
	for i in range(25):
		fade_thing.get_theme_stylebox("panel").bg_color = Color("Black", i * 0.04)
		await get_tree().create_timer(0.05).timeout
	fade_thing.get_theme_stylebox("panel").bg_color = Color("Black", 1)

func fade_out():
	for i in range(25):
		fade_thing.get_theme_stylebox("panel").bg_color = Color("Black", 1 - (i * 0.04))
		await get_tree().create_timer(0.05).timeout
