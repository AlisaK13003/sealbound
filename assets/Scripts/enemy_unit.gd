extends Node2D

@onready var enemy_sprite = $Sprite2D
@onready var white_box = $ColorRect
@onready var mouse_area = $Area2D
@onready var health_bar = $PBar
@onready var planned_damage_label = $"Planned Damage"
@onready var selection_circle = $Sprite2D2
var stored_enemy : EnemyCombatant
var battle_parent
var selected_item
var where_is_item

func setup_enemy(enemy: EnemyCombatant):
	stored_enemy = enemy
	enemy_sprite.texture = enemy.enemy_sprite
	health_bar.max_value = enemy.enemy_stats.max_health
	health_bar.value = enemy.enemy_stats.health
	white_box.visible = false
	enemy.enemy_stats.health_changed.connect(update_health.bind())
	mouse_area.area_entered.connect(mouse_entered)
	mouse_area.area_exited.connect(mouse_exited)
	battle_parent = self.get_parent().get_parent()
	
func mouse_entered(area):
	var parent = area.get_parent()
	selected_item = parent.held_item
	where_is_item = parent.where_is_item
	
func mouse_exited(_area):
	selected_item = null

func _unhandled_input(event):
	if event is InputEventMouseButton and not event.pressed and selected_item != null:
		if selected_item.does_what == 1:
			battle_parent.active_enemies_data[battle_parent.enemy_enclosure.get_child(stored_enemy.enemy_position).get_instance_id()].use_item(selected_item)
			battle_parent.item_storage.get_child(where_is_item).visible = false
			selected_item = null
	
func update_health(current):
	health_bar.value = current
	if current == 0:
		self.visible = false
		
		for i in range(battle_parent.active_enemies_data.size()):
			if battle_parent.active_enemies_data.get(i) == stored_enemy:
				battle_parent.active_enemies_data.remove_at(i)
				return
func update_planned_damage(planned_damage):
	
	var current_health = stored_enemy.enemy_stats.health - int(planned_damage_label.text)
	
	if current_health <= 0:
		return false
	
	var damage_to_take = int(planned_damage_label.text) + planned_damage
	planned_damage_label.text = str(damage_to_take)
	return true
	
func reset_ui():
	planned_damage_label.text = ""
	selection_circle.visible = false
