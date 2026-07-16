extends Control

@onready var stored_quests_list = $Panel/GridContainer
var quest_node = preload("res://assets/Resources/Interactables/Quests (2)/quest_node.tscn")

@onready var scroll_bar = $VScrollBar
@export var parent: Node2D

var can_scroll

var start_range = 0
var end_range = 3
var selected_index = 0

var scroll_value = 1

func _ready():
	for i in range(parent.stored_quests_.size()):
		var temp_child = quest_node.instantiate()
		stored_quests_list.add_child(temp_child)
		temp_child.setup_(parent.stored_quests_[i], i)
		temp_child.on_click.connect(quest_clicked)
		if i > end_range:
			temp_child.visible = false
	$Panel._setup()

func quest_clicked(what_quest_was_clicked, quest_index):
	print("The quest that was clicked is at index: ", quest_index)
	# stored_quests_list.get_child(quest_index).visible = false
	stored_quests_list.get_child(quest_index).am_i_accepted = true
	#GlobalCombatInformation.active_quests.append(what_quest_was_clicked)
	GlobalCombatInformation.add_quest(what_quest_was_clicked)
