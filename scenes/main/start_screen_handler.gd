extends Node

func _on_button_pressed():
	Global.current_region = "Buildings_Insides"
	Global.current_loading_zone = "Bedroom"
	print("HELLO")
	AreaStateManager.swap_scene(self)
