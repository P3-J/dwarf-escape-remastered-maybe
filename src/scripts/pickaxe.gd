extends Node3D
class_name PickaxeManager

@onready var pickaxe_animation_player: AnimationPlayer = $PickaxeAnimationPlayer
@onready var boost_particles: GPUParticles3D = $BoostParticles

enum PickaxeState {
	IDLE,
	RUN,
	BOOST,
	JUMP
}

@export var c_state = PickaxeState.IDLE
var previous_state = c_state


func _process(delta: float) -> void:
	if c_state != previous_state:
		previous_state = c_state
		_enter_state(c_state)


func _enter_state(state: PickaxeState) -> void:
	match state:
		PickaxeState.IDLE:
			pickaxe_animation_player.play("idle")

		PickaxeState.RUN:
			pickaxe_animation_player.play("run")

		PickaxeState.BOOST:
			pickaxe_animation_player.play("boost")

		PickaxeState.JUMP:
			pickaxe_animation_player.play("jump")


func _on_pickaxe_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "boost":
		boost_particles.emitting = true
