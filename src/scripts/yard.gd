extends Node
class_name YARDMAN

@export var sample_interval: float = 0.25
@export var player_node: Node3D

var current_run: YARDDATA
var time_elapsed: float = 0.0
var sample_timer: float = 0.0
var is_recording: bool = false

func start_new_run() -> void:
	var RunScript = load("res://src/yard/yarddata.gd")

	current_run = RunScript.new()

	current_run.run_id = "run_" + str(Time.get_unix_time_from_system())
	current_run.positions.clear()
	current_run.timestamps.clear()

	time_elapsed = 0.0
	sample_timer = 0.0
	is_recording = true

	_record_position()

func _process(delta: float) -> void:
	if not is_recording:
		return

	time_elapsed += delta
	sample_timer += delta

	if sample_timer >= sample_interval:
		sample_timer -= sample_interval
		_record_position()

func _record_position() -> void:
	if player_node == null or current_run == null:
		return

	current_run.positions.append(player_node.global_position)
	current_run.timestamps.append(time_elapsed)

func finish_run(complete_run: bool) -> void:
	is_recording = false

	if !complete_run:
		current_run = null
		time_elapsed = 0.0
		sample_timer = 0.0
		return

	current_run.final_time = time_elapsed
	_record_position()
	_save_to_yard()

	current_run = null

func _save_to_yard() -> void:
	if current_run == null:
		return
	var save_path = "res://run_data/run_%s.tres" % current_run.run_id
	DirAccess.make_dir_recursive_absolute("res://run_data/")

	ResourceSaver.save(current_run, save_path)
	print("Saved run to Game Folder at: ", save_path)

func get_fastest_run() -> YARDDATA:
	var save_dir = "res://run_data/"
	var fastest_run: YARDDATA = null
	var fastest_time: float = INF

	var dir = DirAccess.open(save_dir)
	if dir == null:
		print("Could not open directory: ", save_dir)
		return null

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = save_dir + file_name
			var run: YARDDATA = load(full_path)
			if run and run.final_time < fastest_time:
				fastest_time = run.final_time
				fastest_run = run
		file_name = dir.get_next()

	if fastest_run:
		print("Fastest run found: ", fastest_run.run_id, " with time: ", fastest_time)
	else:
		print("No runs found")

	return fastest_run
