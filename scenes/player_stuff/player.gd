extends CharacterBody3D

@export var player_head: Node3D
@export var body_anim: Body_anim;

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

var is_crouching: bool = false
var is_sliding: bool = false
var slide_timer: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	var input_dir := _get_input_direction()
	var direction := (global_transform.basis * input_dir).normalized()

	_update_wallrun(delta)
	_update_coyote_timer(delta)
	_update_crouch_and_slide(delta)

	if is_sliding:
		_process_slide_movement(delta)
	elif is_wall_running:
		_process_wallrun_movement(delta)
	elif is_on_floor():
		_process_ground_movement(delta, direction)
	else:
		_process_air_movement(delta, direction)

	move_and_slide()
	_update_head_tilt(delta, input_dir)
	_update_head_height(delta)


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
	var desired := direction * air_speed
	var add_vel := desired - horiz_vel

	if add_vel.length() > air_accel * delta:
		add_vel = add_vel.normalized() * air_accel * delta

	horiz_vel += add_vel
	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.z

	velocity.y = max(velocity.y + gravity * delta, max_fall_speed)


func _update_coyote_timer(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta


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

	if direction.length() > 0 and is_on_floor():
		if !body_anim.is_playing_anim():
			body_anim.play_animation("run")
	else:
		body_anim.play_animation("reset")

	return direction.normalized()


func _input(event: InputEvent) -> void:
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


func jump() -> void:
	if is_wall_running:
		velocity.y = wallrun_jump_speed
		velocity += wall_normal * wallrun_jump_push
		_end_wallrun()
		wallrun_cooldown_timer = wallrun_cooldown
	elif is_on_floor() or coyote_timer > 0.0:
		velocity.y = jump_speed
		coyote_timer = 0.0
		is_sliding = false
		is_crouching = false



func _update_wallrun(delta: float) -> void:
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

	var dir := Vector3(velocity.x, 0.0, velocity.z).normalized()
	if dir == Vector3.ZERO:
		dir = -global_transform.basis.z
	velocity.x = dir.x * slide_speed
	velocity.z = dir.z * slide_speed


func _process_slide_movement(delta: float) -> void:
	var horiz := Vector2(velocity.x, velocity.z)
	var speed_now: float = max(horiz.length() - slide_friction * delta, 0.0)
	horiz = horiz.normalized() * speed_now if horiz.length() > 0.0 else Vector2.ZERO
	velocity.x = horiz.x
	velocity.z = horiz.y

	if is_on_floor():
		velocity.y = -1.0 # stick to the floor a bit mybe? so groundslide possible
	else:
		velocity.y = max(velocity.y + gravity * delta, max_fall_speed)


func _can_stand() -> bool:
	if ceiling_check == null:
		return true
	return not ceiling_check.is_colliding()


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
