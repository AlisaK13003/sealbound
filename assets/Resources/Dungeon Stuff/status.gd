extends Resource

class_name status

@export var status_name : String
@export_flags(
	"Sleep",
	"Shock",
	"Poison",
	"Burn",
	"Freeze",
	"Agro",
	"Attack-",
	"Defense-",
	"Evasion-",
	"CritChance-",
	"Accuracy-",
	"Regen",
	"Stun_Immunity",
	"Attack+",
	"Defense+",
	"Evasion+",
	"CritChance+",
	"Accuracy-"
	) var status_type
@export var remaining_turns: int = 3
