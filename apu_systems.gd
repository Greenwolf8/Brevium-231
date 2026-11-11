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
		# Update control rod position only if the apu is running AND the control rod is flicked on
		if apu1_started and apu1_ctrlrods:
			update_apu1_rod_pos(delta)
		# Start APU if start switch and master switch are flicked on, and it is not on already
		if apu1_start and apu1_master and !apu1_started:
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
	if !apu1_melteddown and apu1_master and (!apu1_ctrlrods or !apu1_waterpump):
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

