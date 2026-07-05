extends Node3D

@onready var animator = $AnimationPlayer
@onready var default_chest_state = $Chest7

@onready var particles = $GPUParticles3D

var player_in_range: bool = false
var has_chest_been_opened: bool = false

signal chest_opened

func _ready():
	animator.stop()
	default_chest_state.visible = true

func _input(_event):
	if player_in_range and not has_chest_been_opened:
		if Global.get_input_mapping("confirm"):
			var anim: Animation = animator.get_animation("Chest_Open")
			anim.loop_mode = Animation.LOOP_NONE
			animator.play("Chest_Open")
			await animator.animation_finished
			particles.emitting = true
			has_chest_been_opened = true
			chest_opened.emit()

func _on_area_3d_body_entered(body):
	if body.is_in_group("3D_Player"): 
		player_in_range = true

func _on_area_3d_body_exited(body):
	if body.is_in_group("3D_Player"): 
		player_in_range = false
