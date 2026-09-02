extends Control

@onready var mouse_slider = $TextureRect/HBoxContainer/HBoxContainer/HBoxContainer/HSlider
@onready var mouse_value = $TextureRect/HBoxContainer/HBoxContainer/HBoxContainer/MouseValue
@onready var music_slider: HSlider = $TextureRect/HBoxContainer/HBoxContainer/HBoxContainer2/MusicSlider
@onready var audio_slider: HSlider = $TextureRect/HBoxContainer/HBoxContainer/HBoxContainer3/AudioSlider
@onready var music_value: Label = $TextureRect/HBoxContainer/HBoxContainer/HBoxContainer2/MusicValue
@onready var audio_value: Label = $TextureRect/HBoxContainer/HBoxContainer/HBoxContainer3/AudioValue
@onready var resolution_option: OptionButton = $TextureRect/HBoxContainer/HBoxContainer/HBoxContainer5/OptionButton

const COMMON_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(800, 600),
	Vector2i(1024, 768),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

var available_resolutions: Array[Vector2i] = []

signal settings_changed()

func _ready() -> void:
	hide()
	
	mouse_slider.value = Globalsettings.mouse_sensitivity / 0.01
	mouse_value.text = str(mouse_slider.value)
	mouse_slider.value_changed.connect(_on_mouse_changed)

	audio_slider.value = Globalsettings.audio_volume
	audio_value.text = str(audio_slider.value)
	audio_slider.value_changed.connect(_on_audio_changed)

	music_slider.value = Globalsettings.music_volume
	music_value.text = str(music_slider.value)
	music_slider.value_changed.connect(_on_music_changed)

	_setup_resolution_options()
	if not resolution_option.item_selected.is_connected(_on_option_button_item_selected):
		resolution_option.item_selected.connect(_on_option_button_item_selected)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		MenuManager.back()
		Globalsettings.save_settings()


func _on_mouse_changed(value: float) -> void:
	Globalsettings.mouse_sensitivity = value * 0.01
	mouse_value.text = str(value)
	Signalbus.settings_changed.emit()

func _on_audio_changed(value: float) -> void:
	Globalsettings.audio_volume = value
	audio_value.text = str(value)
	Signalbus.settings_changed.emit()

func _on_music_changed(value: float) -> void:
	Globalsettings.music_volume = value
	music_value.text = str(value)
	Signalbus.settings_changed.emit()

# BACK BUTTON
func _on_back_pressed() -> void:
	Globalsettings.save_settings()
	MenuManager.back()

func _on_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		# Go fullscreen
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Go back to windowed
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _setup_resolution_options() -> void:
	resolution_option.clear()
	available_resolutions.clear()

	var screen_size: Vector2i = DisplayServer.screen_get_size()
	for resolution in COMMON_RESOLUTIONS:
		if resolution.x <= screen_size.x and resolution.y <= screen_size.y:
			available_resolutions.append(resolution)

	if available_resolutions.is_empty():
		available_resolutions.append(screen_size)

	var current_size: Vector2i = DisplayServer.window_get_size()
	if current_size.x <= screen_size.x and current_size.y <= screen_size.y and not available_resolutions.has(current_size):
		available_resolutions.append(current_size)

	for resolution in available_resolutions:
		resolution_option.add_item("%dx%d" % [resolution.x, resolution.y])

	var selected_index := 0
	for i in range(available_resolutions.size()):
		if available_resolutions[i] == current_size:
			selected_index = i
			break

	resolution_option.select(selected_index)


func _on_option_button_item_selected(index: int) -> void:
	if index < 0 or index >= available_resolutions.size():
		push_warning("Invalid resolution index selected: %d" % index)
		return

	DisplayServer.window_set_size(available_resolutions[index])
	Signalbus.settings_changed.emit()
