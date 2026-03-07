extends Resource

class_name Items

@export var item_name : String
@export var item_description : String
@export var sell_price: int

@export var item_sprite : Texture2D

@export_flags("Deal_Damage", "Heal") var does_what : int

@export var amount_to_heal_or_deal : int

@export_flags("Fire", "Ice", "Wind", "Electric", "Psychic", "Wind") var affinities: int
