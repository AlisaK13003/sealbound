extends Resource

class_name inventory_items

@export var item_name: String
@export_flags("Tool", "Crop", "Consumable", "Giftable") var item_qualities
@export var item_texture: Texture2D
@export var over_the_head_texture: Texture2D
@export var item_resource_path: String
@export var sell_price: int
@export var buy_price: int
