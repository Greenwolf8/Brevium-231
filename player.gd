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
@onready var body_collision: CollisionShape3D = $Body_Collision
@onready var engineer_camera: Camera3D = $"/root/Main/world container/Astro Vulcan/Engineer Camera"
@onready var pilot_camera: Camera3D = $"/root/Main/world container/Astro Vulcan/Pilot Camera"
@onready var gear_ladder_path: PathFollow3D = $"/root/Main/world container/Astro Vulcan/Gear Ladder Path/Gear Path Follow"
@onready var gear_ladder_remote_transform: RemoteTransform3D = $"/root/Main/world container/Astro Vulcan/Gear Ladder Path/Gear Path Follow/Player Remote Transform"

var gravity_strength: float = 9.8
var bobbing_up: bool = true
var bob_height_down: Vector3 = Vector3(-0.05, 1.6, -0.35)
var bob_height_up: Vector3 = Vector3(0.05, 1.6, -0.35)
var tween_time: float = 0.25
var on_path: bool = false

# Vars for being in an interaction
var on_ship: bool = false
var on_gear_ladder: bool = false
var on_interior_ladder: bool = false
var in_engineer_terminal: bool = false
var in_pilot_seat: bool = false

# Positions of places to move
var engineer_terminal_pos: Vector3 = Vector3(1.76, 2.6, -26.1)
var engineer_terminal_rot: Vector3 = Vector3(0.0, -180.0, 0.0)
var engineer_terminal_exit_pos: Vector3 = Vector3(1.75, 2.816, -26.49)
var pilot_seat_pos: Vector3 = Vector3(0.771, 2.124, -35.223)
var pilot_seat_exit_pos: Vector3 = Vector3(0.771, 2.825, -34.083)
var current_ladder_pos: Vector3
var interior_ladder_bottom_pos: Vector3 = Vector3(-1.91, -0.8, -32.1)
var interior_ladder_top_pos: Vector3 = Vector3(-1.91, 2.0, -32.1)

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
	if event is InputEventMouseMotion and !in_engineer_terminal:
		rotation_degrees.y -= event.relative.x * 0.5
		camera.rotation_degrees.x -= event.relative.y * 0.5
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -70.0, 70.0)
	
	elif event.is_action_pressed("Interact") and in_engineer_terminal:
		exit_engineer_terminal()
	elif event.is_action_pressed("Interact") and in_pilot_seat:
		exit_pilot_seat()
	
	elif event.is_action_pressed("Interact") and front_cast.is_colliding():
		if front_cast.get_collider().name == "Gear Ladder Interact":
			on_gear_ladder = true
		
		elif front_cast.get_collider().name == "Interior Ladder Interact":
			enter_interior_ladder()
		
		elif front_cast.get_collider().name == "Engineer Terminal Interact":
			enter_engineer_terminal()
		
		elif front_cast.get_collider().name == "Pilot Seat Interact":
			enter_pilot_seat()
	
	elif event.is_action_pressed("P"):
		print("Position: ", position, "\nRotation: ", rotation_degrees)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	if in_engineer_terminal:
		return
	if on_gear_ladder:
		ladder_movement("Gear", delta)
		return
	elif on_interior_ladder:
		ladder_movement("Interior Ladder")
		return
	
	if get_parent() == ship:
		ship_movement(ship, delta)
		return
	else:
		ground_movement(delta)
		return

func _process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	
	if in_pilot_seat:
		if ship.throttle >= 0.0:
			if Input.is_action_pressed("throttle_up"):
				ship.target_throttle += 75 * delta
			elif Input.is_action_pressed("throttle_down"):
				ship.target_throttle -= 75 * delta
		else:
			if Input.is_action_pressed("throttle_up"):
				ship.target_throttle += 40 * delta
			elif Input.is_action_pressed("throttle_down"):
				ship.target_throttle -= 40 * delta

func ship_movement(_ship: Node3D, delta):
	# Sprint 
	var speed: float
	if Input.is_action_pressed("Sprint"):
		speed = sprint_speed
	else:
		speed = walk_speed
	
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var direction: Vector3 = (-transform.basis.x * input_dir.y * speed + -transform.basis.z * input_dir.x * walk_speed)
	if direction:
		velocity.x = move_toward(velocity.x, direction.x, delta * 40)
		velocity.z = move_toward(velocity.z, direction.z, delta * 40)
	else:
		velocity.x = move_toward(velocity.x, 0, delta * 100)
		velocity.z = move_toward(velocity.z, 0, delta * 100)
	
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
		camera.position = lerp(camera.position, Vector3(0.0,1.6,-0.35), delta * 10)
	
	# Gravity
	if down_cast.is_colliding():
		velocity.y = 0.01
	else:
		velocity.y -= gravity_strength * delta
	
	# Jump
	if Input.is_action_pressed("jump") and down_cast.is_colliding():
		velocity.y = jump_speed
	
	move_and_slide()

func ground_movement(delta):
	# Sprint 
	var speed: float
	if Input.is_action_pressed("Sprint"):
		speed = sprint_speed
	else:
		speed = walk_speed
	# Movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var direction: Vector3 = (transform.basis.x * input_dir.x * walk_speed + -transform.basis.z * input_dir.y * speed)
	if direction:
		velocity.x = move_toward(velocity.x, direction.x, delta * 40)
		velocity.z = move_toward(velocity.z, direction.z, delta * 40)
	else:
		velocity.x = move_toward(velocity.x, 0, delta * 100)
		velocity.z = move_toward(velocity.z, 0, delta * 100)
	
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
		camera.position = lerp(camera.position, Vector3(0.0,1.6,-0.35), delta * 10)
	
	# Gravity
	if down_cast.is_colliding():
		velocity.y = 0.01
	else:
		velocity.y -= gravity_strength * delta
	
	# Jump
	if Input.is_action_pressed("jump") and down_cast.is_colliding():
		velocity.y = jump_speed
	
	move_and_slide()

func enter_interior_ladder():
	var tween = create_tween()
	if position.y >= 0.0:
		current_ladder_pos = interior_ladder_top_pos
	else:
		current_ladder_pos = interior_ladder_bottom_pos
func ladder_movement(ladder: String, delta: float):
	if !tween_timer.is_stopped(): # Makes sure not moving during tween
		return
	
	match ladder:
		"Gear": # Handles climbing the landing gear ladder
			if !on_path:
				enter_ladder("Gear","Bottom", delta)
				return
			else:
				if gear_ladder_path.progress_ratio == 1.0:
					exit_ladder("Gear", "Top")
				elif gear_ladder_path.progress_ratio == 0.0:
					exit_ladder("Gear", "Bottom")
				
				var climb_input: float = Input.get_axis("move_back", "move_forward")
				
				if climb_input > 0.0:
					gear_ladder_path.progress += 1.5 * delta
				elif climb_input < 0.0:
					gear_ladder_path.progress -= 1.5 * delta
		
	
	body_collision.disabled = true
	on_interior_ladder = true
	tween.tween_property(self, "position", current_ladder_pos, tween_time)
	tween_timer.start()
	move_and_slide()

func enter_ladder(ladder: String, enter_position: String, delta: float):
	var snap_distance: float = 0.2
	var move_speed: float = 150.0
	
	var target_pos: Vector3 = Vector3.ZERO
	var distance: float = 0.0
	
	match ladder:
		"Gear":
			if enter_position == "Top":
				gear_ladder_path.progress_ratio = 0.99
			elif enter_position == "Bottom":
				gear_ladder_path.progress_ratio = 0.01
			
			target_pos = gear_ladder_path.global_position
			distance = global_position.distance_to(target_pos)
			
			if distance <= snap_distance:
				on_path = true
				on_ship = true
				gear_ladder_remote_transform.remote_path = self.get_path()
				return
			
			var direction: Vector3 = (target_pos - global_position).normalized()
			velocity = direction * move_speed * delta
			move_and_slide()
func exit_ladder(ladder: String, exit_position: String):
	match ladder:
		"Gear":
			if exit_position == "Top":
				on_gear_ladder = false
				on_path = false
				gear_ladder_remote_transform.remote_path = ""
			elif exit_position == "Bottom":
				on_gear_ladder = false
				on_path = false
				gear_ladder_remote_transform.remote_path = ""
				on_ship = false
		

func enter_engineer_terminal():
		var tween_pos = create_tween()
		var tween_rot = create_tween()
		var tween_cam_rot = create_tween()
		tween_pos.set_trans(Tween.TRANS_SINE)
		tween_rot.set_trans(Tween.TRANS_SINE)
		tween_cam_rot.set_trans(Tween.TRANS_SINE)
		tween_pos.tween_property(self, "position", engineer_terminal_pos, tween_time)
		tween_rot.tween_property(self, "rotation_degrees", engineer_terminal_rot, tween_time)
		tween_cam_rot.tween_property(camera,"rotation_degrees", Vector3.ZERO, tween_time)
		await tween_rot.finished
		in_engineer_terminal = true
		camera.clear_current()
		engineer_camera.make_current()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func exit_engineer_terminal():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", engineer_terminal_exit_pos, tween_time)
	camera.make_current()
	engineer_camera.clear_current()
	await tween.finished
	in_engineer_terminal = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	engineer_camera.reset_pos()
	return

func enter_pilot_seat():
		var tween_pos = create_tween()
		var tween_rot = create_tween()
		var tween_cam_rot = create_tween()
		tween_pos.set_trans(Tween.TRANS_SINE)
		tween_rot.set_trans(Tween.TRANS_SINE)
		tween_cam_rot.set_trans(Tween.TRANS_SINE)
		tween_pos.tween_property(self, "position", pilot_seat_pos, tween_time)
		tween_rot.tween_property(self, "rotation_degrees", Vector3.ZERO, tween_time)
		tween_cam_rot.tween_property(camera,"rotation_degrees", Vector3.ZERO, tween_time)
		await tween_rot.finished
		in_pilot_seat = true
		camera.clear_current()
		pilot_camera.make_current()

func exit_pilot_seat():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", pilot_seat_exit_pos, tween_time)
	camera.make_current()
	pilot_camera.clear_current()
	await tween.finished
	in_pilot_seat = false
	pilot_camera.reset()
	return
