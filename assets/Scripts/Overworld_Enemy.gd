extends Node2D

@onready var enemy_sprite : Sprite2D = $Enemy_Sprite
@onready var collision_area = $Area2D

@export var enemy_information : EnemyCombatant
@export var set_encounter : encounters
@onready var battle_scene = preload("res://scenes/Combat_Area/backgrounds/background.tscn")

func _ready():
	await get_tree().process_frame
	enemy_sprite.texture = enemy_information.enemy_sprite
	
func _on_area_2d_area_entered(area):
	if area.is_in_group("Overworld_Player"):
		Global.previous_coordinates = area.global_position
		get_tree().call_deferred("change_scene_to_packed", battle_scene)

func _on_area_2d_area_exited(area):
	if area.is_in_group("Overworld_Player"):
		pass
