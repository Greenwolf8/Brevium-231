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

func _ready() -> void:
	# Make animations start with gear open and ladder deployed
	animation_player_gear.play("Landing Gear")
	animation_player_gear.seek(14, true)
	animation_player_ladder.play("ladder/Ladder Deploy")
	animation_player_ladder.seek(7, true)

func _unhandled_input(event: InputEvent) -> void:
	pass

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("throttle_up"):
		throttle += 1.0
	
	if Input.is_action_pressed("throttle_down"):
		throttle -= 1.0
