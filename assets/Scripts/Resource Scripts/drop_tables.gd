extends Resource

class_name drop_tables

@export var coin_drop_range : Vector2
@export var bond_drop_range : Vector2

@export var items_to_drop : Array[inventory_items]
@export var item_drop_chances : Dictionary[inventory_items, int]
