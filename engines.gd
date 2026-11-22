extends Node

# Engine Switches
var switch_eng_start_ign: int = 0
var switch_eng_1_master: bool = false
var switch_eng_2_master: bool = false
var switch_eng_3_master: bool = false

# Engines currently on
var eng_1_running: bool = false
var eng_2_running: bool = false
var eng_3_running: bool = false

# Variables for the ship to use
var eng_1_thrust: float = 0.0
var eng_2_thrust: float = 0.0
var eng_3_thrust: float = 0.0

# fuel flow rates in KG/s
var eng_1_fuel_flow_rate: float = 0.0
var eng_2_fuel_flow_rate: float = 0.0
var eng_3_fuel_flow_rate: float = 0.0

# Common vars
var fuel_energy_density: float = 100000000000000 # J/Kg
var fission_efficiency: float = 0.00371
var energy_conversion_efficiency: float = 0.5
var nozzle_efficiency: float = 0.9999999

# Ship reference
@onready var ship: RigidBody3D = $".."

func _process(delta: float) -> void:
	if eng_1_running:
		eng_1_fuel_flow_rate = calc_fuel_flow(delta, eng_1_fuel_flow_rate, 88.88)
		# If engine 1 is running and the player turns off engine 1, it kills it
		if !switch_eng_1_master:
			kill_eng(1)
			pass
		elif eng_1_fuel_flow_rate >= 0.0:
				eng_1_thrust = calc_engine_thrust(eng_1_fuel_flow_rate)
	else: 
		# If both the engine 1 switch and the start switch are on, it starts engine 1
		if switch_eng_1_master and switch_eng_start_ign == 1:
			start_eng(1)
		
	if eng_2_running:
		eng_2_fuel_flow_rate = calc_fuel_flow(delta, eng_2_fuel_flow_rate, 88.88)
		# If engine 2 is running and the player turns off engine 2, it kills it
		if !switch_eng_2_master:
			kill_eng(2)
			pass
		elif eng_2_fuel_flow_rate >= 0.0:
			eng_2_thrust = calc_engine_thrust(eng_2_fuel_flow_rate)
	else: 
		# If both the engine 2 switch and the start switch are on, it starts engine 2
		if switch_eng_2_master and switch_eng_start_ign == 1:
			start_eng(2)
		
	if eng_3_running:
		eng_3_fuel_flow_rate = calc_fuel_flow(delta, eng_3_fuel_flow_rate, 44.44)
		# If engine 3 is running and the player turns off engine 3, it kills it
		if !switch_eng_3_master:
			kill_eng(3)
			pass
		elif eng_1_fuel_flow_rate >= 0.0:
			eng_3_thrust = calc_engine_thrust(eng_3_fuel_flow_rate)
	else: 
		# If both the engine 3 switch and the start switch are on, it starts engine 3
		if switch_eng_3_master and switch_eng_start_ign == 1:
			start_eng(3)
	
	# Pass on the thrust of each engine, multiply by 1000 to convert from Kilonewtons to Newtons
	ship.eng_1_thrust = eng_1_thrust
	ship.eng_2_thrust = eng_2_thrust
	ship.eng_3_thrust = eng_3_thrust

func start_eng(engine: int):
	
	match engine:
		1:
			eng_1_running = true
		
		2:
			eng_2_running = true
		
		3: 
			eng_3_running = true

func kill_eng(engine: int):
	
	match engine:
		1:
			eng_1_running = false
		
		2:
			eng_2_running = false
		
		3: 
			eng_3_running = false

func calc_engine_thrust(flow_rate: float):
	var thrust: float = 0.0
	# First, find the fuel flow rate, and exhaust flow rate
	var exhaust_flow_rate: float = flow_rate * fission_efficiency
	# Then find the available reactor power
	var reactor_power_output: float = flow_rate * fission_efficiency * fuel_energy_density * energy_conversion_efficiency * nozzle_efficiency
	# Get the exhaust velocity
	var exhaust_velocity: float = sqrt((2 * reactor_power_output) / exhaust_flow_rate)
	# Finally, calc thrust based on the exhaust velocity * mass flow rate
	thrust = exhaust_velocity * exhaust_flow_rate
	return(thrust)

func calc_fuel_flow(delta: float, current_flow_rate: float, max_fuel_flow: float):
	var target_flow_rate = remap(ship.throttle, 0, 100, max_fuel_flow / 5, max_fuel_flow)
	var new_flow_rate: float = current_flow_rate
	
	if current_flow_rate >= target_flow_rate:
		new_flow_rate -= (max_fuel_flow / 4) * delta
	elif current_flow_rate <= target_flow_rate:
		new_flow_rate += (max_fuel_flow / 4) * delta
	
	return(new_flow_rate)
