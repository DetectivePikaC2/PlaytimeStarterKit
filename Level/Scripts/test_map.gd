extends Node3D

var power_direct: bool = false
var power_direct_levers: bool = false
@onready var gate_4 = $Passages/Gate4

func check_power_direct_room():
	if power_direct and power_direct_levers:
		gate_4.opengate()
	elif gate_4.open:
		gate_4.closegate()

func _on_lever_linker_levers_down():
	power_direct_levers = true
	check_power_direct_room()
func _on_lever_linker_levers_up():
	power_direct_levers = false
	check_power_direct_room()
func _on_power_director_button_pressed():
	power_direct = !power_direct
	check_power_direct_room()

func _on_hand_scanner_right_3_scan_success():
	Grabpack.remove_hand("RedHand")

func _on_button_2_pressed():
	Game.load_scene("res://Objects/Gameplay/Extra/Scripts/data_space.tscn")
