extends Node3D

@onready var animation_player: AnimationPlayer = $Hangar2/AnimationPlayer

func _ready() -> void:
	animation_player.play("Call Ship")
	animation_player.seek(40, true)
