extends Node
class_name GrabpackHandAttachmentData

@export_category("Grabpack Bone Settings")
@export var skeleton: Skeleton3D
@export var left_gun_bone_index: int = 0
@export var right_gun_bone_index: int = 0
@export var attachment_size: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var use_flashlight_animation: bool = false
