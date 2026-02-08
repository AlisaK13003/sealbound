extends Node

# majority of values will be replaced later on with stuff from the global script
# hard coded for now to make it easier to test
@export var party : Node2D
var party_member_1 : CollisionShape2D
var party_member_2 : CollisionShape2D
var party_member_3 : CollisionShape2D

var number = [0, 1, 2, 3, 4, 5, 6, 7, 8]
var is_dragging : bool = false
var current_hovered_enemy : Node2D = null
var selected_target: Node2D = null
var party_has_won: bool = false

@export var current_encounter : encounters

# Will be set up by global later on
@export var party_1 : PartyMember
@export var party_2 : PartyMember
@export var party_3 : PartyMember

@export var party_1_label : VBoxContainer
@export var party_2_label : VBoxContainer
@export var party_3_label : VBoxContainer

@export var enemy_list : Array[Node2D]
@export var enemy_enclosure : Node2D

var turn_orders : Array[TurnStorage] = []
var active_turn_orders : Array[TurnStorage] = []
var active_enemies_data : Array = []

signal action_taken

func _update_ui(current_health: int, party_member: int):
	match party_member:
		0:
			party_1_label.get_node("HBoxContainer").get_child(1).text = str(current_health) + " / " + str(party_1.player_stats.max_health)
			if party_1.player_stats.health == 0:
				party_member_1.get_node("X").visible = true
			else:
				party_member_1.get_node("X").visible = false
		1:
			party_2_label.get_node("HBoxContainer").get_child(1).text = str(current_health) + " / " + str(party_2.player_stats.max_health)
			if party_2.player_stats.health == 0:
				party_member_2.get_node("X").visible = true
			else:
				party_member_2.get_node("X").visible = false
		2:
			party_3_label.get_node("HBoxContainer").get_child(1).text = str(current_health) + " / " + str(party_3.player_stats.max_health)
			if party_3.player_stats.health == 0:
				party_member_3.get_node("X").visible = true
			else:
				party_member_3.get_node("X").visible = false

# Given current encounter / party arrangement assign the appropriate sprites and hide the color_rect on the combat_templates
func _ready():
	number.shuffle()
	
	party_member_1 = party.get_node("Front")
	party_member_2 = party.get_node("Middle")
	party_member_3 = party.get_node("Back")
	
	party_1_label.get_child(0).text = party_1.member_name
	party_2_label.get_child(0).text = party_2.member_name
	party_3_label.get_child(0).text = party_3.member_name

	party_1.player_stats.health_changed.connect(_update_ui.bind(0))
	party_2.player_stats.health_changed.connect(_update_ui.bind(1))
	party_3.player_stats.health_changed.connect(_update_ui.bind(2))
	
	party_1.player_stats.speed_changed.connect(turn_priority.bind(turn_orders))
	party_2.player_stats.speed_changed.connect(turn_priority.bind(turn_orders))
	party_3.player_stats.speed_changed.connect(turn_priority.bind(turn_orders))

	_update_ui(party_1.player_stats.health, 0)
	_update_ui(party_2.player_stats.health, 1)
	_update_ui(party_3.player_stats.health, 2)
	
	party_1.current_battle_position = 0
	party_2.current_battle_position = 1
	party_3.current_battle_position = 2
	
	party.get_node("Front").get_node("Party_Member").texture = party_1.player_sprite
	party.get_node("Middle").get_node("Party_Member").texture = party_2.player_sprite
	party.get_node("Back").get_node("Party_Member").texture = party_3.player_sprite
	
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
		
	turn_orders.append(TurnStorage.new(party_1, (party_1.player_stats.altered_speed + party_1.player_stats.speed)))
	turn_orders.append(TurnStorage.new(party_2, (party_2.player_stats.speed + party_2.player_stats.altered_speed)))
	turn_orders.append(TurnStorage.new(party_3, (party_3.player_stats.altered_speed + party_3.player_stats.speed)))
	
	for enemy in active_enemies_data:
		turn_orders.append(TurnStorage.new(enemy, (enemy.enemy_stats.speed + enemy.enemy_stats.altered_speed)))
	
	for i in range(enemy_enclosure.get_child_count()):
		var enemy_area = enemy_enclosure.get_child(i).get_node("Area2D")
		enemy_area.mouse_entered.connect(_on_any_enemy_entered.bind(enemy_enclosure.get_child(i)))
		enemy_area.mouse_exited.connect(_on_any_enemy_exited.bind(enemy_enclosure.get_child(i)))
	
	turn_priority(turn_orders)
	
	active_turn_orders = turn_orders.duplicate()
	
	take_turn()

class TurnStorage:
	var combatant
	var speed : int
	func _init(_combatant, _speed: int):
		combatant = _combatant
		speed = _speed

func turn_priority(array):
	array.sort_custom(func(a, b):
		return a.speed > b.speed
	)

# executes turns in order of speed
func take_turn():
	while not party_has_won:
		if party_1.player_stats.health <= 0 and party_2.player_stats.health <= 0 and party_3.player_stats.health <= 0:
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

func is_combatant_alive(combatant) -> bool:
	for order in turn_orders:
		if order.combatant == combatant:
			return true
	return false

func player_turn(cur_player: int):
	match cur_player:
		0:
			print("Party 1 Doing stuff")
			if party_1.is_dead:
				return
			party_member_1.get_node("Selection_Arrow").visible = true
			await action_taken
			party_member_1.get_node("Selection_Arrow").visible = false
			party_member_1.get_node("Line").visible = false
			if selected_target.has_meta("data_index"):
				var data_idx = selected_target.get_meta("data_index")
				var target_data = active_enemies_data[data_idx]
				
				var damage = party_1.calculate_damage()
				target_data.take_damage(damage)
				check_if_enemy_is_dead(selected_target, target_data)
		1:
			print("Party 2 doing stuff")
			if party_2.is_dead:
				return
			party_member_2.get_node("Selection_Arrow").visible = true
			await action_taken
			party_member_2.get_node("Selection_Arrow").visible = false
			party_member_2.get_node("Line").visible = false
			if selected_target.has_meta("data_index"):
				var data_idx = selected_target.get_meta("data_index")
				var target_data = active_enemies_data[data_idx]
				
				var damage = party_2.calculate_damage()
				target_data.take_damage(damage)
				check_if_enemy_is_dead(selected_target, target_data)
		2:
			print("Party 3 doing stuff")
			if party_3.is_dead:
				return
			party_member_3.get_node("Selection_Arrow").visible = true
			await action_taken
			party_member_3.get_node("Selection_Arrow").visible = false
			party_member_3.get_node("Line").visible = false
			if selected_target.has_meta("data_index"):
				var data_idx = selected_target.get_meta("data_index")
				var target_data = active_enemies_data[data_idx]
				
				var damage = party_3.calculate_damage()
				target_data.take_damage(damage)
				check_if_enemy_is_dead(selected_target, target_data)
	selected_target = null

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
	
func enemy_turn(cur_enemy: int):
	var enemy_data = current_encounter.enemy_list.get(cur_enemy)
	if enemy_data.enemy_stats.health <= 0:
		return
	var enemy_damage = enemy_data.calculate_damage()
	var random_party_member = randi_range(0, 2)
	match random_party_member:
		0:
			party_1.take_damage(enemy_damage)
		1:
			party_2.take_damage(enemy_damage)
		2:
			party_3.take_damage(enemy_damage)
			
func _on_button_button_down():
	party_1.take_damage(50)
	party_2.take_damage(50)
	party_3.take_damage(50)

func _on_button_2_button_down():
	party_1.heal_member(50)
	party_2.heal_member(50)
	party_3.heal_member(50)

func _unhandled_input(event):
	if event is InputEventMouseButton and not event.pressed:
		if is_dragging:
			if current_hovered_enemy != null:
				lock_selection(current_hovered_enemy)
			else:
				mouse_released()

func lock_selection(enemy):
	is_dragging = false
	selected_target = enemy
	action_taken.emit()

func mouse_released():
	if is_dragging:
		is_dragging = false
		party_member_3.get_node("Line").visible = false
		party_member_2.get_node("Line").visible = false
		party_member_1.get_node("Line").visible = false

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

func _on_back_party_entered(viewport, event, shape_idx):
	var can_move = determine_can_move(party_3)
	if event is InputEventMouseButton and can_move:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				party_member_3.get_node("Line").visible = true
				is_dragging = true
				
func _on_middle_party_entered(viewport, event, shape_idx):
	var can_move = determine_can_move(party_2)
	if event is InputEventMouseButton and can_move:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				party_member_2.get_node("Line").visible = true
				is_dragging = true

func _on_front_party_entered(viewport, event, shape_idx):
	var can_move = determine_can_move(party_1)
	if event is InputEventMouseButton and can_move:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				party_member_1.get_node("Line").visible = true
				is_dragging = true

func _on_any_enemy_entered(enemy_node):
	current_hovered_enemy = enemy_node

func _on_any_enemy_exited(enemy_node):
	if current_hovered_enemy == enemy_node:
		current_hovered_enemy = null
