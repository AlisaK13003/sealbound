extends Control

@onready var dungeon_name_label = $MarginContainer/HBoxContainer/VBoxContainer/Dungeon_Name
@onready var floor_count_label = $MarginContainer/HBoxContainer/VBoxContainer/Floor_Count
@onready var average_level_label = $MarginContainer/HBoxContainer/VBoxContainer/Average_Level
@onready var seal_boss_label = $MarginContainer/HBoxContainer/VBoxContainer/Seal

@onready var dungeon_image = $Panel/TextureRect

@onready var enemies = $MarginContainer/MarginContainer/VBoxContainer/Found_Enemies

func _setup(dungeon_type_: dungeon_type):
	dungeon_name_label.text = dungeon_type_.dungeon_name
	floor_count_label.text = "Expect " + str(dungeon_type_.minimum_number_of_waves) + " - " + str(dungeon_type_.max_number_of_waves) + " floors."
	var avg_level_count = 0
	var total_level = 0
	var unique_enemies = []
	for possible_wave in dungeon_type_.potential_waves:
		for enemy in possible_wave.enemies:
			if unique_enemies.find(enemy) == -1:
				unique_enemies.append(enemy)
			avg_level_count += 1
			total_level += enemy.combatant_stats.level
	for enemy_slot in enemies.get_children():
		if unique_enemies.size() <= enemy_slot.get_index():
			enemy_slot.visible = false
			continue
		enemy_slot.get_child(0).sprite_frames = unique_enemies[enemy_slot.get_index()].sprite_frames
		enemy_slot.get_child(0).play("Idle")
		enemy_slot.get_child(0).speed_scale = unique_enemies[enemy_slot.get_index()].idle_speed
		
	average_level_label.text = "Avg Lv: " + str(total_level / avg_level_count)
	dungeon_image.texture = dungeon_type_.dungeon_background
