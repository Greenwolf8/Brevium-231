extends Node3D

func call_ship():
	if Global.hangar_open == false:
		%AnimationPlayer2.play("Global/ElevatorAction_2")
		%Exterior.show()
		%ElevatorCollision.disabled = false
		await get_tree().create_timer(41.6667).timeout
		%Exterior.hide()
		Global.hangar_open = true
		%ElevatorCollision.disabled = true

	elif Global.hangar_open == true:
		%Extorior.show()
		%AnimationPlayer2.play_backwards("Global/ElevatorAction_2")
		Global.hangar_open = false
		%ElevatorCollision.disabled = false
		await get_tree().create_timer(41.6667).timeout
		%ElevatorCollision.disabled = true

func open_hangar():
	%AnimationPlayer.play("ArmatureAction")
