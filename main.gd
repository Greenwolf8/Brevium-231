extends Node3D

const PLAYER = preload("uid://cqdww5lg0i5lm")

var players: Array[CharacterBody3D]
@export var spawn_point: Marker3D

func _ready() -> void:
	Networking.host_created.connect(on_host_created)
	

func on_host_created():
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)

func spawn_player(peer_id: int):
	var new_player = PLAYER.instantiate() as CharacterBody3D
	new_player.name = str(peer_id)
	add_child(new_player)
	initialize_player(new_player)

func initialize_player(player: CharacterBody3D):
	player.position = spawn_point.position
	
	for other in players:
		player.add_collision_exception_with(other)
	players.append(player)


func _on_host_button_pressed() -> void:
	$UI.hide()
	Networking.host_lobby()


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node is CharacterBody3D:
		initialize_player(node)
