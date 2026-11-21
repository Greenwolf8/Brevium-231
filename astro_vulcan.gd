extends RigidBody3D

@onready var animation_player_gear: AnimationPlayer = $"AVRO_VULCAN/AnimationPlayer"
@onready var animation_player_ladder: AnimationPlayer = $"AVRO_VULCAN/AnimationPlayer_ladder"
@onready var elec: Node = $"Electrical Systems"

# Aircraft controls
var target_throttle: float = 0.0
var throttle: float = 0.0

# Engine thrust
var eng_1_thrust: float = 0.0
var eng_2_thrust: float = 0.0
var eng_3_thrust: float = 0.0

# Systems powered on
var radar_engaged: bool = false
var rwr_engaged: bool = false
var r_gun_firing: bool = false
var l_gun_firing: bool = false
var targeting_pod_engaged: bool = false
var radio_in_use: bool = false
var lights_on: int = 0
var hydraulics_usage: float = 0.0

# Throttle Meshes
@onready var eng_1_throttle: MeshInstance3D = $"AVRO_VULCAN/Throttle Quadrant/ENG 1 Throttle"
@onready var eng_1_reverse_lever: MeshInstance3D = $"AVRO_VULCAN/Throttle Quadrant/ENG 1 Throttle/ENG 1 Reverse Lever"
@onready var eng_2_throttle: MeshInstance3D = $"AVRO_VULCAN/Throttle Quadrant/ENG 2 Throttle"
@onready var eng_2_reverse_lever: MeshInstance3D = $"AVRO_VULCAN/Throttle Quadrant/ENG 2 Throttle/ENG 2 Reverse Lever"
@onready var eng_3_throttle: MeshInstance3D = $"AVRO_VULCAN/Throttle Quadrant/ENG 3 Throttle"
@onready var eng_3_reverse_lever: MeshInstance3D = $"AVRO_VULCAN/Throttle Quadrant/ENG 3 Throttle/ENG 3 Reverse Lever"

func _ready() -> void:
	# Make animations start with gear open and ladder deployed
	animation_player_gear.play("Landing Gear")
	animation_player_gear.seek(14, true)
	animation_player_ladder.play("ladder/Ladder Deploy")
	animation_player_ladder.seek(7, true)

func _physics_process(delta: float) -> void:
	# Clamp throttle to make sure it stays between 100% and -25%
	target_throttle = clamp(target_throttle,-25,100.0)
	
	# Move the throttles in cockpit
	if target_throttle <= 10.0 and target_throttle >= -10.0:
		throttle = 0.0
	elif target_throttle >= 10.0 and target_throttle <= 20.0:
		throttle = remap(target_throttle, 10.0, 20.0, 0.0, 20.0)
	elif target_throttle <= -10.0 and target_throttle >= -20.0:
		throttle = remap(target_throttle, -10.0, -20.0, 0.0, -20.0)
	else:
		throttle = target_throttle
	
	if throttle >= 0.0:
		eng_1_throttle.rotation.z = deg_to_rad(clamp(remap(throttle,0.0,100.0,9.5,74.5),9.5,74.5))
		eng_2_throttle.rotation.z = deg_to_rad(clamp(remap(throttle,0.0,100.0,9.5,74.5),9.5,74.5))
		eng_3_throttle.rotation.z = deg_to_rad(clamp(remap(throttle,0.0,100.0,9.5,74.5),9.5,74.5))
		eng_1_reverse_lever.rotation.z = 0.0
		eng_2_reverse_lever.rotation.z = 0.0
		eng_3_reverse_lever.rotation.z = 0.0
	else:
		eng_1_reverse_lever.rotation.z = deg_to_rad(clamp(remap(throttle,0.0,-20.0,0.0,-100.0),-100.0,0.0))
		eng_2_reverse_lever.rotation.z = deg_to_rad(clamp(remap(throttle,0.0,-20.0,0.0,-100.0),-100.0,0.0))
		eng_3_reverse_lever.rotation.z = deg_to_rad(clamp(remap(throttle,0.0,-20.0,0.0,-100.0),-100.0,0.0))
		eng_1_throttle.rotation.z = deg_to_rad(9.5)
		eng_2_throttle.rotation.z = deg_to_rad(9.5)
		eng_3_throttle.rotation.z = deg_to_rad(9.5)
	
	# Get the local force on each engine
	var eng_1_global_force = -global_transform.basis.z * eng_1_thrust
	var eng_2_global_force = -global_transform.basis.z * eng_2_thrust
	var eng_3_global_force = -global_transform.basis.z * eng_3_thrust
	
	# Get the position difference between engine exits and ship centre
	var eng_1_pos_offset = %eng_1_exit.global_position - global_position
	var eng_2_pos_offset = %eng_2_exit.global_position - global_position
	var eng_3_pos_offset = %eng_3_exit.global_position - global_position
	
	apply_force(eng_1_global_force, eng_1_pos_offset)
	apply_force(eng_2_global_force, eng_2_pos_offset)
	apply_force(eng_3_global_force, eng_3_pos_offset)
