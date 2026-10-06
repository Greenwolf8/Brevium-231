extends CharacterBody3D

@onready var down_cast: RayCast3D = %RayCast3D
@onready var camera: Camera3D = %PlayerCamera
@onready var front_cast: RayCast3D = %FrontCast
@onready var task_label: Label = %TaskLabel
@onready var task_title_label: Label = %TaskHeaderLabel
@onready var kill_label: Label = %"Kill Label"
@onready var points_label: Label = %PointsLabel
@onready var press_e_label: Label = %PressE
@onready var ship_terminal_screen: CanvasLayer = %ShipTerminal
@onready var ui_container: CanvasLayer = %UI
@onready var crosshair_node: Control = %CrossHair
@onready var chair = "Chair:<StaticBody3D#37094426288>"
@onready var hangar = get_tree().get_first_node_in_group("Hangar Script")
@onready var ship = get_tree().get_first_node_in_group("player_ship")
@onready var ship_node = $"/root/Map/Node3D/Ship" # I know this is weird but the show() function needs it when calling ship. the "ship" variable does not work
@onready var pause_menu = preload("uid://ox3i4s5dtpur")

var climb_speed: float = 2.5
var walk: float = 5
var sprint: float = 10
var leave_seat_location: Vector3 = Vector3(21,3.38,57.475)
var gravity: float = 11
var is_sprinting: bool = false
var speed: float = walk
var current_ladder: Area3D = null
var hit_object = null
var in_console: bool = false
var old_position: Vector3
var old_rotation: Vector3
var screen_position: Vector3
var screen_rotation: Vector3 
var rot_diff: Vector3 = Vector3.ZERO
var shortest_target: Vector3
var on_gear_ladder: bool = false
var on_interior_ladder: bool = false
var current_task: int = 0
var enemies_destroyed: int = 0

func _ready() -> void:
	$fade_transition/AnimationPlayer.play("fade_out")
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	front_cast.add_exception(self)
	camera.current = is_multiplayer_authority()
	if is_multiplayer_authority():
		task_title_label.text = "Current Task: Summon Your Ship"
		task_label.text = "Interact With The Hangar Screen"
		points_label.text = "Enemies Destroyed: " + str(enemies_destroyed)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event.is_action_pressed("ui_cancel") and not Global.is_paused:
		get_tree().set_pause(true)
		get_tree().current_scene.add_child(pause_menu.instantiate())
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Global.is_paused = true
		return
	
	if not in_console and not Global.in_ship_console:
		if event.is_action_pressed("interact"):
			interact_pressed()
		
		if event is InputEventMouseMotion:
			camera.rotation_degrees.y -= event.relative.x * 0.5
			camera.rotation_degrees.x -= event.relative.y * 0.5
			camera.rotation_degrees.x = clamp(
			camera.rotation_degrees.x, -80.0, 80.0
			)
	
	else:
		if event.is_action_pressed("interact"):
			hangar_console_interact()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not in_console and not Global.in_ship_console and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not in_console and not Global.in_ship_console and not Global.is_pilot and not Global.is_wo:
		if not front_cast.is_colliding():
			%PressE.hide()
			hit_object = null
		else:
			%PressE.show()
			hit_object = front_cast.get_collider()
		
		if Input.is_action_pressed("sprint"):
			speed = sprint
		else:
			speed = walk
		
		if on_gear_ladder or on_interior_ladder: #Movement on a ladder
			var ship_velocity = ship.linear_velocity
			var climb_input = Input.get_axis("move_back", "move_forward") 
			
			if on_gear_ladder: #Movement on landing gear ladder
				var local_ladder_dir: Vector3 = Vector3(0.4663, 1.0, 0.0).normalized()
				var world_climb_dir : Vector3 = ship.global_transform.basis * local_ladder_dir * climb_input
				
				if position.y < -5.7 and climb_input < 0:
					do_climb_gear_ladder.rpc(false, Vector3.ZERO)
					Global.in_ship = false
					climb_gear_ladder()
				elif position.y > 0 and climb_input > 0:
					climb_gear_ladder()
					Global.in_ship = true
					if current_task == 1:
						next_task() #rpc("next_task")
					else:
						pass
				else:
					velocity = ship_velocity + (world_climb_dir * climb_speed)
			
			elif on_interior_ladder: #Movement on the interior ladder
				var world_climb_dir : Vector3 = ship.global_transform.basis.y * climb_input
				
				if position.y < 0 and climb_input < 0:
					climb_interior_ladder()
				elif position.y > 3.5 and climb_input > 0:
					climb_interior_ladder()
				else:
					velocity = ship_velocity + (world_climb_dir * climb_speed)
			move_and_slide()
		
		elif Global.in_ship: #Movement on ship 
			var input_dir := Input.get_vector ("move_left","move_right","move_forward", "move_back")
			var cam_basis := camera.global_transform.basis
			var ship_basis : Basis = ship.global_transform.basis
			var forward := -cam_basis.z
			var right := cam_basis.x
			@warning_ignore("shadowed_variable")
			
			forward = (forward - forward.project(ship_basis.y)).normalized()
			right = (right - right.project(ship_basis.y)).normalized()
			
			var direction := Vector3.ZERO
			if input_dir != Vector2.ZERO:
				direction = (forward * -input_dir.y) + (right * input_dir.x)
			
			
			var current_horizontal_velocity = velocity - velocity.project(ship_basis.y)
			var current_vertical_velocity = velocity.project(ship_basis.y)
			
			if direction != Vector3.ZERO:
				current_horizontal_velocity = direction * speed
			else:
				current_horizontal_velocity = current_horizontal_velocity.move_toward(Vector3.ZERO, speed * delta * 10)
			if down_cast.is_colliding():
				current_vertical_velocity = Vector3.ZERO
				if Input.is_action_just_pressed("jump"):
					current_vertical_velocity = ship_basis.y * 4.5
			else:
				current_vertical_velocity += -ship_basis.y * 11 * delta
			
			velocity = current_horizontal_velocity + current_vertical_velocity
			
			move_and_slide()
		
		else: #Movement on ground
			var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
			var direction := Vector3.ZERO
			
			if not is_on_floor():
				velocity.y -= gravity * delta
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = 4.5
		
			if input_dir != Vector2.ZERO:
				var cam_forward := -camera.global_transform.basis.z
				var cam_right := camera.global_transform.basis.x
				
				cam_forward.y = 0
				cam_right.y = 0
				cam_forward = cam_forward.normalized()
				cam_right = cam_right.normalized()
				
				direction = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()
			
			
			if direction:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
			if not in_console:
				move_and_slide()
	else:
		%PressE.hide()

func hangar_console_interact():
	screen_position = Vector3(-1916.744, 2629.374, -53.17)
	screen_rotation = Vector3(-1.169371, -3.141593, 0.0)
	var tween = create_tween()
	
	if not in_console and not Global.in_ship_console:
		old_rotation.x = wrapf(camera.global_rotation.x, -PI, PI)
		old_rotation.y = wrapf(camera.global_rotation.y, -PI, PI)
		old_position = camera.global_position
		
		rot_diff.x = wrapf(screen_rotation.x - camera.global_rotation.x, -PI, PI)
		rot_diff.y = wrapf(screen_rotation.y - camera.global_rotation.y, -PI, PI)
		shortest_target = camera.global_rotation + rot_diff
		tween.tween_property(camera, "global_position", screen_position, 0.25)
		tween.parallel().tween_property(camera, "global_rotation", shortest_target, 0.25)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		rpc("sync_open_hangar")
		ui_container.hide()
		in_console = true
	elif in_console and not Global.in_ship_console:
		rot_diff.x = wrapf(old_rotation.x - camera.global_rotation.x, -PI, PI)
		rot_diff.y = wrapf(old_rotation.y - camera.global_rotation.y, -PI, PI)
		shortest_target = camera.global_rotation + rot_diff
		tween.tween_property(camera, "global_position", old_position, 0.5)
		tween.parallel().tween_property(camera, "global_rotation", shortest_target, 0.5)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		ui_container.show()
		await get_tree().create_timer(0.5).timeout
		in_console = false 

func ship_console_interact():
	var ship_target_pos = Vector3(29.52, 6.555, -0.44)
	var ship_target_rot = Vector3(0.785398, -1.570796, 0.0)
	var ship_target_transform = Transform3D(Basis.from_euler(ship_target_rot), ship_target_pos)
	var world_target_transform = ship.global_transform * ship_target_transform
	var player_local_transform = global_transform.affine_inverse() * world_target_transform
	var target_local_pos = player_local_transform.origin
	var target_local_rot = player_local_transform.basis.get_euler()
	var tween = create_tween()
	
	if not Global.in_ship_console:
		old_rotation = camera.rotation
		old_position = camera.position
		
		rot_diff.x = wrapf(target_local_rot.x - camera.rotation.x, -PI, PI)
		rot_diff.y = wrapf(target_local_rot.y - camera.rotation.y, -PI, PI)
		rot_diff.z = wrapf(target_local_rot.z - camera.rotation.z, -PI, PI)
		shortest_target = camera.rotation + rot_diff
		
		tween.tween_property(camera, "position", target_local_pos, 0.25)
		tween.parallel().tween_property(camera, "rotation", shortest_target, 0.25)
		await tween.finished
		
		ship_terminal_screen.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Global.in_ship_console = true
		press_e_label.jide()
		crosshair_node.hide()
		set_physics_process(false)
	else:
		rot_diff.x = wrapf(old_rotation.x - camera.rotation.x, -PI, PI)
		rot_diff.y = wrapf(old_rotation.y - camera.rotation.y, -PI, PI)
		rot_diff.z = wrapf(old_rotation.z - camera.rotation.z, -PI, PI)
		shortest_target = camera.rotation + rot_diff
		
		tween.tween_property(camera, "position", old_position, 0.5)
		tween.parallel().tween_property(camera, "rotation", shortest_target, 0.5)
		
		ship_terminal_screen.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Global.in_ship_console = false 
		press_e_label.show()
		crosshair_node.show()
		
		set_physics_process(true)

func enter_pilot_seat():
	set_physics_process(false)
	hide()
	%PressE.hide()
	ship.enter_pilot()
	camera.current = false
	Global.is_pilot = true
	%CrossHair.hide()

func leave_pilot_seat():
	position = leave_seat_location
	velocity = get_platform_velocity()
	set_physics_process(true)
	show()
	ship.leave_pilot()
	camera.current = true 
	Global.is_pilot = false
	%CrossHair.show()

func enter_wo_seat():
	set_physics_process(false)
	hide()
	%PressE.hide()
	ship.enter_wo()
	camera.current = false
	Global.is_wo = true
	%CrossHair.hide()

func leave_wo_seat():
	position = leave_seat_location
	velocity = get_platform_velocity()
	set_physics_process(true)
	show()
	ship.leave_wo()
	camera.current = true 
	Global.is_wo = false
	%CrossHair.show()

@rpc("any_peer", "call_local", "reliable")
func sync_open_hangar():
	if Global.hangar_open:
		hangar.call_ship()
		ship.hide()
	else:
		hangar.call_ship()
		await get_tree().create_timer(41.6667).timeout
		ship_node.show()
		if current_task == 0:
			#rpc("next_task")
			next_task()
		else:
			pass

func interact_pressed():
	if not Global.is_pilot and not Global.is_wo:
		if hit_object and hit_object.is_in_group("Pilot Seat"):
			camera.current = false
			enter_pilot_seat()
			hide()
			_physics_process(false)
		if hit_object and hit_object.is_in_group("WO Seat"):
			camera.current = false
			enter_wo_seat()
			hide()
			_physics_process(false)
		elif hit_object and hit_object.is_in_group("Hangar_Screen"):
			hangar_console_interact()
			_physics_process(false)
		elif (hit_object and hit_object.is_in_group("Ship_Console")) and not Global.in_ship_console:
			ship_console_interact()
			set_physics_process(false)
			Global.in_ship_console = true
		elif hit_object and hit_object.is_in_group("Ladder Gear"):
			climb_gear_ladder()
		elif hit_object and hit_object.is_in_group("Ladder Interior"):
			climb_interior_ladder()
		elif on_gear_ladder:
			climb_gear_ladder()
	elif Global.is_pilot:
		leave_pilot_seat()
		
	elif Global.is_wo:
		leave_wo_seat()

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func climb_gear_ladder():
	var ladder_local = Vector3(20,-5.5,57.475)
	if not on_gear_ladder:
		do_climb_gear_ladder.rpc(true, ladder_local)
		on_gear_ladder = true
		%CollisionShape3D2.disabled = true
	else:
		on_gear_ladder = false
		%CollisionShape3D2.disabled = false

func climb_interior_ladder():
	var ladder_local = Vector3(22.8,0,59.416)
	if not on_interior_ladder:
		var tween = create_tween()
		tween.tween_property(self, "position", ladder_local, 0.25)
		on_interior_ladder = true
		%CollisionShape3D2.disabled= true
	else:
		on_interior_ladder = false
		%CollisionShape3D2.disabled = false

@rpc("any_peer", "call_local", "reliable")
func do_climb_gear_ladder(attaching: bool, ladder_local: Vector3) -> void:
	var tween = create_tween()
	if attaching:
		reparent(ship, true)
		tween.tween_property(self, "position", ladder_local, 0.25)
	else:
		reparent(get_tree().current_scene, true)

#@rpc("any_peer", "call_local")
func next_task():
	Global.current_task += 1
	
	if is_multiplayer_authority():
		current_task += 1
		if current_task == 0:
			task_title_label.text = "Current Task: Summon Ship"
			task_label.text = "Interact With The Hangar Screen And Wait For The Ship To Be Summoned"
		elif current_task == 1:
			task_title_label.text = "Current Task: Enter Ship"
			task_label.text = "Climb The Ship's Ladder Located In The Front Landing Gear"
		elif current_task == 2:
			task_title_label.text = "Current Task: Start Ship"
			task_label.text = "Interact with the console in the rear of the cockpit.\nType 'HELP' to see list of commands"
		elif current_task == 3:
			task_title_label.text = "Current Task: Hunt Down The Enemy"
			task_label.text = "Using Shift/Control For Throttle And WASD To Steer, \nLocate And Hunt Down The Enemy"
		elif current_task == 4:
			task_title_label.text = "Current Task: Eliminate Enemy"
			task_label.text = "Press F Or Left Click To Fire The Cannon, Try To Dodge The Enemy's Cannons \nDo Not Underestimate The Enemy!"
			await get_tree().create_timer(15).timeout
			task_label.hide()

func enemy_destroyed():
	kill_label.show()
	await get_tree().create_timer(2).timeout
	var tween = create_tween()
	tween.tween_property(kill_label, "modulate:a", 0.0, 0.5 )
	enemies_destroyed += 1
	points_label.text = "Enemies Destroyed:" + str(enemies_destroyed)
