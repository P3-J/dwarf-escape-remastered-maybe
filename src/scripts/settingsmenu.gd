extends TextureRect

@onready var mouse_slider: HSlider = $GridContainer/HBoxContainer/HSlider
@onready var mouse_value: Label = $GridContainer/HBoxContainer/MouseValue

@onready var music_slider: HSlider = $GridContainer/HBoxContainer2/MusicSlider
@onready var music_value: Label = $GridContainer/HBoxContainer2/MusicValue

@onready var audio_slider: HSlider = $GridContainer/HBoxContainer3/AudioSlider
@onready var audio_value: Label = $GridContainer/HBoxContainer3/AudioValue

@onready var resolution_option: OptionButton = $GridContainer/HBoxContainer4/OptionButton
@onready var fullscreen_check: CheckButton = $GridContainer/VBoxContainer/CheckButton

const COMMON_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1366, 768),
	Vector2i(1440, 900),
	Vector2i(1600, 900),
	Vector2i(1680, 1050),
	Vector2i(1920, 1080),
	Vector2i(1920, 1200),
	Vector2i(2560, 1080),
	Vector2i(2560, 1440),
	Vector2i(3440, 1440),
	Vector2i(3840, 2160),
]

var available_resolutions: Array[Vector2i] = []

func _ready() -> void:
	hide()

	_setup_sliders()
	_setup_resolution_options()

	# Sync the checkbox to the window's actual mode instead of
	# whatever the scene happens to have baked in, and do it
	# without signal so we don't trigger a mode change on open.
	fullscreen_check.set_pressed_no_signal(
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)

	if not resolution_option.item_selected.is_connected(_on_resolution_selected):
		resolution_option.item_selected.connect(_on_resolution_selected)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		Globalsettings.save_settings()
		MenuManager.back()


# ============================================================
# SLIDERS
# ============================================================

func _setup_sliders() -> void:

	# Mouse sensitivity
	mouse_slider.value = Globalsettings.mouse_sensitivity / 0.01
	mouse_value.text = str(mouse_slider.value)

	if not mouse_slider.value_changed.is_connected(_on_mouse_changed):
		mouse_slider.value_changed.connect(_on_mouse_changed)


	# Audio
	audio_slider.value = Globalsettings.audio_volume
	audio_value.text = str(audio_slider.value)

	if not audio_slider.value_changed.is_connected(_on_audio_changed):
		audio_slider.value_changed.connect(_on_audio_changed)


	# Music
	music_slider.value = Globalsettings.music_volume
	music_value.text = str(music_slider.value)

	if not music_slider.value_changed.is_connected(_on_music_changed):
		music_slider.value_changed.connect(_on_music_changed)


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


# ============================================================
# BACK
# ============================================================

func _on_back_pressed() -> void:
	Globalsettings.save_settings()
	MenuManager.back()


# ============================================================
# FULLSCREEN
# ============================================================

func _on_check_button_toggled(toggled_on: bool) -> void:

	if toggled_on:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)

	else:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)

		# Fullscreen may have left us rendering at a custom base
		# size (see _on_resolution_selected); drop back to the
		# project's default so windowed stretch scaling isn't
		# left using a leftover fullscreen resolution.
		get_window().content_scale_size = Vector2i.ZERO

		# Restore a sensible window position.
		_center_window()


	# Give Godot a frame to apply the mode change before
	# rebuilding the resolution list.
	await get_tree().process_frame

	_setup_resolution_options()

	Signalbus.settings_changed.emit()


# ============================================================
# RESOLUTION LIST
# ============================================================

func _setup_resolution_options() -> void:

	resolution_option.clear()
	available_resolutions.clear()

	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)

	# --------------------------------------------------------
	# BUILD RESOLUTION LIST
	#
	# Godot's DisplayServer has no API to query which video
	# modes the monitor actually supports, so we use a curated
	# list of common resolutions and only keep the ones that
	# fit within the monitor's native size.
	# --------------------------------------------------------

	for resolution in COMMON_RESOLUTIONS:

		if resolution.x <= screen_size.x and resolution.y <= screen_size.y:

			if not available_resolutions.has(resolution):
				available_resolutions.append(resolution)

	# Always offer the monitor's native resolution, even if it
	# isn't one of the common ones above.
	if screen_size != Vector2i.ZERO and not available_resolutions.has(screen_size):
		available_resolutions.append(screen_size)
	if available_resolutions.is_empty():

		push_warning(
			"Could not determine any usable resolutions for this monitor."
		)

		available_resolutions.append(DisplayServer.window_get_size())
	available_resolutions.sort_custom(_sort_resolutions)
	
	for resolution in available_resolutions:
		resolution_option.add_item(
			"%d x %d" % [
				resolution.x,
				resolution.y
			]
		)

	var current_resolution := _get_current_resolution()

	var selected_index := 0

	for i in range(available_resolutions.size()):

		if available_resolutions[i] == current_resolution:
			selected_index = i
			break

	if not available_resolutions.is_empty():
		resolution_option.select(selected_index)

func _get_current_resolution() -> Vector2i:

	var mode := DisplayServer.window_get_mode()

	if mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_FULLSCREEN:

		# window_get_size() always reports the monitor's native
		# size while fullscreen, since the OS window itself never
		# shrinks - the "resolution" we actually picked lives in
		# content_scale_size instead (falling back to the project's
		# default base size when we haven't overridden it).
		var scale_size := get_window().content_scale_size

		if scale_size != Vector2i.ZERO:
			return scale_size

		return Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")
		)

	return DisplayServer.window_get_size()

func _on_resolution_selected(index: int) -> void:

	if index < 0 or index >= available_resolutions.size():

		push_warning(
			"Invalid resolution index: %d" % index
		)

		return


	var resolution := available_resolutions[index]

	var mode := DisplayServer.window_get_mode()

	if mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_FULLSCREEN:

		# Both fullscreen modes always cover the monitor at its
		# native pixel size on Windows - DisplayServer.window_set_size()
		# is a no-op here, so resizing the actual OS window can't
		# give us a lower "resolution".
		#
		# Instead we change the base size the scene renders at and
		# let window/stretch/mode (see project settings) scale that
		# up/down to fill the real, native-sized window.
		get_window().content_scale_size = resolution

	elif mode == DisplayServer.WINDOW_MODE_WINDOWED:

		# Back to the project's default base resolution so stretch
		# scaling isn't left using a size we set while fullscreen.
		get_window().content_scale_size = Vector2i.ZERO

		DisplayServer.window_set_size(resolution)

		_center_window()


	Signalbus.settings_changed.emit()

func _center_window() -> void:

	var screen := DisplayServer.window_get_current_screen()

	var screen_size := DisplayServer.screen_get_size(screen)
	var window_size := DisplayServer.window_get_size()

	var position := (
		DisplayServer.screen_get_position(screen)
		+ (screen_size - window_size) / 2
	)

	DisplayServer.window_set_position(position)

func _sort_resolutions(a: Vector2i, b: Vector2i) -> bool:

	var area_a := a.x * a.y
	var area_b := b.x * b.y

	if area_a == area_b:
		return a.x < b.x

	return area_a < area_b


func _on_option_button_item_selected(index: int) -> void:
	pass # Replace with function body.
