extends Control

var panel: Panel

@onready var selection_arrow: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_differential_label: Label = $With_HP/Health_Differential

var should_show_hp: bool

func _ready():
	GlobalCombatInformation.check_player_values.connect(now_an_active_member)
	
func now_an_active_member():
	if stored_combatant == null:
		return
	if GlobalCombatInformation.check_if_member_is_active(stored_combatant):
		if should_show_hp:
			$With_HP/TextureRect.visible = true
			health_label.text = "HP:" + str(stored_combatant.actual_stats.health) + "/" + str(stored_combatant.actual_stats.max_health)
		else:
			$Without_HP/TextureRect.visible = true
	else:
		if should_show_hp:
			$With_HP/TextureRect.visible = false
			health_label.text = "HP:" + str(stored_combatant.actual_stats.health) + "/" + str(stored_combatant.actual_stats.max_health)
		else:
			$Without_HP/TextureRect.visible = false
	
var stored_combatant
var health_label
func _setup(combatant: generic_combatants, index: int, show_hp: bool = false):
	stored_combatant = combatant
	var name_ = $Without_HP/Label
	var sprite = $Without_HP/Sprite2D
	health_label = $With_HP/HBoxContainer/Label3
	
	panel = $Without_HP/Panel
	should_show_hp = show_hp
	if show_hp:
		name_ = $With_HP/HBoxContainer/Label2
		
		sprite = $With_HP/Sprite2D
		panel = $With_HP/Panel
		$With_HP.visible = true
		$Without_HP.visible = false
	else:
		$With_HP.visible = false
		$Without_HP.visible = true
	
	if show_hp:
		pass
	else:
		pass
		
	if combatant == null:
		return
	if not show_hp:
		name_.text = combatant.combatant_name
	else:
		name_.text = combatant.combatant_name
		health_label.text = "HP:" + str(combatant.actual_stats.health) + "/" + str(combatant.actual_stats.max_health)
	sprite.texture = combatant.party_member_portrait
	now_an_active_member()
	
func update_highlight(highlight):
	if highlight:
		selection_arrow.play("default")
		selection_arrow.visible = true
	else:
		selection_arrow.visible = false
		selection_arrow.stop()

func update_damage_label(health_differential):
	health_differential_label.modulate = Color.LAWN_GREEN
	health_differential_label.text = str(int(health_differential))
	var previous_y_level =	health_differential_label.position.y
	health_differential_label.visible = true

	var tween = create_tween()
	
	tween.tween_property(health_differential_label, "position", Vector2(health_differential_label.position.x, previous_y_level - 20.0), 0.3)
	
	await tween.finished

	await get_tree().create_timer(0.1).timeout

	tween = create_tween()
	tween.tween_property(health_differential_label, "position", Vector2(health_differential_label.position.x, previous_y_level + 10.0), 0.6)
	await tween.finished
	health_differential_label.visible = false
	health_differential_label.position.y = previous_y_level
	health_differential_label.modulate = Color.WHITE_SMOKE
	await get_tree().create_timer(0.5).timeout
