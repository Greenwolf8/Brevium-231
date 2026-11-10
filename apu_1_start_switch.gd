extends StaticBody3D

@export var on_label: MeshInstance3D
@export var avail_label: MeshInstance3D

var on: bool = false
var avail_lit: bool = false

var avail: bool = false
var powered: bool = false

const BUTTON_OFF = preload("uid://c1ruib5pd5l2i")
const BUTTON_ON_ON = preload("uid://b7qsjusq6mp7u")
const GREEN = preload("uid://bu5jukk52fwr6")

func _ready() -> void:
	turn_off()
	kill_avail()

func interact() -> void:
	if on:
		turn_off()
	elif !on and powered:
		turn_on()

func _process(delta: float) -> void:
	if !powered and on:
		turn_off()
	
	if avail and !avail_lit:
		light_avail()
	if!avail and avail_lit:
		kill_avail()

func turn_off():
	on = false
	on_label.set_surface_override_material(0, BUTTON_OFF)
	%"APU Systems".apu1_start = false

func turn_on():
	on = true
	on_label.set_surface_override_material(0, BUTTON_ON_ON)
	%"APU Systems".apu1_start = true

func light_avail():
	avail_label.set_surface_override_material(0, GREEN)
	avail_lit = true

func kill_avail():
	avail_label.set_surface_override_material(0, BUTTON_OFF)
	avail_lit = false
