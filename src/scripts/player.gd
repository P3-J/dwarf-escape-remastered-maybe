extends CharacterBody3D
class_name PlayerDwarf

@export var player_head: Node3D

@export_group("Callables")
@export var hook_mesh_parent: RopeMesh
@export var yardman: YARDMAN

@export_group("Movement")
@export var speed: float = 10.0
@export var air_speed: float = 8.0
@export var jump_speed: float = 10.0
@export var accel: float = 10.0
@export var air_accel: float = 30.0
@export var friction: float = 6.0

@export_group("Gravity")
@export var gravity: float = -27.0
@export var max_fall_speed: float = -90.0

@export_group("Looky")
@export var mouse_sensitivity: float = 0.005
@export var pitch_min: float = -1.5
@export var pitch_max: float = 1.4

@export_group("Jumpy")
@export var coyote_time: float = 0.15

@export_group("Head Tilty")
@export var strafe_tilt_amount: float = deg_to_rad(4.0)
@export var wallrun_tilt_amount: float = deg_to_rad(15.0)
@export var mouse_tilt_amount: float = deg_to_rad(3.0)
@export var mouse_tilt_sensitivity: float = 0.02
@export var mouse_tilt_decay: float = 6.0
@export var tilt_smoothing: float = 8.0

@export_group("Wallrun stuffy")
@export var wall_run_enabled: bool = false
@export var wall_ray_right: RayCast3D
@export var wall_ray_left: RayCast3D
@export var wallrun_speed: float = 12.0
@export var wallrun_min_speed: float = 4.0
@export var wallrun_gravity: float = -4.0
@export var wallrun_attach_boost: float = 2.0
@export var wallrun_max_duration: float = 1.5
@export var wallrun_jump_speed: float = 10.0
@export var wallrun_jump_push: float = 6.0
@export var wallrun_cooldown: float = 0.3         # prevents instantly attaching to the wall again // maybe 2 values req?

@export_group("Crouch n Slide bby")
@export var standing_collision: CollisionShape3D
@export var crouching_collision: CollisionShape3D
@export var ceiling_check: RayCast3D
@export var standing_head_y: float = 1.6
@export var crouching_head_y: float = 0.9
@export var head_height_smoothing: float = 10.0
@export var crouch_speed: float = 5.0             # walk speed while crouched
@export var slide_enter_speed: float = 6.0        # min speed needed to trigger a slide
@export var slide_speed: float = 16.0             # speed set to when a slide starts
@export var slide_friction: float = 5.0           # deceleration
@export var slide_min_speed: float = 4.0          # end slide below this? is this needed
@export var slide_max_duration: float = 1.2       # cap it hard
@export var slide_pitch_amount: float = deg_to_rad(6.0)

@export_group("hook stuff")
@export var hookray: RayCast3D

@export_group("Swingin vars")
@export var min_rope_length: float = 2.0
@export var swing_gravity: float = -20.0
@export var swing_pump_accel: float = 25.0
@export var swing_air_damping: float = 0.15
@export var rope_pull_in_speed: float = 0.0

@export_group("Pickaxe Throw")
@export var pickaxe_throw_speed: float = 60.0
@export var pickaxe_retract_speed: float = 45.0

@export_group("Player stuff")
@export var PickAxe: PickaxeManager

@export_group("Pickaxe Boost")
@export var BoostRay: RayCast3D
@export var boost_str: float = 5.0
@export var boost_delay: float = 0.2

@export_group("Sound callables")
@export var slide_sound: AudioStreamPlayer;

enum HookState { IDLE, THROWING, ATTACHED, RETRACTING }
var hook_state: HookState = HookState.IDLE

var is_swinging: bool = false
var hook_anchor: Vector3 = Vector3.ZERO
var rope_length: float = 0.0
var is_pickaxe_boosting: bool = false
var has_pickaxe_boosted_air: bool = false

var pickaxe_pos: Vector3 = Vector3.ZERO
var pickaxe_original_parent: Node = null
var pickaxe_rest_transform: Transform3D = Transform3D.IDENTITY

var pitch: float = 0.0
var current_tilt: float = 0.0
var mouse_tilt: float = 0.0
var coyote_timer: float = 0.0
var slide_pitch: float = 0.0

var is_wall_running: bool = false
var wall_normal: Vector3 = Vector3.ZERO
var wall_side: int = 0
var wallrun_timer: float = 0.0
var wallrun_cooldown_timer: float = 0.0
var floor_jump_done: bool = false;
var in_boost_area: bool = false
var hook_target_in_range: bool = false

var is_crouching: bool = false
var is_sliding: bool = false
var slide_timer: float = 0.0
var player_frozen : bool = true;
var has_died: bool = false
var is_jumping: bool = false

# debug
var debug_mode: bool = false
const DEBUG_TELEPORT_POSITIONS := {
	KEY_1: Vector3(-11.34, 17.215, -16.747),
	KEY_2: Vector3(-2.736, 74.719, 111.878),
	KEY_3: Vector3(-2.736, 102.13, 161.084),
	KEY_4: Vector3(14.945, 155.497, 295.056),
}

@onready var walk_sfx: AudioStreamPlayer3D = $Audio/Walk

@onready var crosshair: TextureRect = $UI/Crosshair
const CROSSHAIR_NORMAL_TEX: Texture2D = preload("res://src/assets/ui/pickaxe_button_slider_assets/crosshair_normal.png")
const CROSSHAIR_HOOK_TEX: Texture2D = preload("res://src/assets/ui/pickaxe_button_slider_assets/crosshair_highlighted.png")

#time
@export_group("time stuff")
var start_time: int = 0
var is_stopwatch_running: bool = false
@export var timer_text: RichTextLabel
var minutes : int = 0
var seconds : int = 0
var milliseconds : int = 0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_sensitivity = Globalsettings.mouse_sensitivity
	_signal_setup()
	yardman.get_fastest_run()
	if PickAxe:
		pickaxe_original_parent = PickAxe.get_parent()
		pickaxe_rest_transform = PickAxe.transform

	start_countdown()

func _physics_process(delta: float) -> void:
	var input_dir := _get_input_direction()
	var direction := (global_transform.basis * input_dir).normalized()

	if player_frozen: return

	_update_wallrun(delta)
	_update_pickaxe_travel(delta)
	_update_rope_line()
	_update_crouch_and_slide(delta)
	_should_show_speed_lines(velocity)
	_update_hook_target_indicator()

	if in_boost_area: velocity.y += 2

	if is_sliding:
		_process_slide_movement(delta)
	elif is_wall_running:
		_process_wallrun_movement(delta)
	elif hook_state == HookState.ATTACHED:
		_process_swing_movement(delta, direction)
	elif is_on_floor():
		_process_ground_movement(delta, direction)
	else:
		_process_air_movement(delta, direction)

	move_and_slide()
	_update_coyote_timer(delta)
	_update_head_tilt(delta, input_dir)
	_update_head_height(delta)
	_process_pickaxe_state(direction)

func _process(delta: float) -> void:
	update_time()
	check_lava_level()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_0:
			debug_mode = !debug_mode
			print("Debug mode: ", "ON" if debug_mode else "OFF")
		elif debug_mode and DEBUG_TELEPORT_POSITIONS.has(event.keycode):
			velocity = Vector3.ZERO
			global_position = DEBUG_TELEPORT_POSITIONS[event.keycode]

	if player_frozen:
		return

	if event.is_action_pressed("jump"):
		jump()

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, pitch_min, pitch_max)
		if player_head:
			player_head.rotation.x = pitch + slide_pitch

		mouse_tilt = clamp(
			mouse_tilt - event.relative.x * mouse_tilt_sensitivity,
			-mouse_tilt_amount, mouse_tilt_amount
		)

	if event.is_action_pressed("restart"):
		yardman.finish_run(false)
		Signalbus.emit_signal("dont_play_sounds_on_reload")
		get_tree().reload_current_scene()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if !event.pressed:
			_release_hook()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			boost_off_surface()

func _process_ground_movement(delta: float, direction: Vector3) -> void:
	var current_speed := crouch_speed if is_crouching else speed
	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * current_speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, accel * delta)

	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)


func _process_air_movement(delta: float, direction: Vector3) -> void:
	var horiz_vel := Vector3(velocity.x, 0.0, velocity.z)
	var target_speed: float = max(air_speed, horiz_vel.length())
	var desired := direction * target_speed
	var add_vel := desired - horiz_vel

	if add_vel.length() > air_accel * delta:
		add_vel = add_vel.normalized() * air_accel * delta

	horiz_vel += add_vel
	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.z

	velocity.y = max(velocity.y + gravity * delta, max_fall_speed)



func _get_input_direction() -> Vector3:
	var direction := Vector3.ZERO
	if Input.is_action_pressed("up"):
		direction.z -= 1
	if Input.is_action_pressed("down"):
		direction.z += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("rmb"):
		_try_attach_hook()

	var on_floor: bool = is_on_floor()
	if direction == Vector3.ZERO or !on_floor or is_sliding:
		walk_sfx.stop()
	elif !walk_sfx.playing:
		walk_sfx.play()

	return direction.normalized()


func jump() -> void:
	if hook_state == HookState.ATTACHED:
		velocity.y = wallrun_jump_speed
		is_jumping = true
	if is_wall_running:
		velocity.y = wallrun_jump_speed
		velocity += wall_normal * wallrun_jump_push
		_end_wallrun()
		wallrun_cooldown_timer = wallrun_cooldown
	elif is_on_floor() or coyote_timer > 0.0 and !floor_jump_done:
		Signalbus.emit_signal("play_jump_sound")
		velocity.y = jump_speed
		floor_jump_done = true
		coyote_timer = 0.0
		is_sliding = false
		is_jumping = true
		is_crouching = false


func _update_crouch_and_slide(delta: float) -> void:
	var crouch_held := Input.is_action_pressed("crouch")

	if is_sliding:
		slide_timer += delta
		var speed_now := Vector2(velocity.x, velocity.z).length()
		var should_end := not crouch_held \
			or speed_now < slide_min_speed \
			or slide_timer > slide_max_duration \
			or not is_on_floor()
		if should_end:
			is_sliding = false
			is_crouching = crouch_held
	elif Input.is_action_just_pressed("crouch"):
		var horiz_speed := Vector2(velocity.x, velocity.z).length()
		if horiz_speed >= slide_enter_speed and is_on_floor():
			_start_slide()
		else:
			is_crouching = true
	elif is_crouching and not crouch_held and _can_stand():
		is_crouching = false

	if standing_collision:
		standing_collision.disabled = is_crouching or is_sliding
	if crouching_collision:
		crouching_collision.disabled = not (is_crouching or is_sliding)


func _start_slide() -> void:
	is_sliding = true
	is_crouching = true
	slide_timer = 0.0
	if not slide_sound.playing: slide_sound.play()

	var dir := Vector3(velocity.x, 0.0, velocity.z).normalized()
	if dir == Vector3.ZERO:
		dir = -global_transform.basis.z
	velocity.x = dir.x * slide_speed
	velocity.z = dir.z * slide_speed


func _process_slide_movement(delta: float) -> void:
	#PickAxe.c_state = PickaxeManager.PickaxeState.IDLE
	var horiz := Vector2(velocity.x, velocity.z)
	var speed_now: float = max(horiz.length() - slide_friction * delta, 0.0)
	horiz = horiz.normalized() * speed_now if horiz.length() > 0.0 else Vector2.ZERO
	velocity.x = horiz.x
	velocity.z = horiz.y

	if is_on_floor():
		velocity.y = -1.0 # stick to the floor a bit mybe? so groundslide possible
	else:
		velocity.y = max(velocity.y + gravity * delta, max_fall_speed)


func _update_head_height(delta: float) -> void:
	if not player_head:
		return
	var target_y := crouching_head_y if (is_crouching or is_sliding) else standing_head_y
	var pos := player_head.position
	pos.y = lerp(pos.y, target_y, clamp(head_height_smoothing * delta, 0.0, 1.0))
	player_head.position = pos

	var target_pitch := slide_pitch_amount if is_sliding else 0.0
	slide_pitch = lerp(slide_pitch, target_pitch, clamp(head_height_smoothing * delta, 0.0, 1.0))
	player_head.rotation.x = pitch + slide_pitch


func _update_head_tilt(delta: float, input_dir: Vector3) -> void:
	var target_tilt := 0.0
	if is_wall_running:
		target_tilt = wall_side * wallrun_tilt_amount
	else:
		target_tilt = -input_dir.x * strafe_tilt_amount

	mouse_tilt = lerp(mouse_tilt, 0.0, clamp(mouse_tilt_decay * delta, 0.0, 1.0))
	target_tilt += mouse_tilt

	current_tilt = lerp(current_tilt, target_tilt, clamp(tilt_smoothing * delta, 0.0, 1.0))

	if player_head:
		player_head.rotation.z = current_tilt



#################### WALLRUN STUFF ####################
func _update_wallrun(delta: float) -> void:
	if !wall_run_enabled:
		return

	if wallrun_cooldown_timer > 0.0:
		wallrun_cooldown_timer -= delta

	if is_on_floor():
		if is_wall_running:
			_end_wallrun()
		return

	var hit_right := wall_ray_right != null and wall_ray_right.is_colliding()
	var hit_left := wall_ray_left != null and wall_ray_left.is_colliding()

	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	var wants_forward := Input.is_action_pressed("up")

	var can_attach := (hit_right or hit_left) \
		and wallrun_cooldown_timer <= 0.0 \
		and wants_forward \
		and horiz_speed >= wallrun_min_speed

	if not can_attach:
		if is_wall_running:
			_end_wallrun()
		return

	if hit_right:
		wall_normal = wall_ray_right.get_collision_normal()
		wall_side = 1
	else:
		wall_normal = wall_ray_left.get_collision_normal()
		wall_side = -1

	if not is_wall_running:
		is_wall_running = true
		wallrun_timer = 0.0
		velocity.y = clamp(velocity.y, max_fall_speed, wallrun_attach_boost)

	wallrun_timer += delta
	if wallrun_timer > wallrun_max_duration:
		_end_wallrun()
		wallrun_cooldown_timer = wallrun_cooldown


func _process_wallrun_movement(delta: float) -> void:
	var wall_forward := wall_normal.cross(Vector3.UP).normalized()
	if wall_forward.dot(-global_transform.basis.z) < 0.0:
		wall_forward = -wall_forward

	velocity.x = wall_forward.x * wallrun_speed
	velocity.z = wall_forward.z * wallrun_speed

	velocity.y += wallrun_gravity * delta
	velocity.y = clamp(velocity.y, max_fall_speed, 0.0)


func _end_wallrun() -> void:
	is_wall_running = false
	wall_side = 0


#################### HOOK STUFF ####################
func _try_attach_hook() -> void:
	if hookray == null or hook_state != HookState.IDLE:
		return

	hookray.force_raycast_update()
	if not hookray.is_colliding():
		return

	var spot := hookray.get_collider()
	if spot == null or not is_valid_hookspot(spot):
		return

	Signalbus.emit_signal("play_pickaxe_throw_sound")
	spot = spot as Node3D
	#hook_anchor = hookray.get_collision_point()
	hook_anchor = spot.global_position;

	hook_state = HookState.THROWING
	is_swinging = false

	if PickAxe:
		PickAxe.top_level = true
		pickaxe_pos = PickAxe.global_position
	else:
		pickaxe_pos = global_position

	is_sliding = false
	is_crouching = false
	is_wall_running = false


func _release_hook() -> void:
	if hook_state == HookState.THROWING or hook_state == HookState.ATTACHED:
		hook_state = HookState.RETRACTING
	is_swinging = false


func is_valid_hookspot(spot: Node3D) -> bool:
	if spot.is_in_group("hookspot"):
		return true
	return false

func _update_hook_target_indicator() -> void:
	var in_range := false
	if hookray and hook_state == HookState.IDLE:
		hookray.force_raycast_update()
		if hookray.is_colliding():
			var spot := hookray.get_collider()
			in_range = spot != null and is_valid_hookspot(spot)

	if in_range != hook_target_in_range:
		hook_target_in_range = in_range
		Signalbus.emit_signal('player_in_hook_area', in_range)

func _update_pickaxe_travel(delta: float) -> void:
	match hook_state:
		HookState.THROWING:
			var to_target := hook_anchor - pickaxe_pos
			var dist := to_target.length()
			var step := pickaxe_throw_speed * delta
			PickAxe.scale = Vector3(3,3,3);
			PickAxe.rotation.z += 5;

			if step >= dist:
				pickaxe_pos = hook_anchor
				_arrive_at_hook()
			else:
				pickaxe_pos += to_target.normalized() * step

			if PickAxe:
				PickAxe.global_position = pickaxe_pos

		HookState.RETRACTING:
			Signalbus.emit_signal("play_rope_pull_sound", true)
			var target := _pickaxe_rest_global_position()
			var to_target := target - pickaxe_pos
			var dist := to_target.length()
			var step := pickaxe_retract_speed * delta

			if step >= dist:
				_finish_retract()
			else:
				pickaxe_pos += to_target.normalized() * step
				if PickAxe:
					PickAxe.global_position = pickaxe_pos
		_:
			pass


func _arrive_at_hook() -> void:
	hook_state = HookState.ATTACHED
	is_swinging = true
	rope_length = clamp(global_position.distance_to(hook_anchor), min_rope_length, abs(hookray.target_position.z))
	PickAxe.rotation.z = 0;
	Signalbus.emit_signal("play_pickaxe_hooked_sound")


func _finish_retract() -> void:
	hook_state = HookState.IDLE
	pickaxe_pos = Vector3.ZERO

	if PickAxe:
		PickAxe.top_level = false
		PickAxe.transform = pickaxe_rest_transform


func _pickaxe_rest_global_position() -> Vector3:
	if pickaxe_original_parent:
		return pickaxe_original_parent.global_transform * pickaxe_rest_transform.origin
	return global_position


func _update_rope_line() -> void:
	if hook_mesh_parent == null:
		return

	var rope_visible := hook_state != HookState.IDLE
	var end_point := hook_anchor if hook_state == HookState.ATTACHED else pickaxe_pos

	hook_mesh_parent._update_rope_visual(rope_visible, global_position, end_point)


func _process_swing_movement(delta: float, input_direction: Vector3) -> void:
	velocity.y += swing_gravity * delta

	if input_direction != Vector3.ZERO:
		# dir change
		velocity += input_direction * swing_pump_accel * delta

	if rope_pull_in_speed > 0.0 and Input.is_action_pressed("up"):
		rope_length = max(rope_length - rope_pull_in_speed * delta, min_rope_length)

	velocity *= (1.0 - swing_air_damping * delta)

	var to_player := global_position - hook_anchor
	var distance := to_player.length()

	if distance > rope_length and distance > 0.0:
		var radial := to_player / distance

		global_position = hook_anchor + radial * rope_length
		# i really dont understand the math here but it works? a bit clunky
		var radial_speed := velocity.dot(radial)
		if radial_speed > 0.0:
			velocity -= radial * radial_speed

	if Input.is_action_just_pressed("jump"):
		_release_hook()
		velocity.y = jump_speed * 0.75


#################### MISC STUFF ####################

func _update_coyote_timer(delta: float) -> void:
	if is_on_floor():
		floor_jump_done = false;
		has_pickaxe_boosted_air = true if is_pickaxe_boosting else false;
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta


func _can_stand() -> bool:
	print(ceiling_check, ceiling_check.is_colliding())
	if ceiling_check == null:
		return true
	return not ceiling_check.is_colliding()



#### PICKBOOST

func boost_off_surface():

	var charge_already_used := has_pickaxe_boosted_air

	if !BoostRay.is_colliding() or is_pickaxe_boosting or charge_already_used:
		return;

	has_pickaxe_boosted_air = true;
	Signalbus.emit_signal('play_pickaxe_boost_sound')
	is_pickaxe_boosting = true
	await get_tree().create_timer(boost_delay).timeout

	var ray_origin = BoostRay.global_transform.origin
	var ray_dir = (BoostRay.global_transform.basis * BoostRay.target_position).normalized()

	var distance = 10.0
	var opposite_point = ray_origin - ray_dir * distance

	var boost_vector = (opposite_point - global_transform.origin).normalized()
	boost_vector.y *= 0.5
	velocity = boost_vector * boost_str

	await get_tree().create_timer(boost_delay).timeout
	is_pickaxe_boosting = false

func _player_in_boost(state: bool) -> void:
	in_boost_area = state
	if in_boost_area:
		Signalbus.emit_signal('play_geyser_woosh')

@export var speed_lines_shader: ColorRect;
@export var speed_lines_max_speed: float = 10.0
var speed_lines_material: ShaderMaterial

func _should_show_speed_lines(vel: Vector3) -> void:
	var total_speed: float = Vector2(vel.x, vel.y).length()

	if not %windblow.playing:
		%windblow.play()
	else:
		%windblow.volume_db = -55 + total_speed

	if speed_lines_material == null and speed_lines_shader:
		speed_lines_material = speed_lines_shader.material as ShaderMaterial

	var should_show_lines: bool = is_sliding or not is_on_floor()
	var intensity: float = clamp(total_speed / speed_lines_max_speed, 0.0, 1.0) if should_show_lines else 0.0
	if speed_lines_material:
		speed_lines_material.set_shader_parameter("intensity", intensity)
	speed_lines_shader.visible = intensity > 0.0


func update_time():
	if is_stopwatch_running:
		var current_time = Time.get_ticks_msec()
		var elapsed_time = (current_time - start_time) / 1000.0
		timer_text.text = format_time(elapsed_time)

func check_lava_level():
	# Lava pools sit at independent, level-specific elevations (they're local
	# hazards, not one synchronized flood height), so only the nearest pool
	# is relevant here. Actual death-by-lava is handled by each pool's own
	# Area3D collision (see lava.gd) — this just drives the proximity audio.
	var lava_pools := get_tree().get_nodes_in_group('lava')
	if lava_pools.is_empty():
		return
	var nearest_pool: Node3D = lava_pools[0]
	var nearest_horizontal_dist := Vector2(global_position.x, global_position.z).distance_to(Vector2(nearest_pool.global_position.x, nearest_pool.global_position.z))
	for pool in lava_pools:
		var horizontal_dist = Vector2(global_position.x, global_position.z).distance_to(Vector2(pool.global_position.x, pool.global_position.z))
		if horizontal_dist < nearest_horizontal_dist:
			nearest_horizontal_dist = horizontal_dist
			nearest_pool = pool
	var vertical_distance = global_position.y - nearest_pool.global_position.y
	Signalbus.emit_signal('play_lava_rise_sound', vertical_distance)
	Signalbus.emit_signal('play_lava_hiss_sound', vertical_distance)

func format_time(elapsed_time: float) -> String:
	minutes = int(elapsed_time / 60)
	seconds = int(elapsed_time) % 60
	milliseconds = int((elapsed_time - int(elapsed_time)) * 1000)

	var minute_str = str(minutes).pad_zeros(2)
	var second_str = str(seconds).pad_zeros(2)
	var millisecond_str = str(milliseconds).pad_zeros(3)
	return minute_str + ":" + second_str + ":" + millisecond_str

func reached_end():
	Signalbus.minutes = minutes
	Signalbus.milliseconds = milliseconds
	Signalbus.seconds = seconds
	yardman.finish_run(true)
	get_tree().change_scene_to_file("res://src/scenes/score_screen.tscn")

func _signal_setup():
	Signalbus.connect('kill_player', _on_player_kill)
	Signalbus.connect('game_starts', _on_game_start)
	Signalbus.connect('player_in_boost', _player_in_boost)
	Signalbus.connect('player_in_hook_area', _on_player_in_hook_area)
	Signalbus.player_wins.connect(reached_end)
	Signalbus.settings_changed.connect(_on_settings_changed)
	Signalbus.connect('dont_play_sounds_on_reload', _on_dont_play_sounds_on_reload)

func _on_dont_play_sounds_on_reload() -> void:
	# These are owned/controlled directly by the player, so audio_manager's
	# own stop-list (which only covers its own exported players) can't reach
	# them — without this they keep playing for a frame or two into the
	# scene reload (most noticeable with windblow, since it plays continuously).
	walk_sfx.stop()
	slide_sound.stop()
	%windblow.stop()

func _on_settings_changed() -> void:
	mouse_sensitivity = Globalsettings.mouse_sensitivity

func _on_player_in_hook_area(in_range: bool) -> void:
	if crosshair:
		crosshair.texture = CROSSHAIR_HOOK_TEX if in_range else CROSSHAIR_NORMAL_TEX

func _on_game_start() -> void:
	player_frozen = false;
	start_speedrun_timer();
	yardman.start_new_run()
	Signalbus.emit_signal('make_lava_rise')

func unfreeze_player() -> void:
	Signalbus.emit_signal("game_starts")

func intro_anim_unfreeze(intro_nr: int) -> void:
	match intro_nr:
		0:
			Globalsettings.first_boot_tutorial = false
			start_countdown()

func start_countdown() -> void:
	if Globalsettings.first_boot_tutorial and Globalsettings.current_level == 0: return
	%UI.visible = true
	%countdownanim.play("countdown")

func start_speedrun_timer():
	start_time = Time.get_ticks_msec()
	is_stopwatch_running = true

func _on_player_kill() -> void:
	if !has_died:
		yardman.finish_run(false)
		speed_lines_shader.visible = false
		has_died = true
		Signalbus.kill_player.emit()


func _process_pickaxe_state(dir: Vector3) -> void:
	if is_on_floor():
		if dir != Vector3.ZERO and !is_sliding:
			PickAxe.c_state = PickaxeManager.PickaxeState.RUN
		else:
			PickAxe.c_state = PickaxeManager.PickaxeState.IDLE
	if is_pickaxe_boosting:
		PickAxe.c_state = PickaxeManager.PickaxeState.BOOST
	if is_jumping:
		PickAxe.c_state = PickaxeManager.PickaxeState.JUMP
		is_jumping = !is_jumping
