extends StaticBody3D

@export var on_label: MeshInstance3D

var on: bool = false
var powered: bool = false

const BUTTON_OFF = preload("uid://c1ruib5pd5l2i")
const BUTTON_ON_ON = preload("uid://b7qsjusq6mp7u")

func _ready() -> void:
	turn_off()

func interact() -> void:
	if on:
		turn_off()
	elif !on and powered:
		turn_on()

func _process(delta: float) -> void:
	if !powered and on:
		turn_off()

func turn_off():
	on = false
	on_label.set_surface_override_material(0, BUTTON_OFF)
	%"APU 1 Systems".apu1_master = false

func turn_on():
	on = true
	on_label.set_surface_override_material(0, BUTTON_ON_ON)
	%"APU 1 Systems".apu1_master = true
