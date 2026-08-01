extends Node3D
class_name Body_anim


@export var anim_player: AnimationPlayer;



func play_animation(name_anim: String) -> void:
	match name_anim:
		"run":
			anim_player.play("run");
		"reset":
			anim_player.play("RESET");


func is_playing_anim() -> bool:
	return anim_player.is_playing();
