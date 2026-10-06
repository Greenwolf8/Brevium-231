extends RigidBody3D

@export var engine_power = 150
@export var roll_torque = 1200
@export var pitch_torque = 1250
@export var bullet_scene : PackedScene = preload("uid://dkgqrgnm6bsvi")
@export var muzzle_spread: float = 0.1
@export var shoot_colliding_label: Label

@onready var fire_point = %Hardpoint_1/Cannon/Cannon/MuzzleExit
@onready var fire_timer = %Hardpoint_1/Cannon/Cannon/FireTimer
@onready var pre_fire_timer = %Hardpoint_1/Cannon/Cannon/PreFireTimer
@onready var fire_time = %Hardpoint_1/Cannon/Cannon/FireTime
@onready var pilot_camera: Camera3D = %PilotCamera
@onready var wo_camera: Camera3D = %WOCamera
@onready var throttle_label: Label = %Throttle
@onready var health_label: Label = %HealthLabel	
@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("Player")
@onready var bullet_container = $/root/Map/PlayerBulletContainer
@onready var ai_ship: Node3D = null
@onready var distance: float = 0

var mouse_input: Vector2 = Vector2.ZERO
var health: int = 200
var Camerafree = false
var throttle: float = 0
var forward_move: float = 0.0
var rwr_detection_range: float = 10000
var rwr_active_threats: Array = []

func _ready() -> void:
	health_label.text = "Health: " + str(health)
	%Exterior.area_entered.connect(_on_area_entered)

func _unhandled_input(event: InputEvent) -> void:
	if Camerafree and event is InputEventMouseMotion:
		pilot_camera.rotation_degrees.y -= event.relative.x * 0.2
		pilot_camera.rotation_degrees.y = clamp(
			pilot_camera.rotation_degrees.y, 0,180
		)
		pilot_camera.rotation_degrees.x -= event.relative.y * 0.2
		pilot_camera.rotation_degrees.x = clamp(
		pilot_camera.rotation_degrees.x, -60, 75 
		)
	elif not Camerafree and event is InputEventMouseMotion:
		mouse_input += event.relative

func _physics_process(_delta):
	if not Global.is_pilot: 
		return
	
	var forward_input = Input.get_axis("throttle_down", "throttle_up")
	var yaw_input = Input
	var roll_input = Input.get_axis("move_right", "move_left")
	var pitch_input = Input.get_axis("move_back", "move_forward")
	var forward_force: Vector3 = Vector3.ZERO
	
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not Camerafree:
		pitch_input += mouse_input.y * 0.02
		yaw_input = -mouse_input.x * 0.05
	else:
		yaw_input = 0
	
	if forward_input > 0 and forward_move < 1.985:
		forward_move += 0.015
	elif forward_input < 0 and forward_move > -1:
		forward_move -= 0.015
	else:
		pass
	
	if forward_move > 0:
		%Engine_2.volume_db = forward_move * 2
	else:
		%Engine_2.volume_db = -forward_move * 2

	if forward_move > 0.1 or forward_move < -0.1:
		forward_force = forward_move * -global_transform.basis.x * engine_power
	else:
		forward_force = Vector3.ZERO
	if Global.ship_on:
		apply_central_force(forward_force)
		apply_torque(transform.basis.z * pitch_input * pitch_torque)
		apply_torque(transform.basis.y * yaw_input * pitch_torque)
		apply_torque(transform.basis.x * roll_input * roll_torque)
		
		if not %Engine_2.playing:
			%Engine_2.play()
	
	mouse_input = Vector2.ZERO
	
	throttle_label.text = "Throttle: " + str(int(ceil((forward_move * 50)))) + "%"
	
	if Global.is_pilot:
		if Input.is_action_pressed("fire"):
			request_shoot.rpc(fire_point.global_transform)
		
		if Input.is_action_just_pressed("fire"):
			%Gun1.play()
			just_shot.rpc()
		
		if Input.is_action_just_released("fire"):
			%Gun2.stop()
			%Gun3.play()

func _process(_delta: float) -> void:
	rwr_active_threats.clear()
	var potential_threats = get_tree().get_nodes_in_group("enemy_ship")
	
	for threat in potential_threats:
		if not threat is Node3D:
			continue
		
		var local_position = to_local(threat.global_position)
		distance = Vector2(local_position.x, local_position.z).length()
		var distance_2d = distance / rwr_detection_range
		
		if distance <= rwr_detection_range and distance >= 1000:
			var angle = atan2(-local_position.z, -local_position.x)
			
			rad_to_deg(angle)
			
			rwr_active_threats.append({
				"angle": angle,
				"distance": distance_2d,
				"locking": threat.get("is_locking") if "is_locking" in threat else false,
				"name": threat.get("emitter_name") if "emitter_name" in threat else "HOSTILE"
			})
	%"RWR Screen".update_threats(rwr_active_threats)
	
	# Sends distnace from enemy and speed to gun sight
	var current_speed: int = snapped(linear_velocity.length(), 0.1)
	if not is_instance_valid(ai_ship):
		ai_ship = get_tree().get_first_node_in_group("enemy_ship")
		return
	
	if is_instance_valid(ai_ship):
		%"Gun Sight".distance = distance
	
	%"Gun Sight".speed = current_speed

func _input(_event: InputEvent) -> void:
	var cantlock = Camerafree
	
	if Global.is_pilot:
		if Input.is_action_just_pressed("camera_lock") and not cantlock:
			Camerafree = true
		elif Input.is_action_just_pressed("camera_lock") and cantlock:
			Camerafree = false
			pilot_camera.rotation_degrees.x = 0
			pilot_camera.rotation_degrees.y = 90
	
	if Global.is_wo:
		if Input.is_action_just_pressed("camera_lock") and not cantlock:
			Camerafree = true
		elif Input.is_action_just_pressed("camera_lock") and cantlock:
			Camerafree = false
			wo_camera.rotation_degrees.x = 0
			wo_camera.rotation_degrees.y = 90

@rpc("any_peer", "call_local", "reliable")
func just_shot() -> void:
	pre_fire_timer.start()
	await get_tree().create_timer(0.05).timeout
	fire_time.start()
	if pre_fire_timer.is_stopped():
		%Gun2.play()

@rpc("any_peer", "call_local", "reliable")
func request_shoot(muzzle_transform:  Transform3D) -> void:
	if not multiplayer.is_server():
		return
	if fire_timer.is_stopped() and pre_fire_timer.is_stopped() and fire_time.time_left > 0:
		var bullet = bullet_scene.instantiate()
		bullet.global_transform = muzzle_transform
		%Gun2.play()
		fire_timer.start()
		bullet.rotate_object_local(Vector3.RIGHT, randf_range(-muzzle_spread, muzzle_spread))
		bullet.rotate_object_local(Vector3.UP, randf_range(-muzzle_spread, muzzle_spread))
		if bullet_container:
			bullet_container.add_child(bullet, true)

func enter_pilot():
	health_label.show()
	player = get_tree().get_first_node_in_group("Player")
	Camerafree = false
	pilot_camera.current = true
	pilot_camera.rotation_degrees = Vector3(0, 90, 0)

func leave_pilot():
	health_label.hide()
	player = get_tree().get_first_node_in_group("Player")

func enter_wo():
	health_label.show()
	player = get_tree().get_first_node_in_group("Player")
	Camerafree = false
	wo_camera.current = true
	wo_camera.rotation_degrees = Vector3(0, 90, 0)

func leave_wo():
	health_label.hide()
	player = get_tree().get_first_node_in_group("Player")

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemy_bullet"):
		hit()
		area.queue_free() 

func ship_destroyed():
	self.hide()
	set_physics_process(false)
	Global.player_ship_destroyed = true
	%Engine_2.stop()

func hit():
	health -= randi_range(1, 10)
	if health < 0:
		health = 0
	health_label.text = "Ship Health: " + str(health)
	if health <= 0:
		ship_destroyed()
	
	var bullet_sfx = randi_range(1, 4)
	if bullet_sfx == 1:
		%BulletStrike1.play()
	elif bullet_sfx == 2:
		%BulletStrike2.play()
	elif bullet_sfx == 3:
		%BulletStrike3.play()
	elif bullet_sfx == 4:
		%BulletStrike4.play()

func system_start():
	rpc("sync_system_start")

@rpc(	"any_peer", "call_local", "reliable")
func sync_system_start():
	%OmniLight3D.light_color = Color("fff1f2ff")
	%OmniLight3D2.show()
	%OmniLight3D3.show()
	%OmniLight3D4.show()
	%OmniLight3D5.show()
	%SpotLight3D.show()
	%SpotLight3D2.show()
	%Computer_Boot.play()
	await get_tree().create_timer(5).timeout
	%RadarScreen.show()
	%RadarScreenL.show()
	%RWRScreen.show()
	%Engine_1.play()
	$Avionics/GunSight.show()
	await get_tree().create_timer(6.2).timeout
	Global.ship_on = true
	if not %Engine_2.playing:
		%Engine_2.play() 

func system_shutdown():
	%OmniLight3D.light_color = Color(1.0, 0.0, 0.0, 1.0)
	%Engine_2.stop()
	%Engine_3.play()

func _on_exterior_body_exited(body: Node3D) -> void:
	pass

func _on_exterior_body_entered(body: Node3D) -> void:
	pass
