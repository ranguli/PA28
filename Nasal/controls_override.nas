
# Overwrite controls.stepMagnetos() function to correspond with properties used in aircraft
var stepMagnetos = func(change) {
	if (!change)
		return;
	var mag = props.globals.getNode("/controls/engines/engine[0]/magnetos-switch", 1);
	
	mag.setIntValue(math.min(mag.getValue() + change, 3));
}

var startEngine = func ( v = 1 ) {
	var mag = props.globals.getNode("/controls/engines/engine[0]/magnetos-switch", 1);
	if( mag.getValue() >= 3 ) {
		if( !v ) {
			props.globals.getNode("/controls/engines/engine[0]/magnetos-switch", 1).setIntValue(3);
		} else {
			props.globals.getNode("/controls/engines/engine[0]/magnetos-switch", 1).setIntValue(4);
		}
	}
}
