extends Camera3D

var free_looking: bool = false

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
		
	if event is InputEventMouseMotion:
		if free_looking:
			rotation_degrees.y -= event.relative.x * 0.1
			rotation_degrees.y = clamp(rotation_degrees.y, -70.0, 70.0)
			rotation_degrees.x -= event.relative.y * 0.1
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

func lock_mouse():
	free_looking = false
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", Vector3.ZERO, 0.25)

func unlock_mouse():
	free_looking = true
