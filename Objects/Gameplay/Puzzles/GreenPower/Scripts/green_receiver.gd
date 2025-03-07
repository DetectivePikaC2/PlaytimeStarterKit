extends StaticBody3D

var powered: bool = false
var remaining_power: float = 0.0

@onready var omni_light_3d = $OmniLight3D
@onready var charged: AudioStreamPlayer3D = $Charged
@onready var discharge: AudioStreamPlayer3D = $Discharge

signal gained_power
signal lost_power

func _process(delta):
	if remaining_power > 0.0:
		remaining_power -= 1.0 * delta
	else:
		if powered:
			discharge.play()
			lost_power.emit()
			set_power(false)

func _on_hand_grab_grabbed(hand):
	if hand and Grabpack.right_hand.current_hand_node.name == "GreenHand":
		if not Grabpack.right_hand.current_hand_node.powered:
			if powered:
				Grabpack.right_hand.current_hand_node.remaining_power = remaining_power
				Grabpack.right_hand.current_hand_node.set_power(true)
				lost_power.emit()
				discharge.play()
				charged.play()
				set_power(false)
			return
		remaining_power = Grabpack.right_hand.current_hand_node.remaining_power
		Grabpack.right_hand.current_hand_node.set_power(false)
		gained_power.emit()
		charged.play()
		set_power(true)

func set_power(power):
	powered = power
	omni_light_3d.visible = power
