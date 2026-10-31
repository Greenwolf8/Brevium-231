extends CharacterBody3D

@export var walk_speed: float
@export var sprint_speed: float
@export var jump_speed: float
@export var climb_speed: float
@export var camera: Camera3D
@export var down_cast: RayCast3D
@export var front_cast: RayCast3D
@export var tween_timer: Timer

@onready var ship: Node3D = get_tree().get_first_node_in_group("player_ship")
@onready var main_scene = get_tree().root

var gravity_strength: float = 9.8
var bobbing_up: bool = true
var bob_height_down: Vector3 = Vector3(-0.05, 1.69, -0.25)
var bob_height_up: Vector3 = Vector3(0.05, 1.69, -0.25)

var on_gear_ladder: bool = false
var gear_ladder_bottom_pos: Vector3 = Vector3(0.0, -6.3, -36.0)
var gear_ladder_top_pos: Vector3 = Vector3(0.0, -2.44, -34.1)
var on_interior_ladder: bool = false
var interior_ladder_bottom_pos: Vector3
var interior_ladder_top_pos: Vector3
var current_ladder_pos: Vector3

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	if !is_multiplayer_authority():
		return
	camera.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	# Camera turning
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * 0.5
		camera.rotation_degrees.x -= event.relative.y * 0.5
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80.0, 80.0)
	
	elif event.is_action_pressed("Interact") and front_cast.is_colliding():
		var tween = create_tween()
		var tween_2 = create_tween()
		if front_cast.get_collider().name == "Gear Ladder Interact":
			if get_parent() == ship:
				current_ladder_pos = gear_ladder_top_pos
			else:
				current_ladder_pos = gear_ladder_bottom_pos
			on_gear_ladder = true
			reparent(ship, true)
			tween.tween_property(self, "position", current_ladder_pos, 0.25)
			tween_2.tween_property(self, "rotation_degrees", Vector3(-25.0, 180.0, 0.0), 0.25)
			tween_timer.start()
		
		elif front_cast.get_collider().name == "Interior Ladder Interact":
			on_interior_ladder = true
	
	elif event.is_action_pressed("P"):
		print("Position: ", position, "\nRotation: ", rotation_degrees)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	
	if on_gear_ladder:
		ladder_movement("Gear Ladder")
		return
	
	
	# Sprint 
	var speed: float
	if Input.is_action_pressed("Sprint"):
		speed = sprint_speed
	else:
		speed = walk_speed
	
	
	# Movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var direction = (global_transform.basis.x * input_dir.x * walk_speed + -global_transform.basis.z * input_dir.y * speed)
	if direction:
		velocity.x = move_toward(velocity.x, direction.x, delta * 40)
		velocity.z = move_toward(velocity.z, direction.z, delta * 40)
	else:
		velocity.x = move_toward(velocity.x, 0, delta * 100)
		velocity.z = move_toward(velocity.z, 0, delta * 100)
	
	# Gravity
	if down_cast.is_colliding():
		velocity.y = 0.01
	else:
		velocity.y -= gravity_strength * delta
	
	# Jump
	if Input.is_action_pressed("jump") and down_cast.is_colliding():
		velocity.y = jump_speed
	
	# Head bobbing
	if input_dir.y != 0.0:
		if bobbing_up == true:
			camera.position.x = move_toward(camera.position.x, bob_height_up.x, delta * 0.3)
			if camera.position.x == bob_height_up.x:
				bobbing_up = false
		elif bobbing_up == false:
			camera.position.x = move_toward(camera.position.x, bob_height_down.x, delta * 0.3)
			if camera.position.x == bob_height_down.x:
				bobbing_up = true
	else:
		camera.position = lerp(camera.position, Vector3(0.0,1.69,-0.25), delta * 10)
	
	move_and_slide()

func ladder_movement(ladder: String):
	if !tween_timer.is_stopped(): # Makes sure not moving during tween
		return
	
	var tween = create_tween()
	if ladder == "Gear Ladder": # Handles climbing the landing gear ladder
		var local_ladder_dir: Vector3 = Vector3(0.4663, 1.0, 0.0).normalized()
		var climb_input: float = Input.get_axis("move_back", "move_forward")
		if position.y <= -6.33:
			on_gear_ladder = false
			reparent(main_scene)
			tween.tween_property(self, "rotation_degrees", Vector3(0.0, -90.0, 0.0), 0.25)
			return
		elif position.y >= -0.69:
			on_gear_ladder = false
			tween.tween_property(self, "rotation_degrees", Vector3(0.0, -180.0, 0.0), 0.25)
			return
		else:
			velocity = local_ladder_dir * climb_input * climb_speed
	
	elif ladder == "Interior Ladder":
		var local_ladder_dir: Vector3 = Vector3(0.0, 1.0, 0.0).normalized()
		var climb_input: float = Input.get_axis("move_back", "move_forward")
		if position.y <= -6.33:
			on_interior_ladder = false
			return
		elif position.y >= -0.66:
			on_interior_ladder = false
			return
		else:
			velocity = local_ladder_dir * climb_input * climb_speed
	
	move_and_slide()
