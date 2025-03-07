extends Node

@onready var player = $"../.."
@onready var sound_manager: Node = $"../../SoundManager"
@onready var step_cast: RayCast3D = $"../../StepCast"

#GRABPACKANIMATION:
var is_walking = false
var is_falling = false
var is_crouching = false
var is_sidel_animation = false
var tilt_lerp: float = 6.5
var start_tilt_lerp: float = 3.5
@onready var idle_animation = $"../Pack/IdleAnimation"
@onready var walk_animation = $"../Pack/WalkAnimation"
@onready var crouch_animation = $"../Pack/CrouchAnimation"
@onready var jump_animation = $"../Pack/JumpAnimation"
@onready var item_animation = $"../Pack/ItemAnimation"
@onready var switch_animation = $"../Pack/SwitchAnimation"
@onready var canon_left_animation = $"../Pack/CanonLeftAnimation"
@onready var canon_right_animation = $"../Pack/CanonRightAnimation"

@onready var move_idle = $"../GrabpackMoveIdle"
@onready var move_forward = $"../GrabpackMoveForward"
@onready var move_back = $"../GrabpackMoveBack"
@onready var move_left = $"../GrabpackMoveLeft"
@onready var move_right = $"../GrabpackMoveRight"
@onready var grabpack_walk = $"../Pack"
@onready var grabpack = $".."

func _ready():
	#SETUP ANIMATIONS:
	idle_animation.play("idle")

func _process(delta):
	handle_grabpack_animation(delta)

func handle_grabpack_animation(delta):
	var walking_vector = Input.get_vector("left", "right", "forward", "back")
	if not is_falling:
		if not walking_vector == Vector2.ZERO:
			if is_crouching:
				walk_animation.speed_scale = 0.7
			elif player.is_squeezing:
				walk_animation.speed_scale = 1.0
			elif player.is_sprinting:
				walk_animation.speed_scale = 2.4
			else:
				walk_animation.speed_scale = 1.75
			if player.is_squeezing:
				if not is_sidel_animation:
					walk_animation.play("WalkSidel")
					
					is_walking = false
					is_sidel_animation = true
			else:
				if not is_walking:
					idle_animation.play("StopIdle")
					walk_animation.play("walk")
					walk_animation.speed_scale = 1.5
					is_walking = true
		else:
			if is_walking or is_sidel_animation:
				walk_animation.play("StopWalking")
				walk_animation.queue("NotWalking")
				walk_animation.seek(0)
				walk_animation.speed_scale = 1.0
				idle_animation.play("idle")
				is_walking = false
				is_sidel_animation = false
	
	#DirectionalTilt:
	if Input.is_action_pressed("forward"):
		grabpack_walk.position.y = lerp(grabpack_walk.position.y, move_forward.position.y, start_tilt_lerp * delta)
		grabpack_walk.position.z = lerp(grabpack_walk.position.z, move_forward.position.z, start_tilt_lerp * delta)
		grabpack_walk.rotation.x = lerp(grabpack_walk.rotation.x, move_forward.rotation.x, start_tilt_lerp * delta)
	elif Input.is_action_pressed("back"):
		grabpack_walk.position.y = lerp(grabpack_walk.position.y, move_back.position.y, start_tilt_lerp * delta)
		grabpack_walk.position.z = lerp(grabpack_walk.position.z, move_back.position.z, start_tilt_lerp * delta)
		grabpack_walk.rotation.x = lerp(grabpack_walk.rotation.x, move_back.rotation.x, start_tilt_lerp * delta)
	else:
		grabpack_walk.position.y = lerp(grabpack_walk.position.y, move_idle.position.y, tilt_lerp * delta)
		grabpack_walk.position.z = lerp(grabpack_walk.position.z, move_idle.position.z, tilt_lerp * delta)
		grabpack_walk.rotation.x = lerp(grabpack_walk.rotation.x, move_idle.rotation.x, tilt_lerp * delta)
	if Input.is_action_pressed("left"):
		grabpack_walk.position.x = lerp(grabpack_walk.position.x, move_left.position.x, start_tilt_lerp * delta)
		grabpack_walk.rotation.z = lerp(grabpack_walk.rotation.z, move_left.rotation.z, start_tilt_lerp * delta)
	elif Input.is_action_pressed("right"):
		grabpack_walk.position.x = lerp(grabpack_walk.position.x, move_right.position.x, start_tilt_lerp * delta)
		grabpack_walk.rotation.z = lerp(grabpack_walk.rotation.z, move_right.rotation.z, start_tilt_lerp * delta)
	else:
		grabpack_walk.position.x = lerp(grabpack_walk.position.x, move_idle.position.x, tilt_lerp * delta)
		grabpack_walk.rotation.z = lerp(grabpack_walk.rotation.z, move_idle.rotation.z, tilt_lerp * delta)
	
	if not player.is_on_floor():
		if not is_falling:
			if not step_cast.is_colliding():
				jump_animation.play("start_fall")
				jump_animation.queue("fall")
				walk_animation.play("NotWalking")
				is_walking = false
				is_falling = true
	else:
		if is_falling:
			jump_animation.play("land")
			is_falling = false
			
			sound_manager.land()
	
	if player.crouched:
		if not is_crouching:
			sound_manager.crouch(true)
			crouch_animation.play("EnterCrouch")
			walk_animation.play("NotWalking")
			is_walking = false
			is_crouching = true
	else:
		if is_crouching:
			sound_manager.crouch(false)
			crouch_animation.play("ExitCrouch")
			is_crouching = false

func jump():
	jump_animation.play("Jump")
	jump_animation.queue("fall")
	is_falling = true
	
	if is_walking:
		walk_animation.play("NotWalking")
		is_walking = false
	
	sound_manager.jump()
