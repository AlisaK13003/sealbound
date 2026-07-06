extends Control

var panel: Panel

func _ready():
	GlobalCombatInformation.check_player_values.connect(now_an_active_member)
	
func now_an_active_member():
	if stored_combatant == null:
		return
	if GlobalCombatInformation.check_if_member_is_active(stored_combatant):
		$TextureRect.visible = true
	else:
		$TextureRect.visible = false
	
var stored_combatant
	
func _setup(combatant: generic_combatants, index: int, show_hp: bool = false):
	stored_combatant = combatant
	var name_ = $Label
	var sprite = $Sprite2D
	
	panel = $Panel
	
	if show_hp:
		pass
	else:
		pass
		
	if combatant == null:
		return
	name_.text = combatant.combatant_name
	sprite.texture = combatant.party_member_portrait
	now_an_active_member()
	
func update_highlight(highlight):
	var stylebox = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

	if highlight:
		stylebox.bg_color = Color.AQUA
	else:
		stylebox.bg_color = Color.GRAY

	panel.add_theme_stylebox_override("panel", stylebox)
