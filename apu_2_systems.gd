extends Node

# Warning Indicators Mesh
@export var apu_turbinestall_label: MeshInstance3D
@export var apu_meltdown_label: MeshInstance3D
@export var apu_warn_light: OmniLight3D

# Control Rod Indicator
@export var apu_controlrods: MeshInstance3D

# Gauge Needles
@export var apu_tempgaugeneedle: MeshInstance3D
@export var apu_turbinerpmneedle: MeshInstance3D

# Materials
const BUTTON_OFF = preload("uid://c1ruib5pd5l2i")
const BUTTON_ORANGE = preload("uid://dos3fbyt150cv")

# APU 1 Status
var apu_started: bool = false
var apu_turbine_rpm: float = 0.0
var apu_core_temp: float = 23.0
var apu_rod_pos: float = 1.0
var apu_neutron_flux: float = 0.0
var apu_output: float = 0.0
var apu_pumps_on: bool = false
var apu_water_flow_rate: float = 0.0 #Kg/s
var apu_shutdown: bool = false
var apu_melteddown: bool = false

# APU Common Vars
var water_heat_capacity: float = 2256.0 #J/Kg

const APU_MELTDOWN_TEMP: float = 1841.0 # Kelvin
const APU_SPECIFIC_HEAT: float = 1600.0 # Joules per Kelvin
const APU_MAX_OUTPUT: float = 17.5
const APU_MAX_NEUTRON_FLUX: float = 25.0
const APU_OPERATING_TEMP: float = 275.0

# APU 1 Switches
var apu_master: bool = false
var apu_start: bool = false
var apu_waterpump: bool = false
var apu_ctrlrods: bool = false

# Colours
const GREEN = preload("uid://bu5jukk52fwr6")

func _process(delta: float) -> void:
	if !apu_melteddown:
		# Run all update functions to run the reactor
		update_apu_reaction()
		update_apu_heat(delta)
		update_apu_rod_pos(delta)
		# Start APU if start switch and master switch are flicked on, and it is not on already
		if apu_start and apu_master and !apu_started and !apu_shutdown:
			start_apu(delta)
		# If heat ever gets too high, cause meltdown
		if apu_core_temp > 1000.0:
			cause_apu_meltdown()
		# clamp the water flow rate and control rod position to make sure they dont go negative
		apu_water_flow_rate = clamp(apu_water_flow_rate, 0.0, 100.0)
		apu_rod_pos = clamp(apu_rod_pos, 0.0, 1.0)
	# Pass the output of the APU back to the "Electrical Systems" script
	if apu_output > 0.0:
		%"Electrical Systems".apu_2_output = apu_output
	if (apu_start or apu_started) and apu_turbine_rpm <= 1000:
		apu_turbinestall_label.set_surface_override_material(0, BUTTON_ORANGE)
	else:
		apu_turbinestall_label.set_surface_override_material(0, BUTTON_OFF)
	# If the master switch is on, but either one of the control rods or water pump switches are off, then the warning light turns on
	if !apu_melteddown and !apu_shutdown and apu_master and (!apu_ctrlrods or !apu_waterpump):
		apu_warn_light.light_energy = 0.1
	else:
		apu_warn_light.light_energy = 0.0
	# If control rods switch is on, the indicators turn on
	if apu_ctrlrods:
		apu_controlrods.set_surface_override_material(1, GREEN)
	else:
		apu_controlrods.set_surface_override_material(1, null)

func start_apu(delta: float):
	if apu_ctrlrods and apu_rod_pos >= 0.7 and !apu_started:
		apu_rod_pos -= 0.01 * delta
	elif apu_rod_pos <= 0.71 and !apu_started and apu_core_temp > 75:
		apu_started = true

func update_apu_reaction():
	if apu_rod_pos > 0.99:
		apu_neutron_flux = 0.0
		return
	
	var reactivity = 1.0 - apu_rod_pos
	apu_neutron_flux = APU_MAX_NEUTRON_FLUX * reactivity

func update_apu_heat(delta: float):
	# Water pump
	var target_flow_rate = 0.0
	if apu_core_temp <= 400:
		target_flow_rate = clamp(remap(apu_core_temp, 100.0, 400.0, 1.5, 14.0), 0.0, 100.0)
	else:
		target_flow_rate = 25.0
	
	if apu_waterpump:
		if apu_water_flow_rate < target_flow_rate - 0.2: 
			apu_water_flow_rate += 0.2 * delta
		elif apu_water_flow_rate > target_flow_rate + 0.2:
			apu_water_flow_rate -= 0.2 * delta 
	else:
		apu_water_flow_rate -= 0.3 * delta
	
	if apu_shutdown:
		if apu_water_flow_rate <= 25:
			apu_water_flow_rate += 5.0 * delta
	elif !apu_master:
		if apu_water_flow_rate <= 3:
			apu_water_flow_rate += 0.3 * delta
	
	var water_effectiveness = 1.0
	if apu_core_temp <= 30.0:
		# Water becoms more effective above 30 degrees, where 15 is the lowest it can cool the reactor
		water_effectiveness = clamp(remap(apu_core_temp, 15.0, 30.0, 0.0, 1.0), 0.0, 1.0)
	elif apu_core_temp >= 400.0: 
		# Above 300 degrees, effectiveness drops dramatically to increase chance of accidental meltdown
		water_effectiveness = clamp(remap(apu_core_temp, 400.0, 550.0, 1.0, 0.2), 0.2, 1.0)
	
	var fuel_heat_effectiveness: float = remap(apu_core_temp, 0.0, 1000.0, 500.0, 2000.0)
	
	# Heat Gained From Fission
	var heat_generated = apu_neutron_flux * fuel_heat_effectiveness * delta
	# Heat Removed By Water
	var heat_removed = apu_water_flow_rate * water_heat_capacity * water_effectiveness * delta
	# Total Heat Gain/Loss
	var total_heat_energy = heat_generated - heat_removed
	
	var core_temp_change = total_heat_energy / APU_SPECIFIC_HEAT
	apu_core_temp += core_temp_change
	
	# Calculate the electrical output of apu
	var turbine_target_rpm = apu_water_flow_rate * heat_removed * 0.75
	if apu_core_temp >= 150.0:
		if apu_turbine_rpm < turbine_target_rpm:
			apu_turbine_rpm += (turbine_target_rpm - apu_turbine_rpm) * delta * 0.05
	if apu_turbine_rpm > turbine_target_rpm: 
		apu_turbine_rpm += (turbine_target_rpm - apu_turbine_rpm) * delta * 0.05
	
	if turbine_target_rpm <= 0.0 and apu_turbine_rpm > 0.0:
		apu_turbine_rpm -= 750.0 * delta
	
	apu_output = apu_turbine_rpm * (APU_MAX_OUTPUT / 2500.0)
	
	# Rotate the gauge needles
	apu_tempgaugeneedle.rotation.y = deg_to_rad(remap(apu_core_temp,0.0, 400.0, 1.5, -260.0))
	apu_turbinerpmneedle.rotation.y = deg_to_rad(remap(apu_turbine_rpm,0.0, 5000.0, 0.0, -327.0))

func update_apu_rod_pos(delta: float):
	# If the apu_shutdown button was pressed, slam control rods fully in
	if apu_shutdown:
		if apu_rod_pos < 0.9:
			apu_rod_pos += 0.5 * delta
			return
		else:
			pass
	# If master switch isn't  on, slowly put rods back all the way in
	if !apu_master:
		if apu_rod_pos < 0.9:
			apu_rod_pos += 0.1 * delta
			return
		else:
			pass
	if !apu_ctrlrods and !apu_started:
		return
	
	# Find heat difference 
	var heat_difference = APU_OPERATING_TEMP - apu_core_temp
	
	var speed_effectiveness = 1.0
	if apu_core_temp >= 300:
		clamp(remap(apu_core_temp, 300.0, 400.0, 1.0, 0.1), 0.1, 1.0)
	else:
		speed_effectiveness = 1.0
	
	# Move rods in/out based on the heat difference
	if heat_difference < 19.0 and heat_difference > -19.0:
		pass
	elif heat_difference >= 20.0:
		apu_rod_pos -= 0.03 * speed_effectiveness * delta
	elif heat_difference <= -50.0:
		apu_rod_pos += 0.01 * speed_effectiveness * delta 

func cause_apu_meltdown():
	apu_melteddown = true
	apu_meltdown_label.set_surface_override_material(0, BUTTON_ORANGE)
	apu_warn_light.light_energy = 0.1
	apu_started = false

func apu_emerg_stop():
	apu_started = false
	apu_shutdown = true
	
	%"APU 2 MASTER Switch".turn_off()
	%"APU 2 START Switch".turn_off()
	%"APU 2 WTR PUMP Switch".turn_off()
	%"APU 2 CTRL RODS Switch".turn_off()
