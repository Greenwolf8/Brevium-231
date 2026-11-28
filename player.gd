extends CharacterBody3D

@export var walk_speed: float
@export var sprint_speed: float
@export var jump_speed: float
@export var climb_speed: float
@export var camera: Camera3D
@export var down_cast: RayCast3D
@export var front_cast: RayCast3D
@export var tween_timer: Timer

@onready var ship: Node3D = $"/root/Main/world container/Astro Vulcan"
@onready var main_scene = get_tree().root
@onready var body_collision: CollisionShape3D = $Body_Collision
@onready var engineer_camera: Camera3D = $"/root/Main/world container/Astro Vulcan/Engineer Camera"
@onready var pilot_camera: Camera3D = $"/root/Main/world container/Astro Vulcan/Pilot Camera"
@onready var gear_ladder_path: PathFollow3D = $"/root/Main/world container/Astro Vulcan/Gear Ladder Path/Gear Path Follow"
@onready var gear_ladder_remote_transform: RemoteTransform3D = $"/root/Main/world container/Astro Vulcan/Gear Ladder Path/Gear Path Follow/Player Remote Transform"
@onready var interior_ladder_path: PathFollow3D = $"/root/Main/world container/Astro Vulcan/Interior Ladder Path/Interior Path Follow"
@onready var interior_ladder_remote_transform: RemoteTransform3D = $"/root/Main/world container/Astro Vulcan/Interior Ladder Path/Interior Path Follow/Player Remote Transform"

var gravity_strength: float = 9.8
var bobbing_up: bool = true
var bob_height_down: Vector3 = Vector3(-0.05, 1.6, -0.35)
var bob_height_up: Vector3 = Vector3(0.05, 1.6, -0.35)
var tween_time: float = 0.25
var on_path: bool = false
var last_ship_transform: Transform3D
var horizontal_vel: Vector3
var vertical_vel: Vector3

# Vars for being in an interaction
var on_ship: bool = false
var in_cockpit: bool = false
var on_gear_ladder: bool = false
var on_interior_ladder: bool = false
var in_engineer_terminal: bool = false
var in_pilot_seat: bool = false

# Positions of places to move
@onready var engineer_terminal_pos: Marker3D =  $"/root/Main/world container/Astro Vulcan/Engineer Terminal Pos"
@onready var engineer_terminal_exit_pos: Marker3D =  $"/root/Main/world container/Astro Vulcan/Engineer Terminal Exit Pos"
@onready var pilot_seat_pos: Marker3D =  $"/root/Main/world container/Astro Vulcan/Pilot Seat Pos"
@onready var pilot_seat_exit_pos: Marker3D =  $"/root/Main/world container/Astro Vulcan/Pilot Seat Exit Pos"

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	if !is_multiplayer_authority():
		return
	camera.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	last_ship_transform = ship.global_transform

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	# Camera turning
	if event is InputEventMouseMotion and !in_engineer_terminal and !in_pilot_seat:
		rotate_object_local(Vector3.UP, -event.relative.x * 0.003)
		camera.rotate_x(-event.relative.y * 0.003)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -70.0, 70.0)
	
	elif event.is_action_pressed("Interact") and in_engineer_terminal:
		exit_engineer_terminal()
	elif event.is_action_pressed("Interact") and in_pilot_seat:
		exit_pilot_seat()
	
	elif event.is_action_pressed("Interact") and front_cast.is_colliding():
		if front_cast.get_collider().name == "Gear Ladder Interact":
			on_gear_ladder = true
		
		elif front_cast.get_collider().name == "Interior Ladder Interact":
			on_interior_ladder = true
		
		elif front_cast.get_collider().name == "Engineer Terminal Interact":
			enter_engineer_terminal()
		
		elif front_cast.get_collider().name == "Pilot Seat Interact":
			enter_pilot_seat()
	
	elif event.is_action_pressed("P"):
		print("Position: ", position, "\nRotation: ", rotation_degrees)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority() or in_engineer_terminal or in_pilot_seat:
		return
	
	if on_gear_ladder:
		ladder_movement("Gear", delta)
		return
	elif on_interior_ladder:
		ladder_movement("Interior", delta)
		return
	
	if on_ship:
		ship_movement(delta)
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

func ship_movement(delta: float):
	# Sprint 
	var speed: float
	if Input.is_action_pressed("Sprint"):
		speed = sprint_speed
	else:
		speed = walk_speed
	
	var input_dir: Vector2 = Input.get_vector("move_back", "move_forward", "move_left", "move_right")
	var move_dir: Vector3 = (basis.x * input_dir.x) + (basis.z * input_dir.y)
	move_dir = move_dir.normalized()
	
	var direction: Vector3 = (ship.global_transform.basis.x * move_dir.x) + (ship.global_transform.basis.z * move_dir.z)
	direction = direction.normalized() * speed
	
	var local_pos: Vector3 = ship.global_position - global_position
	var rot_vel: Vector3 = ship.angular_velocity.cross(local_pos)
	var target_ship_vel: Vector3 = ship.linear_velocity + rot_vel
	
	var target_vel_x: float = target_ship_vel.x
	var target_vel_z: float = target_ship_vel.z
	if input_dir:
		target_vel_x = target_ship_vel.x + direction.x
		target_vel_z = target_ship_vel.z + direction.z
	else: 
		target_vel_x = target_ship_vel.x
		target_vel_z = target_ship_vel.z
	
	if input_dir:
		horizontal_vel.x = move_toward(horizontal_vel.x, target_vel_x, delta * 40.0)
		horizontal_vel.z = move_toward(horizontal_vel.z, target_vel_z, delta * 40.0)
	else:
		horizontal_vel.x = move_toward(horizontal_vel.x, target_vel_x, delta * 100)
		horizontal_vel.z = move_toward(horizontal_vel.z, target_vel_z, delta * 100)
	
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
	var grav_dir: Vector3 = -ship.global_basis.y.normalized()
	up_direction = -grav_dir
	if down_cast.is_colliding():
		vertical_vel = up_direction * 0.01
	else:
		vertical_vel -= up_direction * gravity_strength * delta
	
	# Jump
	if Input.is_action_pressed("jump") and down_cast.is_colliding():
		vertical_vel += up_direction * jump_speed
	
	# Match ship rotation
	var right = -global_transform.basis.z.cross(up_direction).normalized()
	var forward = up_direction.cross(right).normalized()
	
	global_transform.basis = Basis(right, up_direction, -forward)
	
	velocity = horizontal_vel + vertical_vel
	move_and_slide()

func ground_movement(delta):
	# Sprint 
	var speed: float
	if Input.is_action_pressed("Sprint"):
		speed = sprint_speed
	else:
		speed = walk_speed
	# Movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis.x * input_dir.x + transform.basis.z * input_dir.y).normalized()
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, delta * 40)
		velocity.z = move_toward(velocity.z, direction.z * speed, delta * 40)
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

func ladder_movement(ladder: String, delta: float):
	if !tween_timer.is_stopped(): # Makes sure not moving during tween
		return
	
	match ladder:
		"Gear": # Handles climbing the landing gear ladder
			if !on_path and !on_ship:
				enter_ladder("Gear","Bottom", delta)
				return
			elif !on_path and on_ship:
				enter_ladder("Gear","Top", delta)
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
		
		"Interior":
			if !on_path and !in_cockpit:
				enter_ladder("Interior","Bottom", delta)
				return
			elif !on_path and in_cockpit:
				enter_ladder("Interior", "Top", delta)
			else:
				if interior_ladder_path.progress_ratio == 1.0:
					exit_ladder("Interior", "Top")
				elif interior_ladder_path.progress_ratio == 0.0:
					exit_ladder("Interior", "Bottom")
				
				var climb_input: float = Input.get_axis("move_back", "move_forward")
				if interior_ladder_path.progress_ratio > 0.75 and !in_cockpit:
					interior_ladder_path.progress += 2.0 * delta
				elif interior_ladder_path.progress_ratio > 0.75 and in_cockpit:
					interior_ladder_path.progress -= 2.0 * delta
				elif climb_input > 0.0:
					interior_ladder_path.progress += 1.5 * delta
				elif climb_input < 0.0:
					interior_ladder_path.progress -= 1.5 * delta
	
	move_and_slide()

func enter_ladder(ladder: String, enter_position: String, delta: float):
	var snap_distance: float = 0.05
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
		"Interior":
			if enter_position == "Top":
				interior_ladder_path.progress_ratio = 0.99
			elif enter_position == "Bottom":
				interior_ladder_path.progress_ratio = 0.01
			
			%"Body_Collision".disabled = true
			target_pos = interior_ladder_path.global_position
			distance = global_position.distance_to(target_pos)
			
			if distance <= snap_distance:
				on_path = true
				interior_ladder_remote_transform.remote_path = self.get_path()
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
		
		"Interior":
			if exit_position == "Top":
				on_interior_ladder = false
				on_path = false
				in_cockpit = true
				interior_ladder_remote_transform.remote_path = ""
			elif exit_position == "Bottom":
				on_interior_ladder = false
				on_path = false
				in_cockpit = false
				interior_ladder_remote_transform.remote_path = ""
			%"Body_Collision".disabled = false

func enter_engineer_terminal():
		var tween_pos = create_tween()
		var tween_rot = create_tween()
		var tween_cam_rot = create_tween()
		tween_pos.set_trans(Tween.TRANS_SINE)
		tween_rot.set_trans(Tween.TRANS_SINE)
		tween_cam_rot.set_trans(Tween.TRANS_SINE)
		tween_pos.tween_property(self, "position", engineer_terminal_pos.global_position, tween_time)
		tween_rot.tween_property(self, "rotation", engineer_terminal_pos.global_rotation - Vector3(engineer_terminal_pos.global_rotation.x, deg_to_rad(180.0), 0.0), tween_time)
		tween_cam_rot.tween_property(camera,"rotation", engineer_terminal_pos.global_rotation - Vector3(0.0, engineer_terminal_pos.global_rotation.y, engineer_terminal_pos.global_rotation.z), tween_time)
		body_collision.disabled = true
		await tween_rot.finished
		in_engineer_terminal = true
		camera.clear_current()
		engineer_camera.make_current()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func exit_engineer_terminal():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", engineer_terminal_exit_pos.global_position, tween_time)
	camera.make_current()
	engineer_camera.clear_current()
	await tween.finished
	body_collision.disabled = false
	in_engineer_terminal = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	engineer_camera.reset_pos()
	return

func enter_pilot_seat(delta: float):
	var distance: float = global_position.distance_to(pilot_seat_pos.global_position)
	
	global_position.x = move_toward(global_position.x, pilot_seat_pos.global_position.x, delta * 4.0 * abs(global_position.x - pilot_seat_pos.global_position.x))
	global_position.y = move_toward(global_position.y, pilot_seat_pos.global_position.y, delta * 4.0 * abs(global_position.y - pilot_seat_pos.global_position.y))
	global_position.z = move_toward(global_position.z, pilot_seat_pos.global_position.z, delta * 4.0 * abs(global_position.z - pilot_seat_pos.global_position.z))
	
	camera.global_rotation.x = move_toward(camera.global_rotation.x, pilot_seat_pos.global_rotation.x,  (delta * abs(camera.global_rotation.x - pilot_seat_pos.global_position.x) / 25.0))
	global_rotation.y = move_toward(global_rotation.y, pilot_seat_pos.global_rotation.y, (delta * abs(global_rotation.y - pilot_seat_pos.global_position.y) / 25.0))
	global_rotation.z = move_toward(global_rotation.z, pilot_seat_pos.global_rotation.z, (delta * abs(global_rotation.z - pilot_seat_pos.global_position.z) / 25.0))
	
	body_collision.disabled = true
	
	if distance <= 0.01:
		entering_pilot_seat = false
		in_pilot_seat = true 
		camera.clear_current()
		pilot_camera.make_current()

func exit_pilot_seat(delta: float):
	var distance: float = global_position.distance_to(pilot_seat_exit_pos.global_position)
	
	global_position.x = move_toward(global_position.x, pilot_seat_exit_pos.global_position.x, delta * 4.0 * abs(global_position.x - pilot_seat_exit_pos.global_position.x))
	global_position.y = move_toward(global_position.y, pilot_seat_exit_pos.global_position.y, delta * 4.0 * abs(global_position.y - pilot_seat_exit_pos.global_position.y))
	global_position.z = move_toward(global_position.z, pilot_seat_exit_pos.global_position.z, delta * 4.0 * abs(global_position.z - pilot_seat_exit_pos.global_position.z))
	
	camera.global_rotation.x = move_toward(camera.global_rotation.x, pilot_seat_exit_pos.global_rotation.x,  (delta * abs(camera.global_rotation.x - pilot_seat_exit_pos.global_position.x) / 25.0))
	global_rotation.y = move_toward(global_rotation.y, pilot_seat_exit_pos.global_rotation.y, (delta * abs(global_rotation.y - pilot_seat_exit_pos.global_position.y) / 25.0))
	global_rotation.z = move_toward(global_rotation.z, pilot_seat_exit_pos.global_rotation.z, (delta * abs(global_rotation.z - pilot_seat_exit_pos.global_position.z) / 25.0))
	
	camera.make_current()
	pilot_camera.clear_current()
	if distance <= 0.1:
		exiting_pilot_seat = false
		in_pilot_seat = false
		body_collision.disabled = false
		pilot_camera.reset()
		return

