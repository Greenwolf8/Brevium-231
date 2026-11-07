extends StaticBody3D

@export var switch_mesh: MeshInstance3D

var on: bool = false

const BUTTON_ORANGE = preload("uid://dos3fbyt150cv")

func interact() -> void:
	if not on:
		switch_mesh.set_surface_override_material(1, BUTTON_ORANGE)
		on = true
	else:
		switch_mesh.set_surface_override_material(1, null)
		on = false
