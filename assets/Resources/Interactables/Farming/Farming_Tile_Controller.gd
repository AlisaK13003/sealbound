extends Control

var held_crop: crops
var slot_number: int
var player_can_plant_or_harvest: bool = false
var harvestable: bool = false

@onready var texture_rect = $TextureRect
@onready var default_texture = load("res://assets/Resources/Interactables/Farming/Crops/Start.png")

# If a crop should be growing here, check it's progress on load
func _setup(current_slot):
	slot_number = current_slot

	if Global.planted_crops[current_slot] == null:
		texture_rect.texture = default_texture
		held_crop = null
		return
	held_crop = Global.planted_crops[current_slot]
	check_plant_progress()
	
# Checks what stage the crop should be at based on how long it's been growing
func check_plant_progress():
	var stage_day = (Global.current_day * (Global.current_year + 1)) - held_crop.plant_date
	for stage in held_crop.growth_stages:
		if stage_day >= held_crop.growth_stages[stage]:
			texture_rect.texture = stage
			harvestable = true
		else:
			harvestable = false
		
func plant_crop(crop_to_plant):
	held_crop = load(crop_to_plant).duplicate(true)
	if held_crop == null:
		return
	held_crop.plant_date = Global.current_day
	Global.planted_crops[slot_number] = held_crop
	Global.remove_from_inventory(Global.item_is_in_slot)
	check_plant_progress()
	
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("Mouse_Right_Click"):
		if Global.holding_item != null and Global.holding_item.item_qualities & 2:
			if held_crop == null and player_can_plant_or_harvest:
				plant_crop(Global.holding_item.item_resource_path)
				return
		if harvestable:
			if Global.add_to_first_open_slot(load(held_crop.path_to_inventory_item)):
				held_crop = null
				harvestable = false
				Global.planted_crops[slot_number] = null
				texture_rect.texture = default_texture
			else:
				print("CAN'T HARVEST")

func _player_in_range_to_act(body):
	if body.is_in_group("Overworld_Player"):
		player_can_plant_or_harvest = true
		
func _player_not_in_range_to_act(body):
	if body.is_in_group("Overworld_Player"):
		player_can_plant_or_harvest = false
