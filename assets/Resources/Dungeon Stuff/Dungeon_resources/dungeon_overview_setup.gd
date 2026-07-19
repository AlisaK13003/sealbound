extends Control

@onready var dungeon_name_label = $Dungeon_Name
@onready var floor_count_label = $GridContainer2/Floor_Count
@onready var average_level_label = $GridContainer2/Average_Level
@onready var seal_boss_label = $GridContainer2/Seal

@onready var dungeon_description = $Dungeon_description
@onready var enemies = $Found_Enemies

var stored_dungeon
var stored_quest

func _setup(dungeon_type_: dungeon_type, quest_dungeon: quest = null):
	dungeon_description.text = dungeon_type_.dungeon_description
	stored_dungeon = dungeon_type_
	stored_quest = quest_dungeon
	dungeon_name_label.text = dungeon_type_.dungeon_name
	floor_count_label.text = "Expect " + str(dungeon_type_.minimum_number_of_floors) + " - " + str(dungeon_type_.max_number_of_floors) + " floors."
	var unique_enemies = []
	var unique_items = []
	for chest_drop in dungeon_type_.chest_drops.keys():
		for item in chest_drop:
			if unique_items.find(item) == -1:
				unique_items.append(item)
	for item in unique_items:
		var new_label = Label.new()
		new_label.text = item.item_name
		$GridContainer.add_child(new_label)
	
	if dungeon_type_.does_dungeon_have_boss:
		seal_boss_label.text = "Seal Guardian: " + dungeon_type_.boss_encounter.encounterable_enemy.combatant_name
	
	for enemy_slot: generic_combatants in unique_enemies:
		var cont = Container.new()
		var new_sprite = AnimatedSprite2D.new()
		
		cont.custom_minimum_size = Vector2(32, 32)
		
		cont.add_child(new_sprite)
		enemies.add_child(cont)
		new_sprite.offset = enemy_slot.equip_sprite_offset
		new_sprite.sprite_frames = enemy_slot.sprite_frames
		new_sprite.play("Idle")
		new_sprite.speed_scale = enemy_slot.idle_speed
		new_sprite.flip_h = enemy_slot.equip_flip

	average_level_label.text = "Avg Lv: " + str(dungeon_type_.average_dungeon_level)
