extends Node3D

@export var level_nr: int

func _ready() -> void:
	Globalsettings.current_level = level_nr
	
	return
	if level_nr == 1:
		Signalbus.emit_signal("play_ambient_lv3")
