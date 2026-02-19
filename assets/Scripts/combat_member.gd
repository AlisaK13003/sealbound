extends CollisionShape2D

@onready var party_sprite = $Party_Member
@onready var mouse_area = $Mouse_Spot
@onready var selection_arrow = $Selection_Arrow
@onready var death_x = $X
@onready var line = $Line
@onready var p_bar = $PBar
@onready var health_text = $PBar/Health_Num
var stored_member
var highlight_shader
var selected_item : Items
var where_is_item

@onready var battle_parent = self.get_parent().get_parent()

var battle_state = {
	"is_dead": false,
	"waiting_to_perform": false,
	"has_acted": false 
}

func setup(member: PartyMember):
	stored_member = member
	party_sprite.texture = member.player_sprite
	highlight_shader = party_sprite.material.duplicate()
	party_sprite.material = null
	update_health(member.player_stats.health, member.player_stats.max_health)
	mouse_area.area_entered.connect(mouse_entered)
	mouse_area.area_exited.connect(mouse_exited)
	
func mouse_entered(area):
	var parent = area.get_parent()
	selected_item = parent.held_item
	where_is_item = parent.where_is_item
	
func mouse_exited(area):
	selected_item = null

func _unhandled_input(event):
	if event is InputEventMouseButton and not event.pressed and selected_item != null:
		if selected_item.does_what == 2:
			battle_parent.party_members[stored_member.current_battle_position].use_item(selected_item)
			battle_parent.item_storage.get_child(where_is_item).visible = false
			selected_item = null
		
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
	if battle_state["has_acted"]:
		party_sprite.material = null
		line.visible = false
	if battle_state["waiting_to_perform"]:
		party_sprite.material = highlight_shader
		line.visible = false
	else:
		party_sprite.material = null
		line.visible = false

func reset_states():
	battle_state["is_dead"] = false
	battle_state["has_acted"] = false
	battle_state["waiting_to_perform"] = false

func disable():
	visible = false
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
