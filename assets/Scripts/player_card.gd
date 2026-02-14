extends Control

@onready var name_label = %Party_Name
@onready var skill_container = %Skill_Cards
@onready var party_sprite = %Party_Sprite

func setup(member_data: PartyMember, cur_party: int):
	name_label.text = member_data.member_name
	party_sprite = member_data.player_sprite
	print("asdf")
	for j in range(member_data.move_list.size()):
		print("asdf")
		skill_container.get_child(j).get_node("Label").text = member_data.move_list[j].move_name
		skill_container.get_child(j).get_node("Area2D").input_event.connect(player_select_move.bind(cur_party, j))

func player_select_move(viewport, event, shape_idx, cur_party: int, selected_move: int):
	if event is InputEventMouseButton and event.pressed:
		print(str(cur_party) + " selected " + str(selected_move))
