# Garmin G5 by D-ECHO based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)
#######################################

var G5_only = nil;
var G5_start = nil;
var G5_display = nil;
var page = "only";

var base = "/instrumentation/G5/";
var base_path = "Aircraft/PA28/Models/Instruments/G5/";

var start_prop = base~"start";
var volts = props.globals.getNode("/instrumentation/G5/electrical/instrument-volts", 1);

# Used properties
var alt_qnh	=	props.globals.getNode("/instrumentation/altimeter/setting-inhg",			1);
var alt_ft	=	props.globals.getNode("/instrumentation/altimeter/indicated-altitude-ft",		1);
var hdg		=	props.globals.getNode("/orientation/heading-deg",					1);
var slipskid	=	props.globals.getNode("/instrumentation/slip-skid-ball/indicated-slip-skid",		1);
var gr_speed	=	props.globals.getNode("/velocities/groundspeed-kt",					1);
var ai_roll	=	props.globals.getNode("/orientation/roll-deg",						1);
var ai_pitch	=	props.globals.getNode("/orientation/pitch-deg",						1);
var ar_speed	=	props.globals.getNode("/instrumentation/airspeed-indicator/indicated-speed-kt-actual",	1);
var ap_alt	=	props.globals.getNode("/it-stec55x/input/alt",						1);
var ap_vs	=	props.globals.getNode("/it-stec55x/input/vs",						1);
var ap_out	=	props.globals.getNode("/instrumentation/G5/ap_out",					1);
var ap_on	=	ap_out.getNode("ap",									1);
var ap_vert	=	ap_out.getNode("vert",									1);
var ap_lat	=	ap_out.getNode("lat",									1);
var bat_f	=	props.globals.getNode("/instrumentation/G5/electrical/feed-from-battery",		1);
var bat_c	=	props.globals.getNode("/instrumentation/G5/electrical/battery-charge-percent",		1);
var bat_s	=	props.globals.getNode("/instrumentation/G5/electrical/always-show-battery-status",	1);
var bat_l	=	props.globals.initNode("/instrumentation/G5/electrical/load-average",	0.0, "DOUBLE"	);
var bat_ch	=	props.globals.getNode("/instrumentation/G5/electrical/battery-charging",		1);
var device_av	=	props.globals.getNode("options/attitude-indicator",					1);

var roundToNearest = func(n, m) {
	var x = int(n/m)*m;
	if((math.mod(n,m)) > (m/2) and n > 0)
			x = x + m;
	if((m - (math.mod(n,m))) > (m/2) and n < 0)
			x = x - m;
	return x;
}

var heading_norm_s = func ( hdg ) {
	var r = math.periodic(0,360,hdg);
	if( r < 10 ) {
		r = 360;
	}
	return r;
}

var canvas_G5_base = {
	init: func(canvas_group, file, init_horizon) {
		var font_mapper = func(family, weight) {
			return "LiberationFonts/LiberationSans-Bold.ttf";
		};

		
		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		var svg_keys = me.getKeys();
		 
		foreach(var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var svg_keys = me.getKeys();
			foreach (var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var clip_el = canvas_group.getElementById(key ~ "_clip");
			if (clip_el != nil) {
				clip_el.setVisible(0);
				var tran_rect = clip_el.getTransformedBounds();
				var clip_rect = sprintf("rect(%d,%d, %d,%d)", 
				tran_rect[1], # 0 ys
				tran_rect[2], # 1 xe
				tran_rect[3], # 2 ye
				tran_rect[0]); #3 xs
				#   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
				me[key].set("clip", clip_rect);
				me[key].set("clip-frame", canvas.Element.PARENT);
			}
			}
		}
		
		if(init_horizon == 1){
			me.h_trans = me["horizon"].createTransform();
			me.h_rot = me["horizon"].createTransform();
		}

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		if( device_av.getValue() == "Garmin G5" ) {
			var volt = volts.getValue();
			var start = getprop(start_prop) or 0;
			if ( start == 1 and volt > 9) {
				G5_start.page.hide();
				G5_only.page.show();
				G5_only.update();
			} else if ( start > 0 and start < 1 and volt > 9){
				G5_only.page.hide();
				G5_start.page.show();
			} else {
				G5_only.page.hide();
				G5_start.page.hide();
			}
			
			settimer(func me.update(), 0.02);
		}
	},
};
	
	
var canvas_G5_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_G5_only , canvas_G5_base] };
		m.init(canvas_group, file, 1);
		
		return m;
	},
	getKeys: func() {
		return ["qnh","gs","ball","rollpointer","heading","horizon","asi.10","asi.rollingdigits","asi.dashes","asi.tape","altBig0","altBig1","altBig2","altBig3","altBig4","altSmall0","altSmall1","altSmall2","altSmall3","altSmall4","alt.tape","alt.1000","alt.100","alt.rollingdigits","hdg.scale","hdg0","hdg1","hdg2","hdg3","ap.alt","ap.alt.pointer","ap.annun","vert.annun","lat.annun","vert.number","bat.group","bat.time","bat.status","bat.rectangles","bat.flash"];
	},
	update: func() {
		var roll = ai_roll.getValue();
		var pitch = ai_pitch.getValue();
		var setting_qnh = alt_qnh.getValue();
		me["qnh"].setText(sprintf("%4.2f", setting_qnh));
		me["gs"].setText(sprintf("%3d", math.round(gr_speed.getValue())));
		me["ball"].setTranslation(slipskid.getValue()*58, 0);
		me["rollpointer"].setRotation(-roll*D2R);
		
		var hdg_deg = hdg.getValue();
		me["heading"].setText(sprintf("%3d", math.round(hdg_deg))~"°");
		var hdg20 = heading_norm_s(hdg_deg+20);
		var hdg10 = heading_norm_s(hdg_deg+10);
		var hdgm10 = heading_norm_s(hdg_deg-10);
		me["hdg2"].setText(sprintf("%3d", 10*math.floor(hdg20/10)));
		me["hdg1"].setText(sprintf("%3d", 10*math.floor(hdg10/10)));
		me["hdg0"].setText(sprintf("%3d", 10*math.floor((hdg_deg)/10)));
		me["hdg3"].setText(sprintf("%3d", 10*math.floor(hdgm10/10)));
		me["hdg.scale"].setTranslation(-math.mod(hdg_deg, 10)*5,0);
		
		me.h_trans.setTranslation(0,pitch*7.2);
		me.h_rot.setRotation(-roll*D2R,me["horizon"].getCenter());
		
		var airspeed = ar_speed.getValue();
		if(airspeed < 30){
			me["asi.10"].hide();
			me["asi.rollingdigits"].hide();
			me["asi.dashes"].show();
			me["asi.tape"].setTranslation(0,0);
		}else{
			me["asi.10"].show();
			me["asi.rollingdigits"].show();
			me["asi.dashes"].hide();
			me["asi.10"].setText(sprintf("%2d", math.round(math.floor(airspeed/10))));
			me["asi.rollingdigits"].setTranslation(0,math.mod(airspeed, 10)*25);
			me["asi.tape"].setTranslation(0,airspeed*4);
		}
		
		var altitude = alt_ft.getValue();
		me["altBig2"].setText(sprintf("%2d", math.floor((altitude+200)/1000)));
		me["altBig1"].setText(sprintf("%2d", math.floor((altitude+100)/1000)));
		me["altBig0"].setText(sprintf("%2d", math.floor((altitude)/1000)));
		me["altBig4"].setText(sprintf("%2d", math.floor((altitude-100)/1000)));
		me["altBig3"].setText(sprintf("%2d", math.floor((altitude-200)/1000)));
		me["altSmall2"].setText(sprintf("%03d", math.mod(100*math.floor((altitude+200)/100),1000)));
		me["altSmall1"].setText(sprintf("%03d", math.mod(100*math.floor((altitude+100)/100),1000)));
		me["altSmall0"].setText(sprintf("%03d", math.mod(100*math.floor((altitude)/100),1000)));
		me["altSmall4"].setText(sprintf("%03d", math.mod(100*math.floor((altitude-100)/100),1000)));
		me["altSmall3"].setText(sprintf("%03d", math.mod(100*math.floor((altitude-200)/100),1000)));
		me["alt.tape"].setTranslation(0,(math.mod(altitude, 100))*0.6);
		
		me["alt.1000"].setText(sprintf("%2d", math.floor((altitude)/1000)));
		me["alt.100"].setText(sprintf("%1d", math.mod(math.floor((altitude)/100),10)));
		me["alt.rollingdigits"].setTranslation(0,math.mod(altitude, 100)*0.9);
		
		var ap_alt_ft = (setting_qnh - ap_alt.getValue()) * 1000;
		
		me["ap.alt"].setText(sprintf("%5d", ap_alt_ft));
		var alt_diff = (altitude-ap_alt_ft) * 0.6;
		me["ap.alt.pointer"].setTranslation(0,math.clamp(alt_diff, -92, 92));
		
		var vert = ap_vert.getValue();
		
		me["ap.annun"].setText(ap_on.getValue());
		me["vert.annun"].setText(vert);
		me["lat.annun"].setText(ap_lat.getValue());
		
		if ( vert == "ALT" ) {
			me["vert.number"].setText(math.round(ap_alt_ft));
		} else if ( vert == "VS" ){
			me["vert.number"].setText(math.round(ap_vs.getValue()));
		} else {
			me["vert.number"].setText("");
		}
		
		if ( bat_f.getBoolValue() or bat_s.getBoolValue() ) {
			me["bat.group"].show();
			var charge = bat_c.getValue();
			if ( charge <= 1.0 and charge >= 0.41 ) {
				me["bat.rectangles"].setColorFill(0,1,0);
			} else if ( charge < 0.41 and charge >= 0.21 ) {
				me["bat.rectangles"].setColorFill(1,1,0);
			} else {
				me["bat.rectangles"].setColorFill(1,0,0);
			}
			me["bat.status"].setTranslation( charge * 19.5 * 12 , 0 );
			var load = bat_l.getValue();
			if( load > 0){
				var battery_time = ( charge * 0.8 ) / bat_l.getValue();
				var hours = math.floor(battery_time);
				var mins = math.mod(battery_time, 1)*60;
				me["bat.time"].show();				
				me["bat.time"].setText( sprintf("%2d", hours) ~ ":" ~ sprintf("%02d", mins) );
			} else {
				me["bat.time"].hide();
			}
			me["bat.flash"].setVisible( bat_ch.getBoolValue() );
		} else {
			me["bat.group"].hide();
		}
		
	},
	
};


var canvas_G5_start = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_G5_start , canvas_G5_base] };
		m.init(canvas_group, file, 0);

		return m;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
	}
	
};


setlistener("sim/signals/fdm-initialized", func {
	G5_display = canvas.new({
		"name": "G5",
		"size": [320, 240],
		"view": [320, 240],
		"mipmapping": 1
	});
	G5_display.addPlacement({"node": "G5.screen"});
	var groupOnly = G5_display.createGroup();
	var groupStart = G5_display.createGroup();

	G5_only = canvas_G5_only.new(groupOnly, base_path~"G5.svg");
	G5_start = canvas_G5_start.new(groupStart, base_path~"G5-start.svg");
	
	canvas_G5_base.update();
	
	
	setlistener(volts, func {
		if( volts.getValue() < 9 and getprop(start_prop) != 0){
			setprop(start_prop, 0);
		}
	});

	setlistener(device_av, func {
		if ( device_av.getValue() == "Garmin G5" ){
			canvas_G5_base.update();
		}
	});
});

var showG5 = func {
	var dlg = canvas.Window.new([320, 240], "dialog").set("resize", 0);
	dlg.setCanvas(G5_display);
}

var pressed_time = getprop("/sim/time/elapsed-sec");

var power_btn = func (x) {	# 1 = pressed 0 = released
	if( x == 1 ) {
		pressed_time = getprop("/sim/time/elapsed-sec");
	} else if ( x == 0 ) {
		var dt = getprop("/sim/time/elapsed-sec") - pressed_time;
		if ( dt < 1 and getprop(start_prop) == 1 ){
			if(bat_s.getValue() == 0){
				bat_s.setValue(1);
			}else{
				bat_s.setValue(0);
			}
		} else {
			if( volts.getValue() >= 9 ){
				if(getprop(start_prop) == 0){
					interpolate(start_prop, 1, 3);	#starting up
				}else if(getprop(start_prop) == 1){
					interpolate(start_prop, 0, 1);	#shutting down
				}
			}
		}
	}
}
	
	
