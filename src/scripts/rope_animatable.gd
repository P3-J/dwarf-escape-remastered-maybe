extends AnimatableBody3D


enum Animations {
	swing,
	upndown,
	stay
}

@export var current_anim: Animations;


func _ready() -> void:
	return
	match (current_anim):
		Animations.swing:
			%swing.play("swing")
		Animations.upndown:
			%swing.play("upNdown")
		Animations.stay:
			return
