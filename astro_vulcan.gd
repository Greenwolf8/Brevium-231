extends RigidBody3D

@onready var animation_player_gear: AnimationPlayer = $"AVRO_VULCAN/AnimationPlayer"
@onready var animation_player_ladder: AnimationPlayer = $"AVRO_VULCAN/AnimationPlayer_ladder"
@onready var elec: Node = $"Electrical Systems"

# Aircraft controls
var throttle: float = 0.0


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

func _unhandled_input(event: InputEvent) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Clamp throttle to make sure it stays between 100% and -25%
	throttle = clamp(throttle,-25,100.0)
	
	# Move the throttles in cockpit
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
