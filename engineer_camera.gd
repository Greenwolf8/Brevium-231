extends Camera3D

var interaction_layer:float = 8
var max_distance: float = 100

func _unhandled_input(event: InputEvent) -> void:
	if !self.is_current():
		return
	
	if event.is_action_pressed("L Click"):
		cockpit_raycast()

func cockpit_raycast():
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_end = ray_origin + project_ray_normal(mouse_pos) * max_distance
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = interaction_layer
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	print(result)
	if not result.is_empty():
		var hit_object = result.collider
		if hit_object.has_method("interact"):
			hit_object.interact()
