extends Node

## Rescales the shared UI theme's font sizes to match the current
## window/resolution.
##
## The project's stretch settings (window/stretch/mode = "viewport",
## aspect = "expand") keep pixel density constant when the window is
## resized - the canvas just shows more or less area instead of
## scaling everything, which is what we want for gameplay. That means
## menu text doesn't shrink or grow on its own when the player picks a
## different resolution in the settings menu, so we do it here by
## hand, driven off the same Signalbus.settings_changed signal
## settingsmenu.gd already emits on every resolution/fullscreen change.

## Emitted whenever the UI scale factor is recomputed, so nodes that
## aren't covered by the Theme (TextureProgressBar, TextureRect, any
## node relying on its own `scale`) can rescale themselves the same
## way - see lava_meter.gd for an example. `window_height` is handed
## along too so listeners that need an absolute threshold (e.g.
## "swap to a lower-res texture below 768p") don't have to duplicate
## current_window_height()'s fullscreen/windowed handling.
signal ui_rescaled(scale: float, window_height: float)

const THEME_PATH := "res://src/assets/ui/theme.tres"
const BASE_HEIGHT := 1080.0
const MIN_FONT_SIZE := 1

## Current window height / BASE_HEIGHT. Read this for the initial
## value instead of assuming 1.0, since _ready() may run before yours.
var ui_scale: float = 1.0

var _theme: Theme
var _base_sizes: Dictionary = {} # { [type, font_size_prop]: original_size }


func _ready() -> void:
	_theme = load(THEME_PATH)

	if _theme == null:
		push_warning("ThemeScaler: could not load theme at %s" % THEME_PATH)
		return

	for type in _theme.get_type_list():
		for prop in _theme.get_font_size_list(type):
			_base_sizes[[type, prop]] = _theme.get_font_size(prop, type)

	Signalbus.settings_changed.connect(_rescale)

	_rescale()


func _rescale() -> void:
	var window_height := current_window_height()
	ui_scale = window_height / BASE_HEIGHT

	if _theme != null:
		for key in _base_sizes:
			var type: String = key[0]
			var prop: String = key[1]
			var base_size: int = _base_sizes[key]

			_theme.set_font_size(prop, type, maxi(MIN_FONT_SIZE, roundi(base_size * ui_scale)))

	ui_rescaled.emit(ui_scale, window_height)


func current_window_height() -> float:

	var mode := DisplayServer.window_get_mode()

	if mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_FULLSCREEN:

		# Fullscreen "resolution" is simulated via content_scale_size
		# rather than an actual OS window resize - see
		# settingsmenu.gd's _get_current_resolution() for the same logic.
		var scale_size := get_window().content_scale_size

		if scale_size != Vector2i.ZERO:
			return float(scale_size.y)

		return float(ProjectSettings.get_setting("display/window/size/viewport_height"))

	return float(DisplayServer.window_get_size().y)
