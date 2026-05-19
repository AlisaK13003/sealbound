extends Node2D

# temporary onboarding
@export var party_slot_1 : generic_combatant
@export var party_slot_2 : generic_combatant
@export var party_slot_3 : generic_combatant

@export var current_dungeon_run : dungeon_type

@onready var slot_1 = $Party_Container/"Party Slot 1"
@onready var slot_2 = $Party_Container/"Party Slot 2"
@onready var slot_3 = $Party_Container/"Party Slot 3"

@onready var enemy_shit = $Enemy_Container

@onready var rng = RandomNumberGenerator.new()

var all_combatants : Array[generic_combatant] = []

func _ready():
	slot_1.setup(party_slot_1)
	slot_2.setup(party_slot_2)
	slot_3.setup(party_slot_3)

	all_combatants.append(party_slot_1)
	all_combatants.append(party_slot_2)
	all_combatants.append(party_slot_3)

	var number_of_possible_waves = current_dungeon_run.potential_waves.size()
	var random_wave = floor(rng.randf_range(0, number_of_possible_waves))
	var enemy_count_for_current_wave = current_dungeon_run.potential_waves[random_wave].enemies.size()
	for i in range(enemy_shit.get_child_count()):
		if i >= enemy_count_for_current_wave:
			enemy_shit.get_child(i).visible = false
			continue
		enemy_shit.get_child(i).setup(current_dungeon_run.potential_waves[random_wave].enemies[i])
		all_combatants.append(current_dungeon_run.potential_waves[random_wave].enemies[i])
	determine_order()
	for combatant in all_combatants:
		print(combatant.combatant_name)

func determine_order():
	all_combatants.sort_custom(func(a, b):
		return a.combatant_stats.altered_speed > b.combatant_stats.altered_speed
	)
	
func run(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().quit()
