extends CharacterBody3D

@export var walk_speed: float = 10
@export var camera: Camera3D


func _ready() -> void:
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera.rotation_degrees.y -= event.relative.x * 0.5
		camera.rotation_degrees.x -= event.relative.y * 0.5
		camera.rotation_degrees.x = clamp(
		camera.rotation_degrees.x, -80.0, 80.0
		)

func _physics_process(delta: float) -> void:
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var cam_forward := -camera.global_transform.basis.z
	var cam_right := camera.global_transform.basis.x
	
	
	cam_forward.y = 0
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()
	
	var direction = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)
	
	move_and_slide()
