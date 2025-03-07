extends CanvasLayer

var scene_path: String

signal loading_screen_has_full_coverage

@onready var animation_player : AnimationPlayer = $AnimationPlayer

var load_value = 0.0
var load_started: bool = false

func start():
	ResourceLoader.load_threaded_request(scene_path)
	animation_player.play("start_load")
	
	await loading_screen_has_full_coverage
	load_started = true

func _process(_delta):
	if not load_started: return
	var progress = []
	ResourceLoader.load_threaded_get_status(scene_path, progress)
	
	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(scene_path)
		get_tree().change_scene_to_packed(packed_scene)
		_start_outro_animation()

func _start_outro_animation() -> void:
	get_tree().paused = false
	animation_player.play("end_load")
	await Signal(animation_player, "animation_finished")
	self.queue_free()
