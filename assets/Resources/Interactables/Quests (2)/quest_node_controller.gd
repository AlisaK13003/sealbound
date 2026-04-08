extends Control

@onready var quest_name_label = $VBoxContainer/QuestName

@onready var quest_gold_reward_label = $"Quest Rewards/Quest_Gold"
@onready var quest_bond_reward_label = $"Quest Rewards/Quest_Bond"
@onready var quest_giver_label = $VBoxContainer/QuestGiver
@onready var quest_location_label = $VBoxContainer/QuestLocation
@onready var accepted_image = $Am_I_Accepted

var what_quest_am_i
var index

var am_i_accepted: bool

signal on_click(quest_, quest_index)

func setup_(quest_: quests, i):
	quest_name_label.text = quest_.quest_name
	quest_giver_label.text = quest_.quest_giver
	quest_location_label.text = quest_.quest_location_descriptor
	
	what_quest_am_i = quest_
	index = i
	# Will be adjusted
	quest_gold_reward_label.text = str(clamp(quest_.quest_rewards.coin_drop_range[0] * (quest_.quest_difficulty), quest_.quest_rewards.coin_drop_range[0], quest_.quest_rewards.coin_drop_range[1]))
	quest_bond_reward_label.text = str(clamp(quest_.quest_rewards.bond_drop_range[0] * quest_.quest_difficulty, quest_.quest_rewards.bond_drop_range[0], quest_.quest_rewards.bond_drop_range[1]))

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not am_i_accepted: 
		am_i_accepted = true
		accepted_image.visible = true
		on_click.emit(what_quest_am_i, index)
