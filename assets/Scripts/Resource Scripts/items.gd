extends Resource

class_name Items

@export var item_name : String
@export var item_description : String
@export var sell_price: int
@export var item_quantity: int

@export var item_sprite : Texture2D

@export_flags("Deal_Damage", "Heal") var does_what : int

@export_flags("Consumable", "Valuable", "Quest_Item") var what_is_it = 0

@export var targets_players: bool = true
@export var is_aoe_item: bool = false
@export var amount_to_heal_or_deal : int

@export var does_revive: bool = false

@export_flags(
	"Stun:1",
	"Sleep:2",
	"Shock:4",
	"Poison:8",
	"Burn:16",
	"Freeze:32",
	"Slow:64",
	"Agro:128",
	"Attack-:256",
	"Defense-:512",
	"Evasion-:1024",
	"CritChance-:2048",
	"Accuracy-:4096",
	"Momentum:8192",
	"Regen:16384",
	"Stun_Immunity:32768",
	"Attack+:65536",
	"Defense+:131072",
	"Evasion+:262144",
	"CritChance+:524288",
	"Accuracy+:1048576"
	) var removes_status

@export_flags(
	"Stun:1",
	"Sleep:2",
	"Shock:4",
	"Poison:8",
	"Burn:16",
	"Freeze:32",
	"Slow:64",
	"Agro:128",
	"Attack-:256",
	"Defense-:512",
	"Evasion-:1024",
	"CritChance-:2048",
	"Accuracy-:4096",
	"Momentum:8192",
	"Regen:16384",
	"Stun_Immunity:32768",
	"Attack+:65536",
	"Defense+:131072",
	"Evasion+:262144",
	"CritChance+:524288",
	"Accuracy+:1048576"
	) var give_status

func export_to_JSON():
	return {
		"path": resource_path,
	}
