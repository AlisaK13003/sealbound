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
	visibility_changed.connect(_setup)
	
func _setup():
	StateManager.add_quests_to_board()
	for thing in stored_quests_list.get_children():
		thing.queue_free()
	
	for i in range(StateManager.currently_available_quests.size()):
		var index = GlobalCombatInformation.active_quests.find_custom(func(quest_: quest): return StateManager.currently_available_quests[i].quest_name == quest_.quest_name)
		if index == -1:
			var temp_child = quest_node.instantiate()
			stored_quests_list.add_child(temp_child)
			temp_child.setup_(StateManager.currently_available_quests[i], i)
			temp_child.on_click.connect(quest_clicked)
			if i > end_range:
				temp_child.visible = false
	$Panel._setup()
	$Panel.current_item = 0
	$Panel.update_selected_item()
	
func quest_clicked():
	_setup()
