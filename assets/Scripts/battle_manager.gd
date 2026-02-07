extends Node

# majority of values will be replaced later on with stuff from the global script
# hard coded for now to make it easier to test
@export var party : Node2D
var party_member_1 : CollisionShape2D
var party_member_2 : CollisionShape2D
var party_member_3 : CollisionShape2D

var number = [0, 1, 2, 3, 4, 5, 6, 7, 8]

@export var current_encounter : encounters

# Will be set up by global later on
@export var party_1 : PartyMember
@export var party_2 : PartyMember
@export var party_3 : PartyMember

@export var party_1_label : VBoxContainer
@export var party_2_label : VBoxContainer
@export var party_3_label : VBoxContainer

@export var enemy_list : Array[Node2D]

var turn_orders : Array[TurnStorage] = []

func _update_ui(current_health: int, party_member: int):
	match party_member:
		0:
			party_1_label.get_node("HBoxContainer").get_child(1).text = str(current_health) + " / " + str(party_1.player_stats.max_health)
		1:
			party_2_label.get_node("HBoxContainer").get_child(1).text = str(current_health) + " / " + str(party_2.player_stats.max_health)
		2:
			party_3_label.get_node("HBoxContainer").get_child(1).text = str(current_health) + " / " + str(party_3.player_stats.max_health)

# Given current encounter / party arrangement assign the appropriate sprites and hide the color_rect on the combat_templates
func _ready():
	number.shuffle()
	party_1_label.get_child(0).text = party_1.member_name
	party_2_label.get_child(0).text = party_2.member_name
	party_3_label.get_child(0).text = party_3.member_name

	party_1.player_stats.health_changed.connect(_update_ui.bind(0))
	party_2.player_stats.health_changed.connect(_update_ui.bind(1))
	party_3.player_stats.health_changed.connect(_update_ui.bind(2))
	
	party_1.player_stats.speed_changed.connect(turn_priority)
	party_2.player_stats.speed_changed.connect(turn_priority)
	party_3.player_stats.speed_changed.connect(turn_priority)

	_update_ui(party_1.player_stats.health, 0)
	_update_ui(party_2.player_stats.health, 1)
	_update_ui(party_3.player_stats.health, 2)

	Global.party_slot_1 = party_1
	Global.party_slot_2 = party_2
	Global.party_slot_3 = party_3
	
	party.get_child(0).get_node("Party_Member_1").texture = party_1.player_sprite
	party.get_child(1).get_node("Party_Member_2").texture = party_2.player_sprite
	party.get_child(2).get_node("Party_Member_3").texture = party_3.player_sprite
	
	for i in range(enemy_list.size()):
		if current_encounter.enemy_list.size() > i:
			enemy_list[number[i]].get_node("Sprite2D").texture = current_encounter.enemy_list.get(i).enemy_sprite
			current_encounter.enemy_list.get(i).enemy_position = i
		enemy_list[number[i]].get_node("ColorRect").visible = false
		
	turn_orders.append(TurnStorage.new(party_1, party_1.player_stats.altered_speed))
	turn_orders.append(TurnStorage.new(party_2, party_2.player_stats.altered_speed))
	turn_orders.append(TurnStorage.new(party_3, party_3.player_stats.altered_speed))
	
	for enemy in current_encounter.enemy_list:
		turn_orders.append(TurnStorage.new(enemy, enemy.enemy_stats.altered_speed))
	
	turn_priority()
	take_turn()

class TurnStorage:
	var combatant
	var speed : int
	func _init(_combatant, _speed: int):
		combatant = _combatant
		speed = _speed

func turn_priority():
	turn_orders.sort_custom(func(a, b):
		return a.speed > b.speed
	)

# executes turns in order of speed
func take_turn():
	var thing
	for i in range(turn_orders.size()):
		thing = turn_orders.get(i).combatant
		if thing is PartyMember:
			player_turn(thing.current_battle_position)
		if thing is EnemyCombatant:
			enemy_turn(thing.enemy_position)
	
func player_turn(cur_player: int):
	match cur_player:
		0:
			print(party_1.member_name)	
		1:
			print(party_2.member_name)	
		2:
			print(party_3.member_name)	

func enemy_turn(cur_enemy: int):
	print(current_encounter.enemy_list.get(cur_enemy).enemy_name)
	
func _on_button_button_down():
	party_1.player_stats.health -= 1
	party_2.player_stats.health -= 1
	party_3.player_stats.health -= 1

func _on_button_2_button_down():
	party_1.player_stats.health += 1
	party_2.player_stats.health += 1
	party_3.player_stats.health += 1
