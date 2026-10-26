extends CharacterBody3D

@export var walk_speed: float
@export var sprint_speed: float
@export var jump_speed: float
@export var camera: Camera3D
@export var down_cast: RayCast3D

var gravity_strength: float = 9.8
var bobbing_up: bool = true
var bob_height_down: Vector3 = Vector3(-0.1, 1.69, -0.25)
var bob_height_up: Vector3 = Vector3(0.1, 1.69, -0.25)

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	if !is_multiplayer_authority():
		return
	camera.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	down_cast.add_exception(self)

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
	
	# Sprint 
	var speed: float
	if Input.is_action_pressed("Sprint"):
		speed = sprint_speed
	else:
		speed = walk_speed
	
	# Movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var direction = (global_transform.basis.x * input_dir.x + -global_transform.basis.z * input_dir.y)
	
	if direction:
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Gravity and Jump
	if !down_cast.is_colliding():
		velocity.y -= gravity_strength * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_speed
	
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
