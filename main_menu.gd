extends Node2D

const START_SCENE_PATH := "res://scenes/main/Hearthwynn.tscn"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_credits_pressed() -> void:
	pass


func _on_settings_pressed() -> void:
	pass


func _on_continue_pressed() -> void:
	pass

func _on_new_game_pressed() -> void:
	if Fade.is_fading:
		return

	if has_node("Button_manager"):
		$Button_manager.visible = false

	Fade.transition_to_scene(START_SCENE_PATH)
