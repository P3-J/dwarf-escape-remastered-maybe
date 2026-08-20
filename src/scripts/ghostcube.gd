extends StaticBody3D

@export var yarddata: YARDMAN

var replay_run: YARDDATA
var replay_time: float = 0.0
var replaying: bool = false
var replay_index: int = 0


func _ready() -> void:
	Signalbus.connect('game_starts', _on_game_start)
	replay_run = yarddata.get_fastest_run()


func _on_game_start():
	if replay_run == null:
		print("No replay run available.")
		return

	if replay_run.positions.size() < 2:
		print("Replay run does not contain enough pos")
		return
	visible = true
	replaying = true
	replay_time = 0.0
	replay_index = 0

	global_position = replay_run.positions[0]

func _process(delta: float) -> void:
	if not replaying or replay_run == null:
		return

	replay_time += delta

	var timestamps := replay_run.timestamps
	var positions := replay_run.positions

	if replay_time >= replay_run.final_time:
		global_position = positions[positions.size() - 1]
		replaying = false
		return

	while replay_index < timestamps.size() - 2:
		if replay_time < timestamps[replay_index + 1]:
			break

		replay_index += 1

	var t0 := timestamps[replay_index]
	var t1 := timestamps[replay_index + 1]

	var p0 := positions[replay_index]
	var p1 := positions[replay_index + 1]

	var weight := inverse_lerp(t0, t1, replay_time)

	global_position = p0.lerp(p1, weight)
