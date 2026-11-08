extends Camera3D

var interaction_layer:float = 32768
var max_distance: float = 100

# Transforms when camera is being entered
var starting_pos: Vector3 = Vector3(1.77,4.16,-25.72)
var starting_rot: Vector3 = Vector3(0.0, -180, 0.0)

# Transforms when camera is zoomed in
var fuel_elec_pos: Vector3 = Vector3(2.065, 3.96, -25.2)
var fuel_elec_rot: Vector3 = Vector3(-20.4, -180, 0.0)

var zoomed_in: bool = false
var tween_time: float = 0.25

func _ready() -> void:
	position = starting_pos
	rotation_degrees = starting_rot

func _unhandled_input(event: InputEvent) -> void:
	if !self.is_current():
		return
	
	if event.is_action_pressed("L Click") and !zoomed_in:
		interaction_layer = 32768
		cockpit_raycast()
	elif event.is_action_pressed("L Click") and zoomed_in:
		interaction_layer = 8
		cockpit_raycast()
	elif event.is_action_pressed("R Click") and zoomed_in:
		var tween_pos = create_tween()
		var tween_rot = create_tween()
		var tween_fov = create_tween()
		tween_pos.tween_property(self, "position", starting_pos, tween_time)
		tween_rot.tween_property(self, "rotation_degrees", starting_rot, tween_time)
		tween_fov.tween_property(self,"fov", 75.0, tween_time)
		zoomed_in = false

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
		if zoomed_in:
			if hit_object.has_method("interact"):
				hit_object.interact()
		else:
			if hit_object.name == "FUEL,ELEC":
				var tween_pos = create_tween()
				var tween_rot = create_tween()
				var tween_fov = create_tween()
				tween_pos.tween_property(self, "position", fuel_elec_pos, tween_time)
				tween_rot.tween_property(self, "rotation_degrees", fuel_elec_rot, tween_time)
				tween_fov.tween_property(self,"fov", 50.0, tween_time)
				zoomed_in = true
