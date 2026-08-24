extends Control

@export var loading_screen: LevelLoader

func _on_button_pressed() -> void:
	MenuManager.back()


func _on_tutorial_pressed() -> void:
	Globalsettings.current_level = 0
	loading_screen.next_scene_path = "res://src/levels/tutorial.tscn"
	loading_screen.load_next_scene_async()
	loading_screen.visible = true
	pass


#func _on_lvl_2_pressed() -> void:
	#loading_screen.next_scene_path = "res://src/levels/lv2.tscn"
	#loading_screen.load_next_scene_async()
	#loading_screen.visible = true
	#hide()


func _on_texture_button_pressed() -> void:
	MenuManager.back()


func _on_lvl_3_pressed() -> void:
	Globalsettings.current_level = 1
	loading_screen.next_scene_path = "res://src/levels/lv3.tscn"
	loading_screen.load_next_scene_async()
	loading_screen.visible = true
