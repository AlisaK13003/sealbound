extends Resource

class_name shop_item

@export var item_quantity: int
@export var buy_price: int
@export_flags("Item", "Equipment", "Weapon") var item_type
@export var item_thing: Items
@export var equipment_thing : equipment
@export var weapon_thing : weapon
@export var unlock_requirement: Array[Global.Progression_Flags] = []
