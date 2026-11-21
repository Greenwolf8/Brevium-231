extends Area3D

var on: bool = false

func interact():
	if !on:
		on = true
		%"Engines Systems".switch_eng_3_master = true
	else:
		on = false
		%"Engines Systems".switch_eng_3_master = false
