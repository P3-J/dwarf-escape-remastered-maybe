extends Node3D


enum DSTEXT {
	spacebar,
	pickaxe_boost,
	crouch,
	hook,
}

@export var DisplayedText: DSTEXT;

func _ready() -> void:
	
	match DisplayedText:
		DSTEXT.spacebar:
			%spacebar.visible = true
		DSTEXT.pickaxe_boost:
			%pickboost.visible = true
		DSTEXT.crouch:
			%crouch.visible = true
		DSTEXT.hook:
			%hook.visible = true
	
