extends Area3D

var pos: int = 0

var start_rot: Vector3 = Vector3(-47.4, -53.5, 33.8)
var norm_rot: Vector3 = Vector3(0.0, 0.0, 9.5)

@onready var switch: MeshInstance3D = $"../AVRO_VULCAN/Throttle Quadrant/ENG IGN Switch"

func interact():
	var tween = create_tween()
	if pos == 0:
		await tween.tween_property(switch, "rotation_degrees", start_rot, 0.25).finished
		pos = 1
	else:
		await tween.tween_property(switch, "rotation_degrees", norm_rot, 0.25).finished
		pos = 0
		
	
	%"Engines Systems".switch_eng_start_ign = pos
