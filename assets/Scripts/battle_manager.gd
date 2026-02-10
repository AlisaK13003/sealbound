extends Node

# Global Variables / signals
# --------------------------------------------------------------------------------

@export var party_members : Array[PartyMember]
var party_nodes : Array[CollisionShape2D]
@export var party_labels : Array[VBoxContainer]

var number = [0, 1, 2, 3, 4, 5, 6, 7, 8]

var battle_state = {
	"is_dragging": false,
	"selected_target": null,
	"hovered_enemy": null,
	"party_has_won": false,
	"turn_order": []
}

var party_has_won: bool = false

@export var current_encounter : encounters
@export var enemy_list : Array[Node2D]
@export var enemy_enclosure : Node2D

var turn_orders : Array[TurnStorage] = []
var active_turn_orders : Array[TurnStorage] = []
var active_enemies_data : Array = []

signal action_taken

# Helper Functions / Classes
# --------------------------------------------------------------------------------

# class to store party / enemies in relation to their speed
class TurnStorage:
	var combatant
	var speed : int
	func _init(_combatant, _speed: int):
		combatant = _combatant
		speed = _speed

# Returns an array of active combatants sorted by speed in descending order
func turn_priority(array : Array[TurnStorage]):
	array.sort_custom(func(a, b):
		return a.speed > b.speed
	)

func is_combatant_alive(combatant) -> bool:
	for order in turn_orders:
		if order.combatant == combatant:
			return true
	return false

func check_if_enemy_is_dead(target_node, target_data):
	if target_data.enemy_stats.health <= 0: 
		print("Enemy has died: " + target_data.enemy_name)
		target_node.visible = false
		target_node.get_node("Area2D/CollisionShape2D").set_deferred("disabled", true)
		remove_combatant_from_turns(target_data)
	
func remove_combatant_from_turns(combatant_to_remove):
	for i in range(turn_orders.size() - 1, -1, -1):
		if turn_orders[i].combatant == combatant_to_remove:
			turn_orders.remove_at(i)

func determine_can_move(entity):
	var thing = active_turn_orders.get(0).combatant
	var not_enemy_turn : bool = thing is PartyMember
	var can_move : bool
	if not_enemy_turn == true:
		if thing.current_battle_position == entity.current_battle_position:
			can_move = true
		else:
			can_move = false
	return can_move

func _on_button_button_down():
	party_members[0].take_damage(50)
	party_members[1].take_damage(50)
	party_members[2].take_damage(50)

func _on_button_2_button_down():
	party_members[0].heal_member(50)
	party_members[1].heal_member(50)
	party_members[2].heal_member(50)

func _update_ui(current_health: int, cur_player: int):
	party_labels[cur_player].get_node("HBoxContainer").get_child(1).text = str(current_health) + " / " + str(party_members[cur_player].player_stats.max_health)
	if party_members[cur_player].player_stats.health == 0:
		party_nodes[cur_player].get_node("X").visible = true
	else:
		party_nodes[cur_player].get_node("X").visible = false

# Main Battle Loop
# --------------------------------------------------------------------------------

func _ready():
	number.shuffle()
	
	var party = $CombatParty
	
	party_nodes.append(party.get_node("Front"))
	party_nodes.append(party.get_node("Middle"))
	party_nodes.append(party.get_node("Back"))
	
	for i in range(party_members.size()):
		party_labels[i].get_child(0).text = party_members[i].member_name
		party_members[i].player_stats.health_changed.connect(_update_ui.bind(i))
		party_members[i].player_stats.speed_changed.connect(turn_priority.bind(turn_orders))
		_update_ui(party_members[i].player_stats.health, i)
		party_members[i].current_battle_position = i
		turn_orders.append(TurnStorage.new(party_members[i], (party_members[i].player_stats.altered_speed + party_members[i].player_stats.speed)))
		party_nodes[i].get_node("Mouse_Spot").input_event.connect(_on_party_input_event.bind(i))

	party.get_node("Front").get_node("Party_Member").texture = party_members[0].player_sprite
	party.get_node("Middle").get_node("Party_Member").texture = party_members[1].player_sprite
	party.get_node("Back").get_node("Party_Member").texture = party_members[2].player_sprite
	
	active_enemies_data.clear()
	
	for node in enemy_list:
		node.visible = false
		node.get_node("ColorRect").visible = false
	
	for i in range(enemy_list.size()):
		if current_encounter.enemy_list.size() >= i:
			var new_enemy = current_encounter.enemy_list[i].duplicate(true)
			active_enemies_data.append(new_enemy)
			new_enemy.enemy_position = i
			
			var visual_node = enemy_list[number[i]]
			visual_node.visible = true
			visual_node.get_node("Sprite2D").texture = new_enemy.enemy_sprite
			
			visual_node.set_meta("data_index", i)
		
	for enemy in active_enemies_data:
		turn_orders.append(TurnStorage.new(enemy, (enemy.enemy_stats.speed + enemy.enemy_stats.altered_speed)))
	
	for i in range(enemy_enclosure.get_child_count()):
		var enemy_area = enemy_enclosure.get_child(i).get_node("Area2D")
		enemy_area.mouse_entered.connect(_on_any_enemy_entered.bind(enemy_enclosure.get_child(i)))
		enemy_area.mouse_exited.connect(_on_any_enemy_exited.bind(enemy_enclosure.get_child(i)))
	
	turn_priority(turn_orders)
	
	active_turn_orders = turn_orders.duplicate()
	
	take_turn()

# executes turns in order of speed
func take_turn():
	while not battle_state["party_has_won"]:
		if party_members[0].player_stats.health <= 0 and party_members[1].player_stats.health <= 0 and party_members[2].player_stats.health <= 0:
			get_tree().quit()
			return 
		
		active_turn_orders = turn_orders.duplicate()
				
		while active_turn_orders.size() > 0:
			var current_entry = active_turn_orders.get(0)
			var thing = current_entry.combatant
			
			if not is_combatant_alive(thing):
				active_turn_orders.remove_at(0)
				continue
			
			if thing is PartyMember and thing.player_stats.health <= 0:
				active_turn_orders.remove_at(0)
				continue
			
			if thing is PartyMember:
				await player_turn(thing.current_battle_position)
			if thing is EnemyCombatant:
				await enemy_turn(thing.enemy_position)
				
			if active_turn_orders.size() > 0:
				active_turn_orders.remove_at(0)

func player_turn(cur_player: int):
	if party_members[cur_player].is_dead:
		return
	party_nodes[cur_player].get_node("Selection_Arrow").visible = true
	await action_taken
	party_nodes[cur_player].get_node("Selection_Arrow").visible = false
	party_nodes[cur_player].get_node("Line").visible = false
	if battle_state["selected_target"].has_meta("data_index"):
		var data_idx = battle_state["selected_target"].get_meta("data_index")
		var target_data = active_enemies_data[data_idx]
		
		var damage = party_members[cur_player].calculate_damage()
		target_data.take_damage(damage)
		check_if_enemy_is_dead(battle_state["selected_target"], target_data)
	battle_state["selected_target"] = null
	
func enemy_turn(cur_enemy: int):
	var enemy_data = current_encounter.enemy_list.get(cur_enemy)
	if enemy_data.enemy_stats.health <= 0:
		return
	var enemy_damage = enemy_data.calculate_damage()
	var random_party_member = randi_range(0, 2)
	party_members[random_party_member].take_damage(enemy_damage)

# Stuff to handle actions
# --------------------------------------------------------------------------------

func _on_party_input_event(viewport, event, shape_idx, cur_party: int):
	var can_move = determine_can_move(party_members[cur_party])
	
	if event is InputEventMouseButton and can_move:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				party_nodes[cur_party].get_node("Line").visible = true
				battle_state["is_dragging"] = true

func mouse_released():
	if battle_state["is_dragging"]:
		battle_state["is_dragging"] = false
		for node in party_nodes:
			node.get_node("Line").visible = false

func _unhandled_input(event):
	if event is InputEventMouseButton and not event.pressed:
		if battle_state["is_dragging"]:
			if battle_state["hovered_enemy"] != null:
				lock_selection(battle_state["hovered_enemy"])
			else:
				mouse_released()

func lock_selection(enemy):
	battle_state["is_dragging"] = false
	battle_state["selected_target"] = enemy
	action_taken.emit()

func _on_any_enemy_entered(enemy_node):
	battle_state["hovered_enemy"] = enemy_node

func _on_any_enemy_exited(enemy_node):
	if battle_state["hovered_enemy"] == enemy_node:
		battle_state["hovered_enemy"] = null
