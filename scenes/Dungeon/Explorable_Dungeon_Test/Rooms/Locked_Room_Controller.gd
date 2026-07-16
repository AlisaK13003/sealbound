extends Node3D

var requires_boss_key: bool = false
var requires_normal_key: bool = false

func _ready():
	$Area3D.connect("body_entered", _body_entered)

var boss_key_path = "res://assets/tile sheets/Dungeon_Boss_Room_Key.png"
var normal_key_path = "res://assets/tile sheets/Dungeon_Special_Room_Key.png"

func _setup(boss_key):
	print("SETUP Run")
	if boss_key:
		print("BOSS KEY")
		requires_boss_key = true
		$Sprite3D2/Sprite3D3.texture = load(boss_key_path)
		$Sprite3D2/Sprite3D3.texture = load(boss_key_path)
		$Sprite3D2/Sprite3D3.texture = load(boss_key_path)
		$Sprite3D/Sprite3D.texture = load(boss_key_path)
	else:
		print("NORMAL KEY")
		requires_normal_key = true

func _body_entered(body):
	if body.is_in_group("3D_Player"):
		if requires_boss_key and GlobalCombatInformation.holding_boss_key > 0:
			unlock()
			GlobalCombatInformation.holding_boss_key -= 1
			GlobalCombatInformation.obtained_or_used_key.emit()
		elif requires_normal_key and GlobalCombatInformation.holding_basic_room_key > 0:
			unlock()
			GlobalCombatInformation.holding_basic_room_key -= 1
			GlobalCombatInformation.obtained_or_used_key.emit()

func unlock():
	self.visible = false
	for clutter_child in find_children("*", "CollisionShape3D", true, false):
		clutter_child.set_deferred("disabled", true)
	
func lock():
	self.visible = true
	for clutter_child in find_children("*", "CollisionShape3D", true, false):
		clutter_child.set_deferred("disabled", false)
