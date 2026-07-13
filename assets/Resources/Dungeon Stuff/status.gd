extends Resource

class_name status

@export var status_name : String
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
	) var status_type
@export var remaining_turns: int = 4

var status_name_map: Dictionary = {
	1 << 0: "Stun",
	1 << 1: "Sleep",
	1 << 2: "Shock",
	1 << 3: "Poison",
	1 << 4: "Burn",
	1 << 5: "Freeze",
	1 << 6: "Slow",
	1 << 7: "Agro",
	1 << 8: "Attack-",
	1 << 9: "Defense-",
	1 << 10: "Evasion-",
	1 << 11: "CritChance-",
	1 << 12: "Accuracy-",
	1 << 13: "Momentum",
	1 << 14: "Regen",
	1 << 15: "Stun_Immunity",
	1 << 16: "Attack+",
	1 << 17: "Defense+",
	1 << 18: "Evasion+",
	1 << 19: "CritChance+",
	1 << 20: "Accuracy+"
}

func setup(lasts):
	for key in status_name_map:
		if status_type & key:
			status_name = status_name_map[key]
	remaining_turns = lasts
