extends Control

@onready var name_label = %Party_Name
@onready var skill_container = %Skill_Cards
@onready var party_sprite = %Party_Sprite
var belongs_to_party_num : int 
var has_acted : bool = false

var selected_move:
	set(value):
		selected_move = value
		move_selected.emit()
		
signal move_selected(value, party_num)

func setup(member_data: PartyMember, cur_party: int):
	name_label.text = member_data.member_name
	party_sprite = member_data.player_sprite
	belongs_to_party_num = cur_party
	for j in range(member_data.move_list.size()):
		skill_container.get_child(j).get_node("Label").text = member_data.move_list[j].move_name
		skill_container.get_child(j).get_node("Area2D").input_event.connect(player_select_move.bind(cur_party, j))

func player_select_move(viewport, event, shape_idx, cur_party: int, _selected_move: int):
	if event is InputEventMouseButton and event.pressed and not has_acted:
		if selected_move == _selected_move:
			selected_move = null
		else:
			selected_move = _selected_move
