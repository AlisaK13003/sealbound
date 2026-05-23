extends Node3D

# temporary onboarding
@export var party_slot_1 : generic_combatants
@export var party_slot_2 : generic_combatants
@export var party_slot_3 : generic_combatants

@export var current_dungeon_run : dungeon_type

@onready var slot_1 = $Player_Container/Player_Slot1
@onready var slot_2 = $Player_Container/Player_Slot2
@onready var slot_3 = $Player_Container/Player_Slot3

@onready var enemy_shit = $Enemy_Container

@onready var rng = RandomNumberGenerator.new()

var all_combatants : Array[generic_combatants] = []

var mana: int = 3

var waiting_for_confirmation : bool = false
signal confirmation
signal action_taken
signal turn_ended

func _ready():
	slot_1.setup(party_slot_1, self, 0)
	slot_2.setup(party_slot_2, self, 1)
	slot_3.setup(party_slot_3, self, 2)

	all_combatants.append(party_slot_1)
	all_combatants.append(party_slot_2)
	all_combatants.append(party_slot_3)
		
	$UI/Party_Portraits/Party_Portrait_1/HealthBar.max_value = party_slot_1.combatant_stats.max_health
	$UI/Party_Portraits/Party_Portrait_1/HealthBar.value = party_slot_1.combatant_stats.health
	$UI/Party_Portraits/Party_Portrait_1/Name.text = party_slot_1.combatant_name
	$UI/Party_Portraits/Party_Portrait_1/Health_Num.text = str(party_slot_1.combatant_stats.health)
	$UI/Party_Portraits/Party_Portrait_1/Portrait.texture = party_slot_1.party_member_portrait
	
	$UI/Party_Portraits/Party_Portrait_2/HealthBar.max_value = party_slot_2.combatant_stats.max_health
	$UI/Party_Portraits/Party_Portrait_2/HealthBar.value = party_slot_2.combatant_stats.health
	$UI/Party_Portraits/Party_Portrait_2/Name.text = party_slot_2.combatant_name
	$UI/Party_Portraits/Party_Portrait_2/Health_Num.text = str(party_slot_2.combatant_stats.health)
	$UI/Party_Portraits/Party_Portrait_2/Portrait.texture = party_slot_2.party_member_portrait
	
	$UI/Party_Portraits/Party_Portrait_3/HealthBar.max_value = party_slot_3.combatant_stats.max_health
	$UI/Party_Portraits/Party_Portrait_3/HealthBar.value = party_slot_3.combatant_stats.health
	$UI/Party_Portraits/Party_Portrait_3/Name.text = party_slot_3.combatant_name
	$UI/Party_Portraits/Party_Portrait_3/Health_Num.text = str(party_slot_3.combatant_stats.health)
	$UI/Party_Portraits/Party_Portrait_3/Portrait.texture = party_slot_3.party_member_portrait
	
	battle_loop()

func determine_order():
	all_combatants.clear()
	
	for slot in $Player_Container.get_children():
		all_combatants.append(slot.stored_combatant)
	for enemy_slot in enemy_shit.get_children():
		if enemy_slot.visible:
			all_combatants.append(enemy_slot.stored_combatant)
	
	all_combatants.sort_custom(func(a, b):
		return a.combatant_stats.altered_speed > b.combatant_stats.altered_speed
	)

func select_next_wave():
	mana = 3
	var number_of_possible_waves = current_dungeon_run.potential_waves.size()
	var random_wave = rng.randi_range(0, number_of_possible_waves - 1)
	var enemy_count_for_current_wave = current_dungeon_run.potential_waves[random_wave].enemies.size()
	for i in range(enemy_shit.get_child_count()):
		if i >= enemy_count_for_current_wave:
			enemy_shit.get_child(i).visible = false
			continue
		else:
			enemy_shit.get_child(i).visible = true
		enemy_shit.get_child(i).setup(current_dungeon_run.potential_waves[random_wave].enemies[i].duplicate(true), self, i)
		all_combatants.append(current_dungeon_run.potential_waves[random_wave].enemies[i].duplicate(true))
	
func battle_loop():
	print("BATTLE_STARTED")
	var is_wave_over : bool = false
	var number_of_waves_to_fight = rng.randi_range(current_dungeon_run.minimum_number_of_waves, current_dungeon_run.max_number_of_waves)
	for i in range(number_of_waves_to_fight):
		is_wave_over = false
		select_next_wave()
		$UI/Dungeon_Floor.text = current_dungeon_run.dungeon_name + "\n" + str(i + 1) + "F"

		while(not is_wave_over):
			determine_order()
			for j in range(all_combatants.size()):
				var current_combatant = all_combatants[j]
				if current_combatant.is_dead:
					continue
				elif current_combatant.is_combatant_enemy:
					await execute_enemy_turn(current_combatant)
				else:	
					var current_slot : int = 0
					for person in $Player_Container.get_children():
						if person.stored_combatant.combatant_name == current_combatant.combatant_name:
							current_slot = person.get_index()
					$Player_Container.get_child(current_slot).take_turn()
					$Player_Container.get_child(current_slot).combatant_ui.visible = true
					$Player_Container.get_child(current_slot).combatant_ui_area.visible = true
					
					var what_action = await action_taken
					match what_action[0]:
						"BASIC_ATTACK":
							var target_node = enemy_shit.get_child(what_action[1])
							var damage = $Player_Container.get_child(current_slot).execute_base_attack(target_node.stored_combatant, target_node)
							if await target_node.update_health(damage):
								target_node.stored_combatant.is_dead = true
						"BASIC_DEFEND":
							$Player_Container.get_child(current_slot).execute_defend()
							print("HIII")
						"SKILL":
							print("SKILL")
						"ITEM":
							print("ITEM")
					$Player_Container.get_child(current_slot).combatant_ui.visible = false
					$Player_Container.get_child(current_slot).combatant_ui_area.visible = false
					$Player_Container.get_child(current_slot).reset_ui()
				revert_to_default_UI()
				await get_tree().create_timer(0.75).timeout
				var number_of_alive_enemies = 0
				for enemy in enemy_shit.get_children():
					if enemy.stored_combatant == null:
						continue
					if not enemy.stored_combatant.is_dead:
						number_of_alive_enemies += 1
				if number_of_alive_enemies <= 0:
					is_wave_over = true
					break

func execute_enemy_turn(enemy_to_attack):
	rng = RandomNumberGenerator.new()
	var action_selected = rng.randi_range(0,2)
	var player_to_attack = rng.randi_range(0,2)
	while($Player_Container.get_child(player_to_attack).stored_combatant.is_dead or $Player_Container.get_child(player_to_attack).is_empty):
		player_to_attack = rng.randi_range(0,2)
	
	var attacking_enemy : int
	for enemy in enemy_shit.get_children():
		if enemy_to_attack == enemy.stored_combatant:
			attacking_enemy = enemy.get_index()
	enemy_shit.get_child(attacking_enemy).take_turn()
	action_selected = 0
	match action_selected:
		# Basic Attack
		0:
			var damage_to_deal = enemy_shit.get_child(attacking_enemy).execute_base_attack($Player_Container.get_child(player_to_attack).stored_combatant, $Player_Container.get_child(player_to_attack))
			if await $Player_Container.get_child(player_to_attack).update_health(damage_to_deal):
				$Player_Container.get_child(player_to_attack).stored_combatant.is_dead = true
			$UI/Party_Portraits.get_child(player_to_attack).get_node("HealthBar").value = $Player_Container.get_child(player_to_attack).stored_combatant.combatant_stats.health
			$UI/Party_Portraits.get_child(player_to_attack).get_node("Health_Num").text = str($Player_Container.get_child(player_to_attack).stored_combatant.combatant_stats.health)
		1:
			pass
		2:
			pass

func run(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().quit()

func action_menu_selected(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not waiting_for_confirmation:
			pass

func skill_menu_selected(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not waiting_for_confirmation:
			pass
			
func item_menu_selected(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not waiting_for_confirmation:
			pass

func back_button_selected(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not waiting_for_confirmation:
			revert_to_default_UI()

func attack_button_pressed():
	for enemy in enemy_shit.get_children():
		enemy.could_be_selected()
	var action_on_who = await confirmation
	action_taken.emit("BASIC_ATTACK", action_on_who)
			
func defend_button_pressed():
	action_taken.emit("BASIC_DEFEND")

func gave_confirmation(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("CONFIRMED")

func denied_confirmation(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			waiting_for_confirmation = false

func revert_to_default_UI():
	for enemy in enemy_shit.get_children():
		enemy.undo_selection()

func hide_everything():
	revert_to_default_UI()
