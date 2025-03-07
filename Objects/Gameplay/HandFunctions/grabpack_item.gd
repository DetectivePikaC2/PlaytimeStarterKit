extends Node3D

@onready var hand_grab = $HandGrab

@export_range(1, 2) var grabpacK_number: int = 1
@export var play_collect_sound: bool = true

signal collected

func collect():
	collected.emit()
	hand_grab.release_grabbed()
	if play_collect_sound:
		Grabpack.player.sound_manager.collect()
	Grabpack.switch_grabpack(grabpacK_number)
	
	queue_free()

func _on_hand_grab_let_go(_hand):
	collect()
func _on_basic_interaction_player_interacted():
	collect()
