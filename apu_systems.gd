extends Node

# Warning Indicators Mesh
@export var apu1_turbinestall_label: MeshInstance3D
@export var apu1_meltdown_label: MeshInstance3D
@export var apu1_warn_light: OmniLight3D
@export var apu2_turbinestall_label: MeshInstance3D
@export var apu2_meltdown_label: MeshInstance3D
@export var apu2_warninglight_label: MeshInstance3D

# Control Rod Indicators
@export var apu1_controlrods: MeshInstance3D
@export var apu2_controlrods: MeshInstance3D

# Gauge Needles
@export var apu1_tempgaugeneedle: MeshInstance3D
@export var apu1_turbinerpmneedle: MeshInstance3D
@export var apu2_tempgaugeneedle: MeshInstance3D
@export var apu2_turbinerpmneedle: MeshInstance3D

# Materials
const BUTTON_OFF = preload("uid://c1ruib5pd5l2i")
const BUTTON_ORANGE = preload("uid://dos3fbyt150cv")

# APU 1 Status
var apu1_started: bool = false
var apu1_turbine_rpm: float = 0.0
var apu1_core_temp: float = 23.0
var apu1_rod_pos: float = 1.0
var apu1_neutron_flux: float = 0.0
var apu1_output: float = 0.0
var apu1_pumps_on: bool = false
var apu1_water_flow_rate: float = 0.0 #Kg/s

var apu1_melteddown: bool = false

# APU 2 Status
var apu2_running: bool = false

# APU Common Vars
var water_heat_capacity: float = 2256.0 #J/Kg

const APU_MELTDOWN_TEMP: float = 1841.0 # Kelvin
const APU_SPECIFIC_HEAT: float = 1600.0 # Joules per Kelvin
const APU_MAX_OUTPUT: float = 20.0
const APU_MAX_NEUTRON_FLUX: float = 25.0
const APU_OPERATING_TEMP: float = 275.0

# APU 1 Switches
var apu1_master: bool = false
var apu1_start: bool = false
var apu1_waterpump: bool = false
var apu1_ctrlrods: bool = false

# APU 2 Switches
var apu2_master: bool = false
var apu2_start: bool = false
var apu2_waterpump: bool = false
var apu2_ctrlrods: bool = false

# Colours
const GREEN = preload("uid://bu5jukk52fwr6")

func _process(delta: float) -> void:
	if !apu1_melteddown:
		# Run all update functions to run the reactor
		update_apu1_reaction()
		update_apu1_heat(delta)
		update_apu1_rod_pos(delta)
		# Start APU if start switch and master switch are flicked on, and it is not on already
		if apu1_start and apu1_master and !apu1_started and !apu1_shutdown:
			start_apu1(delta)
		# If heat ever gets too high, cause meltdown
		if apu1_core_temp > 1000.0:
			cause_apu1_meltdown()
		# clamp the water flow rate and control rod position to make sure they dont go negative
		apu1_water_flow_rate = clamp(apu1_water_flow_rate, 0.0, 100.0)
		apu1_rod_pos = clamp(apu1_rod_pos, 0.0, 1.0)
		
		print("RPM: ", round(apu1_turbine_rpm), " Control Rods: ", snapped(apu1_rod_pos, 0.01), " Neutron FLux: ", snapped(apu1_neutron_flux, 0.1), " Temp: ", snapped(apu1_core_temp, 0.1), " Water Flow Rate: ", snapped(apu1_water_flow_rate, 0.01))
	
	# Pass the output of the APU back to the "Electrical Systems" script
	if apu1_output > 0.0:
		%"Electrical Systems".apu_1_output = apu1_output
	
	# If the master switch is on, but either one of the control rods or water pump switches are off, then the warning light turns on
	if !apu1_melteddown and !apu1_shutdown and apu1_master and (!apu1_ctrlrods or !apu1_waterpump):
		apu1_warn_light.light_energy = 0.1
	else:
		apu1_warn_light.light_energy = 0.0
	
	# If control rods switch is on, the indicators turn on
	if apu1_ctrlrods:
		apu1_controlrods.set_surface_override_material(1, GREEN)
	else:
		apu1_controlrods.set_surface_override_material(1, null)

func start_apu1(delta: float):
	if apu1_ctrlrods and apu1_rod_pos >= 0.7 and !apu1_started:
		apu1_rod_pos -= 0.01 * delta
	elif apu1_rod_pos <= 0.71 and !apu1_started and apu1_core_temp > 75:
		apu1_started = true

func update_apu1_reaction():
	if apu1_rod_pos > 0.99:
		apu1_neutron_flux = 0.0
		return
	
	var reactivity = 1.0 - apu1_rod_pos
	apu1_neutron_flux = APU_MAX_NEUTRON_FLUX * reactivity

func update_apu1_heat(delta: float):
	# Water pump
	var target_flow_rate = 0.0
	if apu1_core_temp <= 400:
		target_flow_rate = clamp(remap(apu1_core_temp, 100.0, 400.0, 1.5, 14.0), 0.0, 100.0)
	else:
		target_flow_rate = 25.0
	
	if apu1_waterpump:
		if apu1_water_flow_rate < target_flow_rate - 0.2: 
			apu1_water_flow_rate += 2.0 * delta
		elif apu1_water_flow_rate > target_flow_rate + 0.2:
			apu1_water_flow_rate -= 2.0 * delta 
	else:
		apu1_water_flow_rate -= 0.3 * delta
	
	if apu1_shutdown:
		if apu1_water_flow_rate <= 25:
			apu1_water_flow_rate += 5.0 * delta
	
	var water_effectiveness = 1.0
	if apu1_core_temp <= 30.0:
		# Water becoms more effective above 30 degrees, where 15 is the lowest it can cool the reactor
		water_effectiveness = clamp(remap(apu1_core_temp, 15.0, 30.0, 0.0, 1.0), 0.0, 1.0)
	elif apu1_core_temp >= 400.0: 
		# Above 300 degrees, effectiveness drops dramatically to increase chance of accidental meltdown
		water_effectiveness = clamp(remap(apu1_core_temp, 400.0, 550.0, 1.0, 0.2), 0.2, 1.0)
	
	var fuel_heat_effectiveness: float = remap(apu1_core_temp, 0.0, 1000.0, 500.0, 2000.0)
	
	# Heat Gained From Fission
	var heat_generated = apu1_neutron_flux * fuel_heat_effectiveness * delta
	# Heat Removed By Water
	var heat_removed = apu1_water_flow_rate * water_heat_capacity * water_effectiveness * delta
	# Total Heat Gain/Loss
	var total_heat_energy = heat_generated - heat_removed
	
	var core_temp_change = total_heat_energy / APU_SPECIFIC_HEAT
	apu1_core_temp += core_temp_change
	
	# Calculate the electrical output of apu
	var turbine_target_rpm = apu1_water_flow_rate * heat_removed * 0.75
	if apu1_core_temp >= 225.0:
		if apu1_turbine_rpm < turbine_target_rpm:
			apu1_turbine_rpm += (turbine_target_rpm - apu1_turbine_rpm) * delta * 0.05
	if apu1_turbine_rpm > turbine_target_rpm: 
		apu1_turbine_rpm += (turbine_target_rpm - apu1_turbine_rpm) * delta * 0.05
	
	apu1_output = apu1_turbine_rpm * (APU_MAX_OUTPUT / 25000)
	
	# Rotate the gauge needles
	apu1_tempgaugeneedle.rotation.y = deg_to_rad(remap(apu1_core_temp,0.0, 400.0, 1.5, -260.0))
	apu1_turbinerpmneedle.rotation.y = deg_to_rad(remap(apu1_turbine_rpm,0.0, 5000.0, 0.0, -327.0))

func update_apu1_rod_pos(delta: float):
	if apu1_shutdown:
		if apu1_rod_pos < 0.999:
			apu1_rod_pos += 0.5 * delta
			return
		else:
			pass
	if !apu1_ctrlrods and !apu1_started:
		return
	# Find heat difference 
	var heat_difference = APU_OPERATING_TEMP - apu1_core_temp
	
	var speed_effectiveness = 1.0
	if apu1_core_temp >= 300:
		clamp(remap(apu1_core_temp, 300.0, 400.0, 1.0, 0.1), 0.1, 1.0)
	else:
		speed_effectiveness = 1.0
	
	# Move rods in/out based on the heat difference
	if heat_difference < 19.0 and heat_difference > -19.0:
		pass
	elif heat_difference >= 20.0:
		apu1_rod_pos -= 0.03 * speed_effectiveness * delta
	elif heat_difference <= -50.0:
		apu1_rod_pos += 0.01 * speed_effectiveness * delta 

func cause_apu1_meltdown():
	apu1_melteddown = true
	apu1_meltdown_label.set_surface_override_material(0, BUTTON_ORANGE)
	apu1_warn_light.light_energy = 0.1
	apu1_started = false

func apu1_emerg_stop():
	apu1_started = false
	apu1_shutdown = true
	
	%"APU 1 MASTER Switch".turn_off()
	%"APU 1 START Switch".turn_off()
	%"APU 1 WTR PUMP Switch".turn_off()
	%"APU 1 CTRL RODS Switch".turn_off()
