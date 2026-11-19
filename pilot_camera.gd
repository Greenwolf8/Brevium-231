extends Camera3D

var free_looking: bool = false

@onready var pilot_cast: RayCast3D = $"Pilot Cast"

func _unhandled_input(event: InputEvent) -> void:
	if !self.is_current():
		return
	
	if event.is_action_pressed("mouse_unlock"):
		free_looking = !free_looking
	elif event.is_action_pressed("L Click") and pilot_cast.is_colliding():
		cockpit_raycast()
		
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * 0.5
		rotation_degrees.y = clamp(rotation_degrees.y, -70.0, 70.0)
		rotation_degrees.x -= event.relative.y * 0.5
		rotation_degrees.x = clamp(rotation_degrees.x, -70.0, 70.0)

func _process(delta: float) -> void:
	if !self.is_current():
		return
	
	if free_looking:
		pass

func cockpit_raycast():
	var result = pilot_cast.get_collider()
	
	if result != null:
		var hit_object = result
		if hit_object.has_method("interact"):
			hit_object.interact()
