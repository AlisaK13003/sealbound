extends CollisionShape2D

@onready var party_sprite = $Party_Member
@onready var mouse_area = $Mouse_Spot
@onready var selection_arrow = $Selection_Arrow
@onready var death_x = $X
@onready var line = $Line
@onready var p_bar = $PBar
@onready var health_text = $PBar/Health_Num

func setup(member: PartyMember):
	party_sprite = member.player_sprite
	update_health(member.player_stats.health, member.player_stats.max_health)

func update_health(current_health, maximum):
	print(current_health, maximum)
	p_bar.max_value = maximum
	p_bar.value = current_health
	health_text.text = str(current_health)
	if current_health <= 0:
		death_x.visible = true
		
func set_selected(is_selected : bool):
	selection_arrow.visible = is_selected
	
func disable():
	visible = false
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
