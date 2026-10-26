extends CharacterBody3D

@export var walk_speed: float = 10
@export var run_speed: float = 20
@export var camera: Camera3D

var bobbing_up: bool = true
var bob_height_down: Vector3 = Vector3(-0.1, 1.69, -0.25)
var bob_height_up: Vector3 = Vector3(0.1, 1.69, -0.25)

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	if is_multiplayer_authority():
		camera.make_current()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	
	# Camera turning
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * 0.5
		camera.rotation_degrees.x -= event.relative.y * 0.5
		camera.rotation_degrees.x = clamp(
		camera.rotation_degrees.x, -80.0, 80.0
		)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	
	# Movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var direction = (global_transform.basis.x * input_dir.x + -global_transform.basis.z * input_dir.y)
	
	if direction:
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)
	
	# Head bobbing
	if input_dir.y != 0.0:
		if bobbing_up == true:
			camera.position.x = move_toward(camera.position.x, bob_height_up.x, delta * 0.4)
			if camera.position == bob_height_up:
				bobbing_up = false
		elif bobbing_up == false:
			camera.position.x = move_toward(camera.position.x, bob_height_down.x, delta * 0.4)
			if camera.position == bob_height_down:
				bobbing_up = true
	else:
		camera.position = lerp(camera.position, Vector3(0.0,1.69,-0.25), delta * 10)
	
	move_and_slide()
