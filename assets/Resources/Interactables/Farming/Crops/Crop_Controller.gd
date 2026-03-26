extends Resource

class_name crops

var plant_date: int

@export var crop_name: String
@export var time_for_crop_to_grow: int

# Should have a sprite2D and day attached for each pair
@export var growth_stages: Dictionary
@export var path_to_inventory_item: String
