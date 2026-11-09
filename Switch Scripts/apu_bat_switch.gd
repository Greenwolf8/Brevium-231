extends StaticBody3D

@export var on_label: MeshInstance3D

var on: bool = false

const BUTTON_OFF = preload("uid://c1ruib5pd5l2i")
const BUTTON_ON_ON = preload("uid://b7qsjusq6mp7u")

func interact() -> void:
	if !on:
		on_label.set_surface_override_material(0, BUTTON_ON_ON)
		on = true
		%"Electrical Systems".switch_apu_bat = true
	else:
		on_label.set_surface_override_material(0, BUTTON_OFF)
		on = false
		%"Electrical Systems".switch_apu_bat = false
