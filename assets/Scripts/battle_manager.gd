extends Node

# Global Variables / signals
# --------------------------------------------------------------------------------

# Used to randomize enemy starting position
var number = [0, 1, 2, 3, 4]
var planned_action_count : int = 0
var selected_member = [-1, 0] 
var selected_card = null
var alive_members_count = 0
@export var energy_count: int

@onready var energy_display = HUD.get_node("Energy_Holder")

# Holds the stats for a member
@export var party_members : Array[PartyMember]

# Is the displayed member, holds health bar, sprite, has combat_member.gd attached
var party_nodes : Array[CollisionShape2D]

# Holds the player cards at the bottom, has player_card.gd attached
var party_cards : Array[Control] = []

@export var HUD : Control

@export var current_encounter : encounters

# Stores the displayed enemy nodes, has enemy_unit.gd attached
@export var enemy_enclosure : Node2D

var battle_state = {
	"is_dragging": false,
	"selected_target": null,
	"hovered_enemy": null,
	"party_has_won": false,
	"turn_order": []
}

var party_has_won: bool = false

var turn_orders : Array[TurnStorage] = []
var active_turn_orders : Array[TurnStorage] = []
var active_enemies_data : Array = []

signal action_taken
signal choice_made(result)
signal card_selected(chosen_card)

# Helper Functions / Classes
# --------------------------------------------------------------------------------

# class to store party / enemies in relation to their speed
class TurnStorage:
	var combatant
	var enemy_to_attack
	var speed : int
	var move
	func _init(_combatant, _enemy_to_attack, _speed: int, _move):
		combatant = _combatant
		enemy_to_attack = _enemy_to_attack
		speed = _speed
		move = _move

# Returns an array of active combatants sorted by speed in descending order
func turn_priority(array : Array[TurnStorage]):
	array.sort_custom(func(a, b):
		return a.speed > b.speed
	)

func check_if_enemy_is_dead(target_node, target_data):
	if target_data.enemy_stats.health <= 0: 
		target_node.visible = false
		target_node.get_node("Area2D/CollisionShape2D").set_deferred("disabled", true)
		remove_combatant_from_turns(target_data)
		return true
	return false
	
func remove_combatant_from_turns(combatant_to_remove):
	for i in range(turn_orders.size() - 1, -1, -1):
		if turn_orders[i].combatant == combatant_to_remove:
			turn_orders.remove_at(i)

func _on_button_button_down():
	for member in party_members:
		member.take_damage(50)

func _on_button_2_button_down():
	for member in party_members:
		member.heal_member(50)

func _update_ui(current_health: int, cur_player: int):
	party_nodes[cur_player].update_health(current_health, party_members[cur_player].player_stats.max_health)

# clean up all highlights 
func deselect_all_units():
	for node in party_nodes:
		node.battle_state["waiting_to_perform"] = false
		node.update_state()
		node.get_node("Line").visible = false

func _on_card_move_selected(card):
	card_selected.emit(card)
	choice_made.emit(["CHOSE CARD", card])

# Main Battle Loop
# --------------------------------------------------------------------------------

func _ready():
	number.shuffle()
	
	var party = $CombatParty
	
	party_nodes.append(party.get_node("Front"))
	party_nodes.append(party.get_node("Middle"))
	party_nodes.append(party.get_node("Back"))
	
	for i in range(party_members.size()):
		party_cards.append(HUD.get_node("Player_Cards").get_child(i))
		party_cards[i].setup(party_members[i], i)
		party_nodes[i].setup(party_members[i])
		party_members[i].player_stats.health_changed.connect(_update_ui.bind(i))
		party_members[i].player_stats.speed_changed.connect(turn_priority.bind(turn_orders))
		party_members[i].current_battle_position = i
		party_nodes[i].get_node("Mouse_Spot").input_event.connect(_on_party_input_event.bind(i, party_cards[i]))
		if party_members[i].player_stats.health > 0:
			alive_members_count += 1
			
	active_enemies_data.clear()
	
	for i in range(enemy_enclosure.get_child_count()):
		enemy_enclosure.get_child(i).setup_enemy(current_encounter.enemy_list[number[i]])
		enemy_enclosure.get_child(i).visible = true
		enemy_enclosure.get_child(i).set_meta("data_index", i)
		
		if current_encounter.enemy_list.size() >= i:
			var new_enemy = current_encounter.enemy_list[i].duplicate(true)
			active_enemies_data.append(new_enemy)
			new_enemy.enemy_position = i
			enemy_enclosure.get_child(i).setup_enemy(new_enemy)
	
		var enemy_area = enemy_enclosure.get_child(i).get_node("Area2D")
		enemy_area.mouse_entered.connect(_on_any_enemy_entered.bind(enemy_enclosure.get_child(i)))
		enemy_area.mouse_exited.connect(_on_any_enemy_exited.bind(enemy_enclosure.get_child(i)))
	
	turn_priority(turn_orders)
	
	active_turn_orders = turn_orders.duplicate()
	
	for card in party_cards:
		card.move_selected.connect(_on_card_move_selected.bind(card))
	
	take_turn()

# executes turns in order of speed
func take_turn():
	while not battle_state["party_has_won"]:
		if party_members[0].player_stats.health <= 0 and party_members[1].player_stats.health <= 0 and party_members[2].player_stats.health <= 0:
			get_tree().quit()
			return 
		
		await player_turn()
		
		for i in range(active_enemies_data.size()):
			enemy_turn(i)
			
			var selected_player
			
			while true:
				selected_player = randi_range(0,2)
				if party_members[selected_player].player_stats.health >= 0:
					break
			
			turn_orders.append(TurnStorage.new(active_enemies_data[i], party_members[selected_player], (active_enemies_data[i].enemy_stats.speed + active_enemies_data[i].enemy_stats.altered_speed), null))
	
		turn_priority(turn_orders)
		
		active_turn_orders = turn_orders.duplicate()
			
		while active_turn_orders.size() > 0:
			var current_entry = active_turn_orders.get(0)
			var thing = current_entry.combatant
			
			if current_entry.move == null:
				var damage = thing.calculate_damage()
				current_entry.enemy_to_attack.take_damage(damage)
				check_if_dead(current_entry.enemy_to_attack)	
			else:
				# if a move is selected use it
				var damage = thing.use_move(current_entry.move)
				current_entry.enemy_to_attack.take_damage(damage)
				check_if_dead(current_entry.enemy_to_attack)
			if active_turn_orders.size() > 0:
				active_turn_orders.remove_at(0)
		turn_orders = []
		active_turn_orders = []

func check_if_dead(thing):
	if thing is EnemyCombatant:
		if check_if_enemy_is_dead(enemy_enclosure.get_child(thing.enemy_position), thing):
			active_turn_orders.remove_at(0)
			
	if thing is PartyMember and thing.player_stats.health <= 0:
		alive_members_count -= 1
		active_turn_orders.remove_at(0)

func player_turn():	
	var chosen_card
	while planned_action_count < alive_members_count:
		print("Action Count ", planned_action_count)
		print("Alive Members ", alive_members_count)
		var outcome = await choice_made
		if outcome[0] == "CANCELLED":
			print("Cancel")
			if selected_card != null:
				selected_member[0] = selected_card.belongs_to_party_num; selected_member[1] = 1
			else:
				selected_member[0] = -1; selected_member[1] = 0
			continue
		elif outcome[0] == "BASIC ATTACK":
			print("Basic Attack")
			if battle_state["selected_target"].has_meta("data_index"):
				party_nodes[selected_member[0]].battle_state["waiting_to_perform"] = false
				party_nodes[selected_member[0]].battle_state["has_acted"] = true
				party_nodes[selected_member[0]].update_state()
				var data_idx = battle_state["selected_target"].get_meta("data_index")
				var target_data = active_enemies_data[data_idx]
				
				turn_orders.append(TurnStorage.new(party_members[selected_member[0]], target_data, (party_members[selected_member[0]].player_stats.speed + party_members[selected_member[0]].player_stats.altered_speed), null))
				planned_action_count += 1
			battle_state["selected_target"] = null
			selected_member[0] = -1
			continue
		elif outcome[0] == "CHOSE CARD" and party_members[selected_member[0]].player_stats.health > 0:
			var clicked_card = outcome[1]
			
			if clicked_card.selected_move == null:
				if selected_card != null:
					party_nodes[selected_card.belongs_to_party_num].battle_state["waiting_to_perform"] = false
					party_nodes[selected_card.belongs_to_party_num].update_state()
				selected_member[0] = -1; selected_member[1] = 0
				selected_card = null
				continue
			if clicked_card.has_acted:
				print("YOU ALREADY DID SHIT")
				continue

			if selected_card == clicked_card:
				party_nodes[selected_card.belongs_to_party_num].battle_state["waiting_to_perform"] = false
				party_nodes[selected_card.belongs_to_party_num].update_state()
				selected_member[0] = -1; selected_member[1] = 0
				selected_card = null
			# Clicked a different card
			else:
				if selected_card != null:
					party_nodes[selected_card.belongs_to_party_num].battle_state["waiting_to_perform"] = false
					party_nodes[selected_card.belongs_to_party_num].update_state()
				party_nodes[clicked_card.belongs_to_party_num].battle_state["waiting_to_perform"] = true
				party_nodes[clicked_card.belongs_to_party_num].update_state()
				selected_member[0] = clicked_card.belongs_to_party_num
				selected_member[1] = 1
				selected_card = clicked_card
					
		elif outcome[0] == "CARD ATTACK":
			if battle_state["selected_target"].has_meta("data_index"):
				var data_idx = battle_state["selected_target"].get_meta("data_index")
				var target_data = active_enemies_data[data_idx]
				
				# turn_orders.append(TurnStorage.new(party_members[selected_member[0]], target_data, (party_members[selected_member[0]].player_stats.speed + party_members[selected_member[0]].player_stats.altered_speed), party_members[selected_member[0]].move_list[selected_card.selected_move]))
				var move_to_perform = null
				
				# Check if the card has a valid move index before accessing the array
				if selected_card != null and selected_card.get("selected_move") != null:
					move_to_perform = party_members[selected_member[0]].move_list[selected_card.selected_move]
				else:
					printerr("Error: 'selected_card' is missing 'selected_move' index. Defaulting to null action.")
				
				# Create the TurnStorage using the safe variable
				turn_orders.append(TurnStorage.new(party_members[selected_member[0]], target_data, (party_members[selected_member[0]].player_stats.speed + party_members[selected_member[0]].player_stats.altered_speed), move_to_perform))
				party_nodes[selected_member[0]].battle_state["has_acted"] = true
				party_nodes[selected_member[0]].battle_state["waiting_to_perform"] = false
				party_nodes[selected_member[0]].update_state()
				
				selected_member[0] = -1; selected_member[1] = 0
				planned_action_count += 1
			selected_card = null
			
		if true:
			continue
		else:
			var currently_acting = chosen_card.belongs_to_party_num
			party_nodes[currently_acting].battle_state["waiting_to_perform"] = true
			party_nodes[currently_acting].update_state()
			party_nodes[currently_acting].get_node("Line").visible = false
			
			await action_taken
			
			if battle_state["selected_target"].has_meta("data_index"):
				var data_idx = battle_state["selected_target"].get_meta("data_index")
				var target_data = active_enemies_data[data_idx]
				var damage = party_members[currently_acting].calculate_damage()
				target_data.take_damage(damage)
				check_if_enemy_is_dead(battle_state["selected_target"], target_data)
				battle_state["selected_target"] = null
				chosen_card.has_acted = true
				planned_action_count += 1
				party_nodes[currently_acting].battle_state["waiting_to_perform"] = false
				party_nodes[currently_acting].update_state()
	planned_action_count = 0
	selected_member[0] = -1
	selected_member[1] = 0
	selected_card = null
	for node in party_nodes:
		node.battle_state["has_acted"] = false
	for card in party_cards:
		card.has_acted = false
	
func enemy_turn(cur_enemy: int):
	var enemy_data = current_encounter.enemy_list.get(cur_enemy)
	if enemy_data.enemy_stats.health <= 0:
		return
	var enemy_damage = enemy_data.calculate_damage()
	var random_party_member = randi_range(0, 2)
	party_members[random_party_member].take_damage(enemy_damage)

# Stuff to handle actions
# --------------------------------------------------------------------------------

func _on_party_input_event(viewport, event, shape_idx, cur_party: int, card):	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not card.has_acted and party_members[cur_party].player_stats.health > 0:
			if event.pressed and (selected_member[0] == cur_party or selected_member[0] == -1):
				party_nodes[cur_party].get_node("Line").visible = true
				battle_state["is_dragging"] = true
				selected_member[0] = cur_party

func mouse_released():
	if battle_state["is_dragging"]:
		battle_state["is_dragging"] = false
		for node in party_nodes:
			node.get_node("Line").visible = false
		choice_made.emit(["CANCELLED", null])
		if selected_card == null:
			selected_member[0] = -1
			selected_member[1] = 0

# logic to handle when mouse is released
func _unhandled_input(event):
	if event is InputEventMouseButton and not event.pressed:
		if battle_state["is_dragging"]:
			if battle_state["hovered_enemy"] != null:
				lock_selection(battle_state["hovered_enemy"])
			else:
				mouse_released()

# when mouse is released on an enemy
func lock_selection(enemy):
	battle_state["is_dragging"] = false
	battle_state["selected_target"] = enemy
	if selected_member[1] == 1:
		party_cards[selected_member[0]].has_acted = true
		choice_made.emit(["CARD ATTACK", null])
	elif selected_member[1] == 0:
		party_cards[selected_member[0]].has_acted = true
		choice_made.emit(["BASIC ATTACK", null])

func _on_any_enemy_entered(enemy_node):
	battle_state["hovered_enemy"] = enemy_node

func _on_any_enemy_exited(enemy_node):
	if battle_state["hovered_enemy"] == enemy_node:
		battle_state["hovered_enemy"] = null
