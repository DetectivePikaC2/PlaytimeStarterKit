extends CharacterBody3D

@onready var tree = get_tree()  # Cache the tree reference
@onready var sound_manager: Node = $SoundManager  # Cache this node reference

@export_category("Settings")
@export_group("Movement")
@export var movable: bool = true
@export_group("Grabpack")
@export var flashlight: bool = false
@export var flashlight_togglable: bool = false
@export var start_lowered: bool = false
#0 is no grabpack, and numbers 1 and 2 are grabpack versions 1 and 2.
@export_range(0, 2) var starting_grabpack: int = 0
@export var load_previous_player_hands: bool = false
@export var enabled_hands: Array [PackedScene] = [preload("res://Player/Grabpack/Hands/none.tscn")]

@export_category("Player")
var speed: float = 10 # m/s
var acceleration: float = 60 # m/s^2

var normal_speed: float = 4.0
var sprint_speed: float = 6.0
var crouching_speed: float = 2.0
var squeeze_speed: float = 1.0
var speed_lerp: float = 12.0

var jump_height: float = 1 # m
var camera_sens: float = 1
var camera_movable: bool = true

var jumping: bool = false
var special_jump: bool = false
var special_jump_height: float = 1.0
var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

@onready var neck: Node3D = $Neck
@onready var head = $Neck/Head
@onready var camera = $Neck/Head/CamLayerJump/CamLayerWalk/CamLayerCrouch/Camera3D
@onready var camera_front = $Neck/Head/CamLayerJump/CamLayerWalk/CamLayerCrouch/Camera3D/infront

var player_height: float = 1.7
var crouch_depth: float = 0.85
var crouched: bool = false
var crouch_speed = 6.0
@onready var standing_collision = $StandingCollision
@onready var crouch_collision = $CrouchCollision
@onready var crouch_cast = $RayCast3D

@onready var grabpack = $Grabpack
@onready var animation_manager: Node = $Grabpack/GrabpackAnimationHandler

#Wire Constraints
@onready var length_calculator: Node = $Grabpack/Pack/LengthCalculator
@onready var left_hand: Node3D = $Grabpack/Pack/LeftHandContainer
@onready var right_hand: Node3D = $Grabpack/Pack/RightHandContainer
var wire_1_length:float = 0.0
var wire_2_length:float = 0.0

var is_sprinting: bool = false
var is_squeezing: bool = false
var is_squeeze_hitbox: bool = false

var swinging = false
var swinging_point: Vector3 = Vector3.ZERO

@onready var hook_controller: HookController = $HookController
@onready var flashlight_node: Node3D = $Grabpack/Flashlight

func _ready() -> void:
	capture_mouse(true)
	
	Grabpack.reset_objects()
	Game.reset_nodes()
	sound_manager.load_soundpack("Grass")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not movable: return
		look_dir = event.relative * 0.001
		if mouse_captured: if camera_movable: _rotate_camera()
	if Input.is_action_just_pressed("jump"): jumping = true

func _physics_process(delta: float) -> void:
	if not movable: return
	
	#Handle Crouch:
	var crouchable: bool = false
	if Input.is_action_pressed("crouch"):
		if not is_squeezing:
			crouchable = true
	if crouch_cast.is_colliding():
		crouchable = true
	
	if crouchable:
		standing_collision.disabled = true
		crouch_collision.disabled = false
		
		neck.position.y = move_toward(neck.position.y, crouch_depth, (crouch_speed - 4.0) * delta)
		grabpack.position.y = neck.position.y
		crouched = true
	else:
		if not crouch_cast.is_colliding():
			standing_collision.disabled = false
			crouch_collision.disabled = true
			
			neck.position.y = lerp(neck.position.y, player_height, crouch_speed * delta)
			grabpack.position.y = neck.position.y
			crouched = false
	
	#Handle Sprinting:
	is_sprinting = Input.is_action_pressed("sprint")
	
	#Handle Speed:
	if crouched:
		speed = lerp(speed, crouching_speed, speed_lerp * delta)
	elif is_squeezing:
		speed = lerp(speed, squeeze_speed, speed_lerp * delta)
	elif is_sprinting:
		speed = lerp(speed, sprint_speed, speed_lerp * delta)
	else:
		speed = lerp(speed, normal_speed, speed_lerp * delta)
	
	if is_squeezing != is_squeeze_hitbox:
		standing_collision.shape.radius = 0.19 if is_squeezing else 0.3
		is_squeeze_hitbox = is_squeezing
	
	if not swinging: velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	elif is_on_floor(): velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	
	else: 
		jump_vel = velocity
		jump_vel.y = velocity.y * 1.5
		if jump_vel.y > 9.0:
			jump_vel.y = 9.0
	
	if not left_hand.hand_attached or not right_hand.hand_attached:
		# Simulate the new position
		var max_total_length: float = length_calculator.max_length
		var desired_velocity: Vector3 = velocity  # Example speed
		var current_position = global_position
		
		wire_1_length = current_position.distance_to(left_hand.global_position)
		wire_2_length = current_position.distance_to(right_hand.global_position)
		var total_length: float = wire_1_length + wire_2_length
	
		# Prevent exceeding max length
		if total_length > max_total_length:
			var hand_limits: bool = false
			if left_hand.hand_travelling:
				left_hand.retract_hand()
				hand_limits = true
			if right_hand.hand_travelling:
				right_hand.retract_hand()
				hand_limits = true
			if not hand_limits:
				var excess_length: float = total_length - max_total_length
		
				# Find the direction toward the center point between anchors
				var direction_to_center: Vector3 = ((left_hand.global_position + right_hand.global_position) / 2 - global_position).normalized()
		
				# Apply a correction that keeps the player within the allowed range
				global_position += direction_to_center * excess_length
		
				# Stop movement when max length is reached
				velocity = Vector3.ZERO  
		else:
			# Apply movement normally if within bounds
			velocity.x = desired_velocity.x
			velocity.z = desired_velocity.z

	move_and_slide()
	
	#Handle Flashlight
	flashlight_node.visible = flashlight

func capture_mouse(capture_mode: bool) -> void:
	if capture_mode:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = capture_mode
func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
func _rotate_camera(sens_mod: float = 1.0) -> void:
	neck.rotation.y -= look_dir.x * camera_sens * sens_mod
	neck.rotation.x = clamp(neck.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("left", "right", "forward", "back")
	var _forward: Vector3 = neck.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel
func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel
func _jump(delta: float) -> Vector3:
	if jumping:
		if special_jump:
			jump_vel = Vector3(0, sqrt(4 * special_jump_height * gravity), 0)
			animation_manager.jump()
		elif is_on_floor():
			var can_jump: bool = true
			if crouch_cast.is_colliding():
				can_jump = false
			if is_squeezing:
				can_jump = false
			
			if can_jump:
				jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
				animation_manager.jump()
		jumping = false
		special_jump = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func external_jump(height: float):
	jumping = true
	special_jump = true
	special_jump_height = height
