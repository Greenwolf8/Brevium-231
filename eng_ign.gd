extends Area3D

var on: bool = false

func interact():
	if !on:
		on = true
		%"Engines Systems".switch_eng_start_ign = true
	else:
		on = false
		%"Engines Systems".switch_eng_1_master = false
