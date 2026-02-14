extends Node2D

@onready var enemy_sprite = $Sprite2D
@onready var white_box = $ColorRect
@onready var mouse_area = $Area2D
@onready var health_bar = $PBar

func setup_enemy(enemy: EnemyCombatant):
	enemy_sprite.texture = enemy.enemy_sprite
	health_bar.max_value = enemy.enemy_stats.max_health
	health_bar.value = enemy.enemy_stats.health
	white_box.visible = false
