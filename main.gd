extends Node3D

@export var spawn_point: Marker3D

@onready var player_ship: Node3D = %"Astro Vulcan"
@onready var world_container: Node3D = %"world container"

var players: Array[CharacterBody3D]

const PLAYER = preload("uid://cqdww5lg0i5lm")

func _ready() -> void:
	Networking.host_created.connect(on_host_created)
	set_process(false)

func on_host_created():
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)

func spawn_player(peer_id: int):
	var new_player = PLAYER.instantiate() as CharacterBody3D
	new_player.name = str(peer_id)
	world_container.add_child(new_player)
	initialize_player(new_player)

func initialize_player(player: CharacterBody3D):
	player.position = spawn_point.position
	
	for other in players:
		player.add_collision_exception_with(other)
	players.append(player)

func _on_host_button_pressed() -> void:
	$UI.hide()
	Networking.host_lobby()
	set_process(true)

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node is CharacterBody3D:
		initialize_player(node)

func _process(_delta: float) -> void:
	
	var ship_local_pos: Vector3 = world_container.position - player_ship.position
	var dist_to_ship: float = abs(ship_local_pos.x + ship_local_pos.y + ship_local_pos.z)
	
	if dist_to_ship >= 1000:
		world_container.position -= ship_local_pos
