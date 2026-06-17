extends Control

@onready var quest_menu = $Quest_Menu

func _ready():
	quest_menu.activated.connect(_open_quest_menu)
	
func _open_quest_menu():
	print("QUEST MENU")
