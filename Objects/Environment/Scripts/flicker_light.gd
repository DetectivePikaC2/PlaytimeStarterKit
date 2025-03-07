@tool
extends Light3D

@export var noise: NoiseTexture2D
@export var max_energy: float = 2.0

var time_passed: float = 0.0

func _process(delta):
	time_passed += delta
	
	var sampled_noise = noise.noise.get_noise_1d(time_passed)
	sampled_noise = abs(sampled_noise) * max_energy
	light_energy = sampled_noise
