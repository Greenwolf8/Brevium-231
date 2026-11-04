extends Node

# Engine Switches
var switch_eng_start: int = 0
var switch_eng_1_on: bool = false
var switch_eng_2_on: bool = false
var switch_eng_3_on: bool = false

# Engine power
var engine_1_max_thrust: float = 3070 # Needs to be * 1000
var engine_2_max_thrust: float = 3070 # Needs to be * 1000
var engine_3_max_thrust: float = 1510 # Needs to be * 1000

# Engines currently on
var eng_1_running: bool = false
var eng_2_running: bool = false
var eng_3_running: bool = false

# Variables for the ship to use
var eng_1_thrust: float = 0.0
var eng_2_thrust: float = 0.0
var eng_3_thrust: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	# Check if the engine starter is set to engine start, or norm
	if event.is_action_pressed("1"):
		if switch_eng_start == 0: # If switch is set to normal, it sets it to start
			switch_eng_start = 1
		elif switch_eng_start == 1: # If switch is set to start, set to normal
			switch_eng_start = 0
	# Check if each engine switch is set to on or off
	elif event.is_action_pressed("2"):
		if switch_eng_1_on == false: # If engine 1 switch is set in the off postion, flick it on
			switch_eng_1_on = true
		elif switch_eng_1_on == true: # If engine 1 switch is set in the on postion, flick it off
			switch_eng_1_on = false

func _process(delta: float) -> void:
	print("Thrust: ", eng_1_thrust, ", Throttle: ", get_parent().throttle)
	if eng_1_running:
		# If engine 1 is running and the player turns off engine 1, it kills it
		if !switch_eng_1_on:
			kill_eng_1()
			pass
		else:
			eng_1_thrust = clamp(engine_1_max_thrust * (get_parent().throttle / 100), engine_1_max_thrust * 0, engine_1_max_thrust)
	else: 
		# If both the engine 1 switch and the start switch are on, it starts engine 1
		if switch_eng_1_on and switch_eng_start == 1:
			start_eng_1()

func start_eng_1():
	eng_1_running = true
	print("Starting engine 1")

func kill_eng_1():
	eng_1_running = false
	print("killing engine 1")
