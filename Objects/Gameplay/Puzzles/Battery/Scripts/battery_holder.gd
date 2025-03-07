extends StaticBody3D

@export var allow_battery_removal: bool = false
@export var starts_with_battery: bool = false
@export var powers_puzzle: bool = false
@export var puzzle_node: NodePath
@export var powered_puzzle_on_signal: String = ""
@export var powered_puzzle_off_signal: String = ""

@onready var battery = $Battery

var attached_battery: RigidBody3D = null

var contains_battery: bool = false

@onready var power_up = $PowerUp
@onready var power_down = $PowerDown
@onready var idle = $Idle
@onready var lock = $Lock

signal powered_on
signal powered_off

func _ready():
	if starts_with_battery:
		attached_battery = get_node("BatteryNode")
		attached_battery.disable_battery()
		attached_battery.in_holder = true
		attached_battery.battery_holder = self
		idle.play()
		if not allow_battery_removal:
			attached_battery.hand_grab.enabled = false
		attached_battery.global_transform = battery.global_transform
	else:
		get_node("BatteryNode").queue_free()
	if powers_puzzle:
		if not powered_puzzle_on_signal == "": connect("powered_on", Callable(get_node(puzzle_node), powered_puzzle_on_signal))
		if not powered_puzzle_off_signal == "": connect("powered_off", Callable(get_node(puzzle_node), powered_puzzle_off_signal))

func release_battery():
	contains_battery = false
	attached_battery = null
	idle.stop()
	power_down.play()
	emit_signal("powered_off")

func _on_area_area_entered(area):
	if area.is_in_group("Battery") and not contains_battery:
		attached_battery = area.get_parent()
		attached_battery.disable_battery()
		if not allow_battery_removal:
			attached_battery.hand_grab.enabled = false
			lock.play()
		if attached_battery.item_holdable.hold_hand:
			Grabpack.left_position(battery.global_position)
			Grabpack.left_rotation(battery.global_rotation)
		else:
			Grabpack.right_position(battery.global_position)
			Grabpack.right_rotation(battery.global_rotation)
		
		power_up.play()
		idle.play()
		contains_battery = true
		attached_battery.in_holder = true
		attached_battery.battery_holder = self
		attached_battery.global_transform = battery.global_transform
		emit_signal("powered_on")
