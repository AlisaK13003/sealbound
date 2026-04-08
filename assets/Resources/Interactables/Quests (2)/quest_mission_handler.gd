extends Control

@onready var stored_quests_list = $VBoxContainer
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
	scroll_bar.max_value = (parent.stored_quests_.size())

func _on_area_2d_mouse_entered():
	can_scroll = true

func _on_area_2d_mouse_exited():
	can_scroll = false

func update_display(change_range_by, from_scroll):
	var loop_bounds = stored_quests_list.get_child_count()
	if selected_index == 0:
		start_range = 0
		end_range = clamp(end_range, start_range + 4, loop_bounds)

	start_range = clamp(start_range + change_range_by, 0, loop_bounds-4)
	end_range = clamp(end_range + change_range_by, start_range + 4, loop_bounds)
	selected_index = clamp(change_range_by + selected_index, 0, stored_quests_list.get_child_count())
	if not from_scroll:
		scroll_bar.value = clamp(selected_index, 0, scroll_bar.max_value)

	for i in range(stored_quests_list.get_child_count()):
		#if stored_quests_list.get_child(i).what_quest_am_i in Global.accepted_quest_list:
		#	continue
		if i >= start_range and i < end_range:
			stored_quests_list.get_child(i).visible = true
		else:
			stored_quests_list.get_child(i).visible = false

func _input(event):
	if can_scroll:
		if event.is_action_pressed("Mouse Scroll Down"):
			update_display(scroll_value, false)
		if event.is_action_pressed("Mouse Scroll Up"):
			update_display(-scroll_value, false)

func quest_clicked(what_quest_was_clicked, quest_index):
	print("The quest that was clicked is at index: ", quest_index)
	# stored_quests_list.get_child(quest_index).visible = false
	stored_quests_list.get_child(quest_index).am_i_accepted = true
	Global.accepted_quest_list.append(what_quest_was_clicked)
	update_display(0, false)

func _on_v_scroll_bar_scrolling():
	if scroll_bar.value > selected_index:
		update_display(scroll_value, true)
	else:
		update_display(-scroll_value, true)
