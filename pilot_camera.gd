extends Camera3D

var free_looking: bool = false
var sensitivity: float = 0.1

@onready var pilot_cast: RayCast3D = $"Pilot Cast"

func _unhandled_input(event: InputEvent) -> void:
	if !self.is_current():
		return
	
	if event.is_action_pressed("mouse_unlock") and free_looking:
		lock_mouse()
	elif event.is_action_pressed("mouse_unlock") and !free_looking:
		unlock_mouse()
	
	elif event.is_action_pressed("L Click") and pilot_cast.is_colliding():
		cockpit_raycast()
		
	if free_looking:
		if event is InputEventMouseMotion:
			rotation_degrees.y -= event.relative.x * sensitivity
			rotation_degrees.y = clamp(rotation_degrees.y, -70.0, 70.0)
			rotation_degrees.x -= event.relative.y * sensitivity
			rotation_degrees.x = clamp(rotation_degrees.x, -70.0, 70.0)
		elif event.is_action_pressed("zoom_in") and fov > 15.0:
			fov -= 5.0
		elif event.is_action_pressed("zoom_out") and fov < 75.0:
			fov += 5.0
			pass

func _process(delta: float) -> void:
	if !self.is_current():
		return
	
	sensitivity = remap(fov, 15.0, 75.0, 0.01, 0.1)
	
	if free_looking:
		pass

func reset():
	fov = 75
	lock_mouse()

func cockpit_raycast():
	var result = pilot_cast.get_collider()
	
	if result != null:
		var hit_object = result
		if hit_object.has_method("interact"):
			hit_object.interact()

func lock_mouse():
	free_looking = false
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", Vector3.ZERO, 0.25)

func unlock_mouse():
	free_looking = true
