extends Node2D

@onready var enemy_sprite = $Sprite2D
@onready var white_box = $ColorRect
@onready var mouse_area = $Area2D
@onready var health_bar = $PBar
@onready var planned_damage_label = $"Planned Damage"
var stored_enemy : EnemyCombatant

func setup_enemy(enemy: EnemyCombatant):
	stored_enemy = enemy
	enemy_sprite.texture = enemy.enemy_sprite
	health_bar.max_value = enemy.enemy_stats.max_health
	health_bar.value = enemy.enemy_stats.health
	white_box.visible = false
	enemy.enemy_stats.health_changed.connect(update_health.bind())
	
func update_health(current):
	health_bar.value = current

func update_planned_damage(planned_damage):
	
	var current_health = stored_enemy.enemy_stats.health - int(planned_damage_label.text)
	
	if current_health <= 0:
		return false
	
	var damage_to_take = int(planned_damage_label.text) + planned_damage
	planned_damage_label.text = str(damage_to_take)
	return true
	
func reset_ui():
	planned_damage_label.text = ""
