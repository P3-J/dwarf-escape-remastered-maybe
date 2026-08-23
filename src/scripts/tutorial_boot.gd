extends AnimationPlayer


func _ready() -> void:
	if Globalsettings.current_level == 0 and Globalsettings.first_boot_tutorial == true:
		_play_intro()

func _play_intro() -> void:
	play("intro")
