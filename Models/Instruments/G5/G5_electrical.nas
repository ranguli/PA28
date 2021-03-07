##
# G5 Electrical system model.
# The Garmin G5 is equipped with an internal battery, which is loaded when powered by the aircraft's electrical system and can supply the instrument in case of a power outage.
# Source: https://www.siebert.aero/media/products/Installations-Handbuch_G5_non_cert.pdf

var g5_electrical_loop = nil;
var last_time = nil;

var vbus_volts = 0.0;

# Properties

var property_base	= props.globals.getNode("/instrumentation/G5", 1);
var electrical_base	= property_base.initNode("electrical");
var start		= property_base.initNode("start", 0, "BOOL");				#	0 : switched off; 0-1 : starting up; 1: running
var bus_volts		= props.globals.getNode("/systems/electrical/outputs/G5", 1); 		#	Current supplied by the aircraft's avionics bus
var ins_volts		= electrical_base.initNode("instrument-volts", 0.0, "DOUBLE");		#	voltage fed to the instrument
var charge		= electrical_base.initNode("battery-charge-percent", 1.0, "DOUBLE");	#	internal battery charge
var load		= electrical_base.initNode("load", 0.0, "DOUBLE");			#	internal battery load
var bus_load		= electrical_base.initNode("bus-load", 0.0, "DOUBLE");			#	Load on the avionics bus (from this instrument)
var ffb			= electrical_base.initNode("feed-from-battery", 0, "BOOL");		#	0: fed from avionics bus 1: fed from internal battery (for instrument indication)
var bc			= electrical_base.initNode("battery-charging", 0, "BOOL");		#	0: not charging 1: charging
var option		= props.globals.getNode("/options/attitude-indicator", 1);

var replay_state	= props.globals.getNode("/sim/freeze/replay-state",	1);

##
# Battery model class.
# Adapted from C172p electrical systen
#

var BatteryClass = {
		new : func {
			var obj = { 
				parents : [BatteryClass],
				ideal_volts : 12.0,
				ideal_amps : 0.2,
				amp_hours : 0.8,
				charge_percent : 1.0,
				charge_amps : 0.56,
				};
			charge.setValue(obj.charge_percent);
			return obj;
		},
		apply_load : func (amps, dt) {
			load.setValue(amps);
			
			var old_charge_percent = charge.getValue();

			if ( replay_state.getBoolValue() )
				return me.amp_hours * old_charge_percent;

			var amphrs_used = amps * dt / 3600.0;
			var percent_used = amphrs_used / me.amp_hours;

			var new_charge_percent = std.max(0.0, std.min(old_charge_percent - percent_used, 1.0));
			
			me.charge_percent = new_charge_percent;
			charge.setValue(new_charge_percent);
			return me.amp_hours * new_charge_percent;
		},
		get_output_volts : func {
			var x = 1.0 - me.charge_percent;
			var tmp = -(3.0 * x - 1.0);
			var factor = (math.pow(tmp, 5) + 32) / 32;
			return me.ideal_volts * factor;
		},
		get_output_amps : func {
			var x = 1.0 - me.charge_percent;
			var tmp = -(3.0 * x - 1.0);
			var factor = (math.pow(tmp, 5) + 32) / 32;
			return me.ideal_amps * factor;
		},
		reset_to_full_charge : func {
			me.apply_load(-(1.0 - me.charge_percent) * me.amp_hours, 3600);
		},
	};

var internal_battery = BatteryClass.new();


var update_electrical = func () {
	var time = elapsed_sec.getDoubleValue();
	var dt = time - last_time;
	last_time = time;
    
	var start_v = start.getValue();
	var bus_volts_v = bus_volts.getValue();
	var battery_volts = internal_battery.get_output_volts();
	var charge_v = charge.getValue();
	
	var instrument_consumption = 0.0;
	if( start_v != 0 and option.getValue() == "Garmin G5" ){
		instrument_consumption = 2.1 + rand() * 0.7;				# average is 2.8W, maximal 3.5W
	}
	
	if( bus_volts_v > battery_volts ){						# The instrument electrical system is fed from the avionics bus
		if ( charge_v < 1.0 ){
			internal_battery.apply_load(-internal_battery.charge_amps, dt);
			bc.setValue(1);
			bus_load.setValue(internal_battery.charge_amps*bus_volts_v + instrument_consumption);
		}else{
			bus_load.setValue(instrument_consumption);
			bc.setValue(0);
		}
		ins_volts.setValue(bus_volts_v);
		ffb.setValue(0);
	} else {									# The instrument electrical system is fed from its internal battery
		ins_volts.setValue(battery_volts);
		ffb.setValue(1);
		bc.setValue(0);
		if ( battery_volts > 0 ){
			internal_battery.apply_load(instrument_consumption/battery_volts, dt);
		}
	}
}


var elec_ls = setlistener("/sim/signals/fdm-initialized", func {
	internal_battery.reset_to_full_charge();
	last_time = elapsed_sec.getDoubleValue();
	g5_electrical_loop = maketimer(0.2, update_electrical);
	g5_electrical_loop.simulatedTime = 1; 
	g5_electrical_loop.start();
	removelistener( elec_ls );
});
