extends Node3D

@export var button_number: int = 0

@onready var basic_interaction = $BasicInteraction
@onready var keypad = $"../.."

var pressing_time: float = 0.0

func _ready():
	basic_interaction.connect("player_interacted", Callable(pressed))

func _process(delta):
	if pressing_time > 0.0:
		if pressing_time < 0.5:
			if position.y < 0.0:
				position.y += 0.25* delta
		else:
			position.y -= 0.25 * delta
		pressing_time -= 1.0 * delta

func pressed():
	if pressing_time > 0.0: return
	keypad.pressed(button_number)
	pressing_time = 0.65
