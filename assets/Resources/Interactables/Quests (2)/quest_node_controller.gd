extends Control

@onready var quest_name_label = $VBoxContainer/QuestName

@onready var quest_gold_reward_label = $"Quest Rewards/Quest_Gold"
@onready var quest_bond_reward_label = $"Quest Rewards/Quest_Bond"
@onready var quest_location_label = $VBoxContainer/QuestLocation

@onready var completion_requirements = $GridContainer

var what_quest_am_i: quest
var index

var am_i_accepted: bool

signal on_click()

func _ready():
	GlobalCombatInformation.check_quest_progress.connect(check_quest_progress)
	check_quest_progress()

func check_quest_progress():
	if what_quest_am_i == null:
		return
	for child in completion_requirements.get_children():
		child.queue_free()
		
	var can_turn_in_quest: bool = true
	for goal in what_quest_am_i.completion_requirements.keys():
		var new_node = load("res://assets/Resources/Pause Menu/Quest Menu/Completion_Node.tscn")
		var new_instance = new_node.instantiate()
		new_instance._setup(goal, what_quest_am_i.completion_requirements)
		completion_requirements.add_child(new_instance)

	if what_quest_am_i.should_spawn_dungeon_room and not what_quest_am_i.does_player_have_special_item:
		can_turn_in_quest = false
	
	if can_turn_in_quest:
		$Button.visible = true
		$Background/NinePatchRect3.visible = true
	else:
		$Button.visible = false
		$Background/NinePatchRect3.visible = false

func highlight(should_highlight):
	if should_highlight:
		$Background/NinePatchRect.modulate = Color.AQUAMARINE
		$Button.visible = true
		$Background/NinePatchRect3.visible = true
		$Background/NinePatchRect4.visible = true
	else:
		$Background/NinePatchRect.modulate = Color.WHITE
		$Button.visible = false
		$Background/NinePatchRect3.visible = false
		$Background/NinePatchRect4.visible = false

func was_hovered():
	return

func setup_(quest_: quest, i):
	quest_name_label.text = quest_.quest_name + " -" + quest_.quest_giver
	quest_location_label.text = quest_.quest_description
	
	what_quest_am_i = quest_
	index = i
	# Will be adjusted
	quest_gold_reward_label.text = str(quest_.reward_money) + "g"
	quest_bond_reward_label.text = str(quest_.reward_bond) + "b"
	check_quest_progress()

func _on_button_pressed():
	print("ACCEPTED QUEST")
	StateManager.set_quest_take(what_quest_am_i.tavern_state_to_set)
	GlobalCombatInformation.add_quest(what_quest_am_i.get_path_custom())
	on_click.emit()
	self.queue_free()
