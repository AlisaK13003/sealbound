extends Control

@onready var stored_quests_list = $VBoxContainer
var quest_node = preload("res://assets/Resources/Interactables/Quests (2)/quest_node.tscn")

@export var parent: Node2D

func _ready():
	for quest_ in parent.stored_quests_:
		var temp_child = quest_node.instantiate()
		stored_quests_list.add_child(temp_child)
		temp_child.setup_(quest_)
	pass
