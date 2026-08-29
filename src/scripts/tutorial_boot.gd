extends AnimationPlayer


func _ready() -> void:
	if Globalsettings.current_level == 0 and Globalsettings.first_boot_tutorial == true:
		_play_intro()

func _play_intro() -> void:
	Globalsettings.intro_playing = true
	animation_finished.connect(_on_intro_finished)
	play("intro")

func _on_intro_finished(anim_name: String) -> void:
	if anim_name == "intro":
		Globalsettings.intro_playing = false

func _unhandled_input(event: InputEvent) -> void:
	if Globalsettings.intro_playing and event.is_action_pressed("pause"):
		skip_intro()

func skip_intro() -> void:
	if not is_playing():
		return
	stop()
	var cam := get_node_or_null("../Camera3D")
	if cam:
		cam.current = false
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("intro_anim_unfreeze"):
		player.intro_anim_unfreeze(0)
	Globalsettings.intro_playing = false
