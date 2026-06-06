extends CanvasLayer

@onready var fade_thing = $TextureRect
var is_fading : bool
@onready var gradient: Gradient = fade_thing.texture.gradient
@onready var grad_tex: GradientTexture2D = fade_thing.texture

@onready var fade_thing_2 = $ColorRect

var use_gradient: bool = false

func _ready():

	if not use_gradient:
		fade_thing.visible = false
		fade_thing_2.visible = true
	else:
		fade_thing.visible = true
		fade_thing_2.visible = false
	return
	await fade_in(2)

	await fade_out(0.5)

func change_scene(target_path: String):
	get_tree().change_scene_to_file(target_path)

	await get_tree().process_frame
	await get_tree().process_frame

	var new_scene: Node = get_tree().current_scene
	return new_scene


func fade_in(duration: float):
	if is_fading:
		return
	is_fading = true
	
	if use_gradient:
		fade_thing.texture = fade_thing.texture.duplicate()
		grad_tex = fade_thing.texture
		
		grad_tex.fill_from = Vector2(-1.0, 0.0)
		grad_tex.fill_to = Vector2(0.0, 0.0)
		
		fade_thing.visible = true
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(grad_tex, "fill_from", Vector2(1.0, 0.0), duration)
		tween.tween_property(grad_tex, "fill_to", Vector2(2.0, 0.0), duration)
		
		await tween.finished
	else:
		fade_thing_2.visible = true
		var tween = create_tween()
		tween.tween_property(fade_thing_2, "modulate:a", 1.0, duration)
		await tween.finished
	is_fading = false

func fade_out(duration: float):
	if is_fading:
		return
	is_fading = true
	
	if use_gradient:
		var tween = create_tween().set_parallel(true)
		
		tween.tween_property(grad_tex, "fill_from", Vector2(-1.0, 0.0), duration)
		tween.tween_property(grad_tex, "fill_to", Vector2(0.0, 0.0), duration)
		
		await tween.finished
		fade_thing.visible = false
	else:
		var tween = create_tween()
		tween.tween_property(fade_thing_2, "modulate:a", 0.0, duration)
		await tween.finished
		fade_thing_2.visible = false


	is_fading = false
