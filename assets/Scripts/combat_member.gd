extends CollisionShape2D

@onready var party_sprite = $Party_Member
@onready var mouse_area = $Mouse_Spot
@onready var selection_arrow = $Selection_Arrow
@onready var death_x = $X
@onready var line = $Line
@onready var p_bar = $PBar
@onready var health_text = $PBar/Health_Num
var highlight_shader

var battle_state = {
	"is_dead": false,
	"waiting_to_perform": false,
	"has_acted": false 
}

func setup(member: PartyMember):
	party_sprite.texture = member.player_sprite
	highlight_shader = party_sprite.material.duplicate()
	party_sprite.material = null
	update_health(member.player_stats.health, member.player_stats.max_health)
	
func update_health(current_health, maximum):
	p_bar.max_value = maximum
	p_bar.value = current_health
	health_text.text = str(current_health)
	if current_health <= 0:
		death_x.visible = true
	
func update_state():
	if battle_state["is_dead"]:
		death_x.visible = true
		party_sprite.material = null
		line.visible = false
	elif battle_state["has_acted"]:
		party_sprite.material = null
		line.visible = false
	elif battle_state["waiting_to_perform"]:
		party_sprite.material = highlight_shader
		line.visible = false
	else:
		party_sprite.material = null
		line.visible = false

func disable():
	visible = false
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
