extends Node

# Global Variables / signals
# --------------------------------------------------------------------------------

# Used to randomize enemy starting position
var number = [0, 1, 2, 3, 4]

# Tracks how many party members have scheduled moves
var planned_action_count : int = 0

# Tracks the state of the selected member, first tracks which member, second tracks what action (0 for basic attack, 1 for card)
var selected_member = [-1, 0] 
var selected_card = null
var alive_members_count = 0
@export var energy_count: int
var current_energy_cost: int

# Stores the HBOX that holds the energy counter
@onready var energy_display = HUD.get_node("Energy_Holder")

# Holds the stats for a member
@export var party_members : Array[PartyMember]
@export var item_list : Array[Items]
# Is the displayed member, holds health bar, sprite, has combat_member.gd attached
var party_nodes : Array[CollisionShape2D]

# Holds the player cards at the bottom, has player_card.gd attached
var party_cards : Array[Control] = []

# On screen display
@export var HUD : Control
@onready var GO_button = HUD.get_node("GO")
@onready var CANCEL_button = HUD.get_node("CANCEL")
@onready var location_label = HUD.get_node("Where")
@onready var item_storage = HUD.get_node("ITEM").get_child(0)

# Holds the information regarding 
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

# Stores all alive enemies
var active_enemies_data = {}

signal choice_made(result)

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

# Handles player health ui
func _update_ui(current_health: int, cur_player: int):
	party_nodes[cur_player].update_health(current_health, party_members[cur_player].player_stats.max_health)

# clean up all highlights 
func deselect_all_units():
	for node in party_nodes:
		node.battle_state["waiting_to_perform"] = false
		node.update_state()
		node.get_node("Line").visible = false

func _on_card_move_selected(card):
	selected_member[0] = card.belongs_to_party_num
	choice_made.emit(["CHOSE CARD", card])

func check_if_dead(thing):
	if thing is EnemyCombatant:
		if check_if_enemy_is_dead(enemy_enclosure.get_child(thing.enemy_position), thing):
			active_enemies_data.erase(active_enemies_data.find_key(thing))
			
	if thing is PartyMember and thing.player_stats.health <= 0:
		alive_members_count -= 1

func reset_battle():
	# Reset at the end of each turn
	planned_action_count = 0
	selected_member[0] = -1
	selected_member[1] = 0
	selected_card = null
	energy_count = 3
	for child in energy_display.get_children():
		if child is Label:
			continue
		child.value = 100
	for node in party_nodes:
		if node.battle_state["is_dead"]:
			continue
		node.reset_states()
		node.update_state()
	for card in party_cards:
		card.has_acted = false
		card.selected_move = null
	for enemy in enemy_enclosure.get_children():
		enemy.reset_ui()

func update_energy_display(start_energy, energy_differential, inc_or_dec : bool):
	for i in range(energy_display.get_child_count() - 1):
		if inc_or_dec:
			if i > start_energy and i < energy_differential + start_energy:
				energy_display.get_child(i + 1).value = 100
		elif not inc_or_dec:
			if i <= start_energy and i > start_energy - energy_differential:
				energy_display.get_child(i + 1).value = 0
# Main Battle Loop
# --------------------------------------------------------------------------------

func _ready():
	number.shuffle()
	
	var party = $CombatParty
	
	party_nodes.append(party.get_node("Front"))
	party_nodes.append(party.get_node("Middle"))
	party_nodes.append(party.get_node("Back"))
	
	GO_button.button_down.connect(_handle_go_button)
	CANCEL_button.button_down.connect(_handle_cancel_button)
	location_label.text = Global.current_location
	
	for i in range(3):
		if item_list.get(i) != null:
			item_storage.get_child(i).setup(item_list[i], i)
		for member in party_nodes:
			pass
	
	# Sets up each party member in scene
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
	
	# Sets up each enemy in scene
	for i in range(enemy_enclosure.get_child_count()):
		if current_encounter.enemy_list.size() >= i:
			var enemy_node = enemy_enclosure.get_child(i)
			var new_enemy = current_encounter.enemy_list[i].duplicate(true)
			active_enemies_data[enemy_node.get_instance_id()] = new_enemy
			enemy_enclosure.get_child(i).setup_enemy(active_enemies_data[enemy_node.get_instance_id()])
			enemy_enclosure.get_child(i).visible = true
			enemy_enclosure.get_child(i).set_meta("data_index", i)
			new_enemy.enemy_position = i
	
		var enemy_area = enemy_enclosure.get_child(i).get_node("Area2D")
		enemy_area.mouse_entered.connect(_on_any_enemy_entered.bind(enemy_enclosure.get_child(i)))
		enemy_area.mouse_exited.connect(_on_any_enemy_exited.bind(enemy_enclosure.get_child(i)))
			
	for card in party_cards:
		card.move_selected.connect(_on_card_move_selected.bind(card))
	
	start_combat()

# executes turns in order of speed
func start_combat():
	while not battle_state["party_has_won"]:
		# If every party member is dead, exit
		if party_members[0].player_stats.health <= 0 and party_members[1].player_stats.health <= 0 and party_members[2].player_stats.health <= 0:
			get_tree().quit()
			return 
		
		if active_enemies_data.size() == 0:
			battle_state["party_has_won"] = true
			continue
		
		await player_turn()
		
		# Create enemy turns
		for enemy in active_enemies_data.values():
			enemy_turn(enemy)

			var selected_player

			# Randomly attack an alive party member
			# PLACEHOLDER
			while true:
				selected_player = randi_range(0,2)
				if party_members[selected_player].player_stats.health >= 0:
					break
			
			# Add enemy to turn order list
			turn_orders.append(TurnStorage.new(enemy, party_members[selected_player], (enemy.enemy_stats.speed + enemy.enemy_stats.altered_speed), null))
		
		
		# Sort every combat member based on speed
		turn_priority(turn_orders)
		print("\n")
		turn_orders = turn_orders.duplicate()
			
		# Loop while there are still combatants waiting to attack
		while turn_orders.size() > 0:
			var current_entry = turn_orders.get(0)
			var thing = current_entry.combatant
			
			# If no move was selected, use basic attack
			if current_entry.move == null:
				var damage = thing.calculate_damage()
				current_entry.enemy_to_attack.take_damage(damage)
				check_if_dead(current_entry.enemy_to_attack)	
			# if a move is selected use it
			else:
				var damage = thing.use_move(current_entry.move)
				current_entry.enemy_to_attack.take_damage(damage)
				check_if_dead(current_entry.enemy_to_attack)
			# Remove combatant from the list
			if turn_orders.size() > 0:
				turn_orders.remove_at(0)
		turn_orders = []

func player_turn():	
	# Wait for input from all alive members
	while true:
		var outcome = await choice_made
		if planned_action_count > alive_members_count:
			
			if outcome[0] == "GO":
				reset_battle()
				return
			elif outcome[0] == "RESET":
				reset_battle()
				continue
			else :
				continue
		
		if outcome[0] == "RESET":
			reset_battle()
			continue
		
		if outcome[0] == "GO":
			reset_battle()
			return
		
		# Handle player choosing to not attack
		if outcome[0] == "CANCELLED":
			if selected_card != null:
				selected_member[0] = selected_card.belongs_to_party_num; selected_member[1] = 1
			else:
				selected_member[0] = -1; selected_member[1] = 0
			continue
		
		# Player attacked without selecting a card
		elif outcome[0] == "BASIC ATTACK":
			# Ensure selected enemy is valid
			if battle_state["selected_target"].has_meta("data_index"):
				var data_idx = enemy_enclosure.get_child(battle_state["selected_target"].get_meta("data_index")).get_instance_id()
				var target_data = active_enemies_data[data_idx]
				
				var index = battle_state["selected_target"].get_meta("data_index")
				
				# Ensure the enemy isn't already dead
				if not enemy_enclosure.get_child(index).update_planned_damage(party_members[selected_member[0]].calculate_damage()):
					party_nodes[selected_member[0]].reset_states()
					party_nodes[selected_member[0]].update_state()
					party_cards[selected_member[0]].has_acted = false
					selected_member[0] = -1
					continue
					
				# Reset the player
				party_nodes[selected_member[0]].battle_state["waiting_to_perform"] = false
				party_nodes[selected_member[0]].battle_state["has_acted"] = true
				party_nodes[selected_member[0]].update_state()
				
				turn_orders.append(TurnStorage.new(party_members[selected_member[0]], target_data, (party_members[selected_member[0]].player_stats.speed + party_members[selected_member[0]].player_stats.altered_speed), null))
				enemy_enclosure.get_child(index).get_node("Sprite2D2").visible = true
				planned_action_count += 1
			battle_state["selected_target"] = null
			selected_member[0] = -1
			continue
			
		# Player selected a card
		elif outcome[0] == "CHOSE CARD":
			var clicked_card = outcome[1]
			
			if party_members[clicked_card.belongs_to_party_num].player_stats.health <= 0:
				continue
				
			# Ensure that the player hasn't acted yet
			elif clicked_card.has_acted:
				continue
			elif energy_count == 0:
				continue
			
			# Ensure that enough energy is stored before selecting a move
			elif selected_member[0] != -1 and clicked_card.selected_move != null:
				if (energy_count - party_members[selected_member[0]].move_list[clicked_card.selected_move].energy_cost) < 0:
					selected_member[0] = -1; selected_member[1] = 0
					clicked_card.selected_move = null
					continue
			
			# If player selects the same card twice
			if selected_card == clicked_card:
				if selected_card.selected_move == clicked_card.selected_move:
					party_nodes[selected_card.belongs_to_party_num].reset_states()
					party_nodes[selected_card.belongs_to_party_num].update_state()
					
					selected_member[0] = -1; selected_member[1] = 0
					selected_card = null
					continue
					
			# Clicked a different card
			if selected_card != null:
				party_nodes[selected_card.belongs_to_party_num].reset_states()
				party_nodes[selected_card.belongs_to_party_num].update_state()
				selected_card.selected_move = null
			party_nodes[clicked_card.belongs_to_party_num].battle_state["waiting_to_perform"] = true
			party_nodes[clicked_card.belongs_to_party_num].update_state()
			selected_member[0] = clicked_card.belongs_to_party_num
			selected_member[1] = 1
			selected_card = clicked_card

		# Player attacked an enemy using a card
		elif outcome[0] == "CARD ATTACK":
			if battle_state["selected_target"].has_meta("data_index"):
				var data_idx = enemy_enclosure.get_child(battle_state["selected_target"].get_meta("data_index")).get_instance_id()
				var target_data = active_enemies_data[data_idx]
								
				var move_to_perform = null
				
				# Check if the card has a valid move index before accessing the array
				if selected_card != null and selected_card.selected_move != null:
					move_to_perform = party_members[selected_member[0]].move_list[selected_card.selected_move]
				else:
					printerr("Error: 'selected_card' is missing 'selected_move' index. Defaulting to null action.")
				
				# Create the TurnStorage using the safe variable
				turn_orders.append(TurnStorage.new(party_members[selected_member[0]], target_data, (party_members[selected_member[0]].player_stats.speed + party_members[selected_member[0]].player_stats.altered_speed), move_to_perform))
				party_nodes[selected_member[0]].battle_state["has_acted"] = true
				party_nodes[selected_member[0]].battle_state["waiting_to_perform"] = false
				party_nodes[selected_member[0]].update_state()
				update_energy_display(energy_count - 1, party_members[selected_member[0]].move_list[selected_card.selected_move].energy_cost, false)
				energy_count -= party_members[selected_member[0]].move_list[selected_card.selected_move].energy_cost

				selected_member[0] = -1; selected_member[1] = 0
				planned_action_count += 1
				
			selected_card = null	
	reset_battle()
	
func enemy_turn(cur_enemy):
	if cur_enemy.enemy_stats.health <= 0:
		return
	var enemy_damage = cur_enemy.calculate_damage()
	var random_party_member = randi_range(0, 2)
	party_members[random_party_member].take_damage(enemy_damage)

# Stuff to handle actions
# --------------------------------------------------------------------------------

# For when the player hovers mouses over a player to read attack
func _on_party_input_event(_viewport, event, _shape_idx, cur_party: int, card):	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not card.has_acted and party_members[cur_party].player_stats.health > 0:
			if event.pressed and (selected_member[0] == cur_party or selected_member[0] == -1):
				party_nodes[cur_party].get_node("Line").visible = true
				battle_state["is_dragging"] = true
				selected_member[0] = cur_party

# Handles when the mouse is released while not having selected anything
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

# When the mouse enters an enemy, set that to be the targeted enemy
func _on_any_enemy_entered(enemy_node):
	battle_state["hovered_enemy"] = enemy_node

func _on_any_enemy_exited(enemy_node):
	if battle_state["hovered_enemy"] == enemy_node:
		battle_state["hovered_enemy"] = null

func _handle_go_button():
	choice_made.emit(["GO", null])

func _handle_cancel_button():
	choice_made.emit(["RESET", null])
