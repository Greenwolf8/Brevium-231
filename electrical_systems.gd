extends Node

#Battery switches
var switch_batt1: bool = false
var switch_ess_batt: bool = false
var switch_batt2: bool = false
var switch_apu_bat: bool = false

#Generators switch
var switch_gen1: bool = false
var switch_gen2: bool = false
var switch_gen3: bool = false

#Reactor turbine RPM for generators
var reactor_1_rpm: float = 0.0
var reactor_2_rpm: float = 0.0
var engine_3_rpm: float = 0.0
var max_reactor_output: float = 75.0
var max_engine_output: float = 40.0

#APU generators
var apu_1_output: float = 0.0
var apu_2_output: float = 0.0

#Batteries
var batt_max_charge: float = 100.0
var batt_1_current_charge: float = 75.0
var batt_2_current_charge: float = 75.0
var batt_ess_current_charge: float = 95.0
var batt_apu_current_charge: float = 90.0
var batt_drain_rate: float = 0.0004
var batt_charge_rate: float = 0.001

#Electricity
var power_demand: float = 0.0
var power_generation: float = 0.0

#Electronics busses 
var bus_ac_ess: bool = false
var bus_ac_1: bool = false
var bus_ac_2: bool = false

func _process(_delta: float) -> void:
	calculate_power_generation()
	give_output()

func calculate_power_generation():
	#calculate the power being generated
	var reactor_1_output: float = (reactor_1_rpm / 100) * max_reactor_output if reactor_1_rpm > 45.0 else 0.0
	var reactor_2_output: float = (reactor_2_rpm / 100) * max_reactor_output if reactor_2_rpm > 45.0 else 0.0
	var generator_3_output: float = (engine_3_rpm / 100) * max_engine_output if engine_3_rpm > 55.0 else 0.0
	var total_availible_power: float = apu_1_output + apu_2_output + reactor_1_output + reactor_2_output + generator_3_output
	
	#Calculate the total power draw
	power_demand = calculate_power_draw()
	
	#See if generators cover the demand
	var generators_online = power_demand <= total_availible_power
	
	var left_over_power = clamp(total_availible_power - power_demand, 0, 100000)
	
	if generators_online:
		#All busses are good when gens are on
		bus_ac_ess = true
		bus_ac_1 = true
		bus_ac_2 = true
		
		#Charge batteries when extra power is availible
		if batt_1_current_charge < 100.0:
			batt_1_current_charge += batt_charge_rate * left_over_power
		if batt_ess_current_charge < 100.0:
			batt_ess_current_charge += batt_charge_rate * left_over_power
		if batt_2_current_charge > 100.0:
			batt_2_current_charge += batt_charge_rate * left_over_power
		if batt_apu_current_charge > 100.0:
			batt_apu_current_charge += batt_charge_rate * left_over_power
	
	else:
		if switch_batt1 == true and batt_1_current_charge > 5.0:
			#AC1 is on when batt 1 has charge, and opposite for AC2
			bus_ac_1 = true
			bus_ac_2 = false
			
			batt_1_current_charge -= power_demand * batt_drain_rate #Drain power from battery based on how much is being used
		elif switch_batt2 == true and batt_2_current_charge > 5.0:
			#AC2 is on when batt 2 has charge, and opposite for AC1
			bus_ac_2 = true
			bus_ac_1 = false
			batt_2_current_charge -= power_demand * batt_drain_rate #Drain power from battery based on how much is being used
		else:
			#If neither battery has power, it all goes dead
			bus_ac_1 = false
			bus_ac_2 = false
		
		if switch_ess_batt == true and batt_ess_current_charge > 2.5:
			bus_ac_ess = true #If the ESS battery has charge, ESS bus is on
			batt_ess_current_charge -= 10.0 * batt_drain_rate #Drain power from battery
		else:
			bus_ac_ess = false #ESS bus goes dead when battery does

func calculate_power_draw():
	var demand = 10.0 #This 10.0 is the baseline needed for instruments, etc
	
	if $"..".radar_engaged == true:
		demand += 45.0
	if $"..".rwr_engaged == true:
		demand += 10.0
	if $"..".r_gun_firing == true:
		demand += 5.0
	if $"..".l_gun_firing == true:
		demand += 5.0
	if $"..".targeting_pod_engaged == true:
		demand += 25
	if $"..".radio_in_use == true:
		demand += 10
	if $"..".lights_on > 0:
		demand += $"..".lights_on * 0.5
	if $"..".hydraulics_usage > 0.0:
		demand += $"..".hydraulics_usage * 0.5
	
	return(demand)

func give_output():
	if bus_ac_1 or bus_ac_2:
		%"APU 1 MASTER Switch".powered = true
		%"APU 1 START Switch".powered = true
		%"APU 1 WTR PUMP Switch".powered = true
		%"APU 1 CTRL RODS Switch".powered = true
	else:
		%"APU 1 MASTER Switch".powered = false
		%"APU 1 START Switch".powered = false
		%"APU 1 WTR PUMP Switch".powered = false
		%"APU 1 CTRL RODS Switch".powered = false
	
	if bus_ac_1 or bus_ac_2 or bus_ac_ess:
		pass
	else:
		pass
