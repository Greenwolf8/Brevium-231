extends StaticBody3D

@export var auto_label: MeshInstance3D
@export var off_label: MeshInstance3D

var on: bool = false
var powered: bool = false
var off_off: bool = false #ik it's confusing, but this is used for both lights being off

const BUTTON_OFF = preload("uid://c1ruib5pd5l2i")
const BUTTON_ON_ON = preload("uid://b7qsjusq6mp7u")
const BUTTON_ON_OFF = preload("uid://b7pu563s76ma5")

func _ready() -> void:
	turn_off_off()

func interact() -> void:
	if on:
		turn_off()
	elif !on and powered:
		turn_on()

func _process(delta: float) -> void:
	if !powered and !off_off:
		turn_off_off()
	elif powered and off_off:
		turn_off()

func turn_off():
	auto_label.set_surface_override_material(0, BUTTON_OFF)
	off_label.set_surface_override_material(0, BUTTON_ON_OFF)
	%"APU 1 Systems".apu1_waterpump = false
	on = false
	off_off = false

func turn_on():
	auto_label.set_surface_override_material(0, BUTTON_ON_ON)
	off_label.set_surface_override_material(0, BUTTON_OFF)
	%"APU 1 Systems".apu1_waterpump = true
	on = true
	off_off = false

func turn_off_off():
	auto_label.set_surface_override_material(0, BUTTON_OFF)
	off_label.set_surface_override_material(0, BUTTON_OFF)
	on = false
	off_off = true
