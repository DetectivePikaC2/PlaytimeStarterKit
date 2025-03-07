extends Node3D

const DEFAULT_TEXTURE = preload("res://Interface/Inventory/ItemIcons/T_UI_RedHand.png")

@export var grabpacks: Array[PackedScene]

@onready var player = $".."
@onready var neck = $"../Neck"
@onready var pack = $Pack

@onready var tube_left = $Pack/LayerWalk/TubeLeft
@onready var right_tube = $Pack/LayerWalk/RightTube
@onready var left_arm_attach = $Pack/LayerWalk/ArmLeft/LayerIdle/LayerWalk/LayerCrouch/LayerJump/LayerPack/LayerShoot/CanonAttach
@onready var right_arm_attach = $Pack/LayerWalk/ArmRight/LayerIdle/LayerWalk/LayerCrouch/LayerJump/LayerPack/LayerSwitch/LayerShoot/CanonAttach

@onready var item_animation = $Pack/ItemAnimation
@onready var sound_manager: Node = $"../SoundManager"

@onready var attachment_left: BoneAttachment3D = left_arm_attach.get_node("ArmAttach")
@onready var attachment_right: BoneAttachment3D = right_arm_attach.get_node("BoneAttachment3D")

@onready var left_hand = $Pack/LeftHandContainer
@onready var right_hand = $Pack/RightHandContainer
@onready var canon_right_animation: AnimationPlayer = $Pack/CanonRightAnimation

var sway_speed: float = 30.0
var grabpack_equipped: bool = true
var grabpack_lowered: bool = false

var current_grabpack: int = 0
var current_grabpack_node: Node3D = null
var current_grabpack_skeleton_node: Skeleton3D = null
var grabpack_queue: int = 0
var pack_bone_data_node: Node = null

var grabpack_switchable_hands: bool = false
var grabpack_usable: bool = false
var wire_powered: bool = false

func _ready():
	# Reset grabpack
	if has_node("Pack/GrabpackOne"):
		$Pack/GrabpackOne.queue_free()
	
	Inventory.items_Equipment = []
	for i in player.enabled_hands.size():
		var hand_instance = player.enabled_hands[i].instantiate()
		if not hand_instance.has_node("Useless"):
			var inventory_icon: Texture2D = DEFAULT_TEXTURE
			var description = null
			if hand_instance.has_node("HandInventoryIcon"):
				var inventory_item_icon = hand_instance.get_node("HandInventoryIcon")
				inventory_icon = inventory_item_icon.icon
				if inventory_item_icon.has_description:
					description = inventory_item_icon.description

			Inventory.items_Equipment.append([hand_instance.name, inventory_icon])
			if description:
				Inventory.items_Equipment[i].append(description)
		
		hand_instance.queue_free()
	
	queue_grabpack(player.starting_grabpack)
	set_queued_grabpack()
	await get_tree().create_timer(0.1).timeout
	update_grabpack_data()
	await get_tree().create_timer(0.1).timeout
	update_grabpack_visibility(true)
	
	if player.start_lowered:
		item_animation.play("StartLowered")
		grabpack_lowered = true

func _process(delta):
	rotation.x = lerp_angle(rotation.x, neck.rotation.x, sway_speed * delta)
	rotation.y = lerp_angle(rotation.y, neck.rotation.y, sway_speed * delta)

	if current_grabpack_skeleton_node:
		current_grabpack_skeleton_node.force_update_transform()
		attachment_left.force_update_transform()
		attachment_right.force_update_transform()

# Grabpack Control
func switch_grabpack(grabpack_index: int):
	if grabpack_index == current_grabpack:
		return
	
	grabpack_queue = grabpack_index
	queue_grabpack(grabpack_index)
	item_animation.play("SwitchGrabpackLowerRaise")

func set_queued_grabpack():
	set_grabpack(grabpack_queue)

func set_grabpack(grabpack_index: int):
	_reset_attachments()

	if current_grabpack_node:
		current_grabpack_node.queue_free()

	var new_grabpack = grabpacks[grabpack_index].instantiate()
	new_grabpack.visible = false
	pack.add_child(new_grabpack)

	current_grabpack_node = new_grabpack
	current_grabpack = grabpack_index
	grabpack_lowered = false

func update_grabpack_data():
	_reset_attachments()
	
	pack_bone_data_node = null
	grabpack_switchable_hands = current_grabpack_node.has_node("GrabpackSwitchHands")
	grabpack_usable = current_grabpack_node.has_node("GrabpackLaunchable")

	left_hand.visible = grabpack_usable
	right_hand.visible = grabpack_usable

	if not current_grabpack_node.has_node("GrabpackHandAttachmentData"):
		return
	
	var pack_bone_data = current_grabpack_node.get_node("GrabpackHandAttachmentData")
	pack_bone_data_node = pack_bone_data
	current_grabpack_skeleton_node = pack_bone_data.skeleton

	left_arm_attach.scale = pack_bone_data.attachment_size
	right_arm_attach.scale = pack_bone_data.attachment_size

	attachment_left.set_use_external_skeleton(true)
	attachment_right.set_use_external_skeleton(true)

	attachment_left.set_external_skeleton(attachment_left.get_path_to(pack_bone_data.skeleton))
	attachment_right.set_external_skeleton(attachment_right.get_path_to(pack_bone_data.skeleton))

	attachment_left.bone_idx = pack_bone_data.left_gun_bone_index
	attachment_right.bone_idx = pack_bone_data.right_gun_bone_index
	attachment_left.override_pose = true
	attachment_right.override_pose = true

	if current_grabpack_node.has_node("GrabpackUseIKTube"):
		var leftik: SkeletonIK3D = current_grabpack_skeleton_node.get_node("TubeIKLeft")
		var rightik: SkeletonIK3D = current_grabpack_skeleton_node.get_node("TubeIKRight")
		leftik.target_node = leftik.get_path_to(tube_left)
		rightik.target_node = rightik.get_path_to(right_tube)

		leftik.start()
		rightik.start()

func update_grabpack_visibility(new_visible: bool):
	current_grabpack_node.visible = new_visible

func queue_grabpack(grabpack_index: int):
	grabpack_queue = clamp(grabpack_index, 0, grabpacks.size() - 1)

func lower_grabpack():
	if not grabpack_lowered:
		item_animation.play("LowerPack")
		sound_manager.lower_grabpack()
		grabpack_usable = false
		grabpack_lowered = true

func raise_grabpack():
	if grabpack_lowered:
		item_animation.play("RaisePack")
		sound_manager.raise_grabpack()
		grabpack_usable = current_grabpack_node.has_node("GrabpackLaunchable")
		grabpack_lowered = false

func _input(_event):
	if Input.is_action_pressed("f") and Input.is_action_pressed("u"):
		left_hand.play_animation("middle")
		right_hand.play_animation("middle")
	if Input.is_action_just_pressed("flashlight"):
		if player.flashlight_togglable:
			if pack_bone_data_node and pack_bone_data_node.use_flashlight_animation:
				if not player.flashlight:
					current_grabpack_node.get_node("AnimationPlayer").play("flashlight_on")
					if not canon_right_animation.is_playing():
						canon_right_animation.play("flashlight_on")
				else:
					current_grabpack_node.get_node("AnimationPlayer").play("flashlight_off")
					if not canon_right_animation.is_playing():
						canon_right_animation.play("flashlight_off")
				player.flashlight = !player.flashlight
				sound_manager.toggle_flashlight()

func _reset_attachments():
	attachment_left.bone_idx = 0
	attachment_left.override_pose = false
	attachment_left.set_use_external_skeleton(false)
	attachment_right.bone_idx = 0
	attachment_right.override_pose = false
	attachment_right.set_use_external_skeleton(false)
