extends Control

# lava_meter's texture_under/texture_progress ship in three baked
# sizes (full, "small" = half, "smallest" = quarter). Below this
# window height we switch to the quarter-size art instead of shrinking
# the full-res texture further via scale, so it stays crisp and light
# on memory at low resolutions.
const SMALLEST_TEXTURE_HEIGHT_THRESHOLD := 768.0
const SMALLEST_SCALE_FACTOR := 4.0 # smallest textures are 1/4 the size of the full-res ones

const TEXTURE_UNDER_SMALLEST := preload("res://src/assets/ui/basic/LavaMeterEmptysmallest.png")
const TEXTURE_PROGRESS_SMALLEST := preload("res://src/assets/ui/basic/LavameterFilledsmallest.png")

@onready var lava_meter = $LavaMeter
@onready var player_indicator = $LavaMeter/PlayerPos
var exit: Node3D
var lava: Node3D
var player
var min_height = 0
var min_height_offset = -10
var max_height = 85

# Texture assigned in the scene (full-res) and the scale it was
# hand-tuned at - used as the baseline when swapping back from the
# smallest variant.
var _texture_under_full: Texture2D
var _texture_progress_full: Texture2D
var _base_scale: Vector2
var _using_smallest_texture := false

func _ready() -> void:
	lava = get_tree().get_first_node_in_group("lava")
	exit = get_tree().get_first_node_in_group("exit")
	player = get_tree().get_first_node_in_group("player")

	assert(lava, "there is no node in group 'lava' in this level")
	assert(exit, "there is no node in group 'exit' in this level")
	assert(player, "there is no node in group 'player' in this level")

	min_height = lava.global_transform.origin.y + min_height_offset
	max_height = exit.global_transform.origin.y

	_texture_under_full = lava_meter.texture_under
	_texture_progress_full = lava_meter.texture_progress
	_base_scale = lava_meter.scale

	Signalbus.settings_changed.connect(_update_texture_quality)
	_update_texture_quality()


func _update_texture_quality() -> void:
	var use_smallest := ThemeScaler.current_window_height() <= SMALLEST_TEXTURE_HEIGHT_THRESHOLD

	if use_smallest == _using_smallest_texture:
		return

	_using_smallest_texture = use_smallest

	if use_smallest:
		lava_meter.texture_under = TEXTURE_UNDER_SMALLEST
		lava_meter.texture_progress = TEXTURE_PROGRESS_SMALLEST
		# smallest textures are 1/4 the pixel size of the full-res ones,
		# so scale up by the same factor to land on the same on-screen size.
		lava_meter.scale = _base_scale * SMALLEST_SCALE_FACTOR
	else:
		lava_meter.texture_under = _texture_under_full
		lava_meter.texture_progress = _texture_progress_full
		lava_meter.scale = _base_scale

func _process(_delta: float) -> void:
	
	if (!lava or !player or !exit):
		print("Missing lava, exit or player for the lava meter to function")
		return

	var lava_height = lava.global_transform.origin.y - min_height
	var player_height = player.global_transform.origin.y - min_height

	var lava_percentage = round((lava_height / (max_height - min_height)) * 10000) / 100
	lava_meter.value = lava_percentage

	var player_percentage = round((player_height / (max_height - min_height)) * 10000) / 100

	var max_pos = lava_meter.position.y
	var min_pos = max_pos + lava_meter.size.y
	player_indicator.position.y = min_pos - (((min_pos - max_pos) / 100) * player_percentage)
	player_indicator.position.y -= 26
