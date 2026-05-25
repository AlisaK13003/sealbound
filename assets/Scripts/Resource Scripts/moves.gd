extends Resource
class_name moves

@export_group("Basic Skill Information")
@export var move_name: String
@export var move_description : String
@export var move_sprite : Texture2D
@export_enum("low", "medium", "great") var attack_power
@export_range(0, 100) var accuracy: int = 100
@export var multi_hit : bool
@export var guaranteed_hit_count : int
@export var max_hit_count : int

@export var is_unlocked: bool = true
@export var is_magic_skill: bool = false

@export_range(1,3) var mana_cost : int = 1

@export_group("Status")
@export var does_status: bool
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
	"CritChance+:524288"
	) var status_type
	
@export_range(0,1) var chance_of_status_condition : float
@export var lasts_x_turns: int = 3

@export_group("Targets Who?")
@export var targets_party : bool
@export var is_skill_aoe : bool

#accuracy reductiuo, burn, slow, poison, defense reduction, momentum (orion special), regen, stun, stun immunity, attack + , def+ , evasion +, crit + .

@export_group("Party Healing")
# Determines whether the move heals, and whether by a percentage or int
@export var does_heal_party: bool
@export_enum("low", "moderate", "full") var amount_healed: int
@export var aoe_heal : bool

@export var normal_sprite: Texture2D
@export var pressed_sprite: Texture2D
@export var hover_sprite: Texture2D
@export var disabled_sprite: Texture2D
