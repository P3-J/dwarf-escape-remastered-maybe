extends Node3D
@onready var pickaxe_animation_player: AnimationPlayer = $PickaxeAnimationPlayer
@export var boost_anim_playing = false
var jump_anim_playing = false
var boost_spent_pose_active = false
@onready var boost_particles: GPUParticles3D = $BoostParticles

func _ready() -> void:
	play_idle_animation()

func play_idle_animation() -> void:
	if not boost_anim_playing:
		boost_spent_pose_active = false
		pickaxe_animation_player.play("idle")

func play_run_animation() -> void:
	if not boost_anim_playing:
		boost_spent_pose_active = false
		pickaxe_animation_player.play("run")

func play_jump_animation() -> void:
	if not boost_anim_playing:
		#jump_anim_playing = true
		boost_spent_pose_active = false
		pickaxe_animation_player.play("jump")

func play_boost_animation() -> void:
	boost_anim_playing = true
	boost_spent_pose_active = false
	pickaxe_animation_player.play("boost")

func show_boost_unavailable() -> void:
	if boost_anim_playing or jump_anim_playing or boost_spent_pose_active:
		return
	boost_spent_pose_active = true
	pickaxe_animation_player.play("boost")
	pickaxe_animation_player.seek(pickaxe_animation_player.current_animation_length, true)
	pickaxe_animation_player.stop(true)

func no_animation() -> void:
	if not boost_anim_playing and not jump_anim_playing:
		boost_spent_pose_active = false
		pickaxe_animation_player.play("RESET")

func _on_pickaxe_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "boost":
		boost_anim_playing = false
		boost_particles.emitting = true
	if anim_name == "jump":
		jump_anim_playing = false
