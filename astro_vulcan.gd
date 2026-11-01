extends RigidBody3D

@onready var animation_player_gear: AnimationPlayer = $"AVRO_VULCAN/AnimationPlayer"
@onready var animation_player_ladder: AnimationPlayer = $"AVRO_VULCAN/AnimationPlayer_ladder"

func _ready() -> void:
	animation_player_gear.play("Landing Gear")
	animation_player_gear.seek(14, true)
	animation_player_ladder.play("ladder/Ladder Deploy")
	animation_player_ladder.seek(7, true)
