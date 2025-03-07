extends StaticBody3D

@onready var timer = $Timer
@onready var text_animation = $TextAnimation
@onready var text = $Text
@onready var screen_animation = $ScreenAnimation
@onready var screen = $SM_HandScanner_NoWire

#Sounds:
@onready var scanning = $Scanning
@onready var scan_complete = $ScanComplete
@onready var fail = $Fail

@export var powered: bool = true
@export var scan_time: float = 2.5

var text_material: StandardMaterial3D = null
var screen_material: StandardMaterial3D = null

var scan_state: int = 0
var scan_hand: bool = false

const T_SCANNING = preload("res://Objects/Gameplay/Puzzles/Scanners/Textures/T_Scanning.png")
const T_VERIFIED = preload("res://Objects/Gameplay/Puzzles/Scanners/Textures/T_Verified.png")
const T_READY = preload("res://Objects/Gameplay/Puzzles/Scanners/Textures/T_Ready.png")
const T_ERROR = preload("res://Objects/Gameplay/Puzzles/Scanners/Textures/T_Error.png")

const T_VERIFIED_TEXT = preload("res://Objects/Gameplay/Puzzles/Scanners/Textures/T_VerifiedText.png")
const T_HAND_SCANNER = preload("res://Objects/Gameplay/Puzzles/Scanners/Textures/T_HandScanner.png")
const T_DENIED_TEXT = preload("res://Objects/Gameplay/Puzzles/Scanners/Textures/T_DeniedText.png")

signal scan_started
signal scan_cancelled
signal scan_success
signal scan_incorrect

func _ready():
	text_material = text.get_surface_override_material(0)
	screen_material = screen.get_surface_override_material(1)
	set_state(0)
	if not powered:
		dispower_scanner()

func set_state(state: int):
	if state == 0:
		text_animation.play("ready")
		text_material.emission_texture = T_READY
		screen_animation.play("ready")
		screen_material.emission_texture = T_HAND_SCANNER
		scanning.stop()
	elif state == 1:
		text_animation.play("scan_loop")
		text_material.emission_texture = T_SCANNING
		screen_animation.play("ready")
		screen_material.emission_texture = T_HAND_SCANNER
		scanning.play()
	elif state == 2:
		text_animation.play("verified_loop")
		text_material.emission_texture = T_VERIFIED
		screen_animation.play("verified")
		screen_material.emission_texture = T_VERIFIED_TEXT
		scanning.stop()
		scan_complete.play()
	else:
		text_animation.play("error")
		text_material.emission_texture = T_ERROR
		screen_animation.play("error")
		screen_material.emission_texture = T_DENIED_TEXT
		scanning.stop()
		fail.play()
	scan_state = state

func scan_finished():
	if not scan_hand:
		set_state(2)
		Grabpack.left_retract()
		emit_signal("scan_success")
	else:
		set_state(3)
		Grabpack.right_retract()
		emit_signal("scan_incorrect")

func start_scan(hand):
	if not powered: return
	set_state(1)
	timer.start(scan_time)
	scan_hand = hand
	emit_signal("scan_started")
func stop_scan(hand):
	if hand == scan_hand:
		timer.stop()
		set_state(0)
		emit_signal("scan_cancelled")

func power_scanner():
	powered = true
	text_material.emission_texture = T_READY
	screen_material.emission_texture = T_HAND_SCANNER
	screen_animation.play("ready")
	text_animation.play("ready")
func dispower_scanner():
	powered = false
	screen_animation.play("blank")
	text_animation.play("blank")

func _on_hand_grab_grabbed(hand):
	if scan_state == 0:
		start_scan(hand)
func _on_hand_grab_let_go(hand):
	if scan_state == 1:
		stop_scan(hand)
