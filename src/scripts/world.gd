extends Node3D

@export var level_nr: int

func _ready() -> void:
	Globalsettings.current_level = level_nr
