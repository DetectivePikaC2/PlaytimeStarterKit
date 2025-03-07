extends Node

@onready var player: CharacterBody3D = $".."

func toggle_flashlight():
	get_node("flashlight").play()

func step():
	var walk_node: String = "none"
	
	if player.is_squeezing:
		walk_node = str("sidelStep", randi_range(1, 3))
	elif player.is_sprinting:
		walk_node = str("run", randi_range(1, 6))
	else:
		walk_node = str("walk", randi_range(1, 6))
	
	get_node(walk_node).play()

func collect():
	var sound_node: String = "none"
	
	sound_node = "collect"
	
	get_node(sound_node).play()

func land():
	var sound_node: String = "none"
	
	sound_node = str("land", randi_range(1, 3))
	
	get_node(sound_node).play()
func jump():
	var sound_node: String = "none"
	
	sound_node = str("jump", randi_range(1, 3))
	
	get_node(sound_node).play()
func crouch(type: bool):
	var sound_node: String = "none"
	
	if type:
		sound_node = "crouch2"
	else:
		sound_node = "crouch1"
	
	get_node(sound_node).play()
func launch_hand():
	var sound_node: String = "none"
	
	sound_node = str("launch", randi_range(1, 3))
	
	get_node(sound_node).play()
func retract_hand():
	var sound_node: String = "none"
	
	sound_node = str("retract", randi_range(1, 3))
	
	get_node(sound_node).play()
func switch_hand():
	var sound_node: String = "none"
	
	sound_node = "switchhand"
	
	var sound: AudioStreamPlayer = get_node(sound_node)
	sound.play()
	sound.seek(0.45)
func cable_sound(hand: bool, play: bool):
	var sound_node: String = "none"
	if not hand:
		sound_node = "cableloopleft"
	else:
		sound_node = "cableloopright"
	
	if play:
		get_node(sound_node).play()
	else:
		get_node(sound_node).stop()

func lower_grabpack():
	var sound_node: String = "none"
	
	sound_node = "sidleEnter"
	
	get_node(sound_node).play()
func raise_grabpack():
	var sound_node: String = "none"
	
	sound_node = "sidleExit"
	
	get_node(sound_node).play()

func load_soundpack(pack_folder: String):
	var folder_path: String = str("res://Player/Sound/Movement/", pack_folder, "/")
	
	for i in 15:
		var sound_node: AudioStreamPlayer = get_child(i)
		if sound_node.name.contains("walk") or sound_node.name.contains("run") or sound_node.name.contains("land"):
			var file_name = str(sound_node.name, ".wav")
			var file_path = str(folder_path, file_name)
			var stream = ResourceLoader.load(file_path) as AudioStream
			sound_node.stream = stream
