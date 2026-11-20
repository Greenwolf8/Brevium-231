extends Area3D

var on: bool = false

func interact():
	if !on:
		on = true
		%"Engines Systems".switch_eng_start_ign = 1
	else:
		on = false
		%"Engines Systems".switch_eng_start_ign = 0
