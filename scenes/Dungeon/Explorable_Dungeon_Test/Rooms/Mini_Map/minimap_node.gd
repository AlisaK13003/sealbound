extends Control


@onready var main_room_texture = $Mini_Map_Icon
@onready var something_special_in_room = $Special_Thing

var main_room_text: Texture2D
var special_text: Texture2D

func _ready():
	main_room_texture.texture = main_room_text
	
	if special_text != null and something_special_in_room != null:
		something_special_in_room.texture = special_text

func _setup(base_texture, special_texture):
	main_room_text = base_texture
	special_text = special_texture

func _change_texture(new_texture, special_texture = null):
	main_room_texture.texture = new_texture
	something_special_in_room.texture = special_texture
