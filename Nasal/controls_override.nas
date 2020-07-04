
# Overwrite controls.stepMagnetos() function to correspond with properties used in aircraft
var mag = props.globals.getNode("/controls/engines/engine[0]/magnetos-switch", 1);
var stepMagnetos = func(change) {
	if (!change)
		return;
	
	mag.setIntValue( math.clamp(mag.getValue() + change, 0, 3));
}

var startEngine = func ( v = 1 ) {
	if( mag.getValue() >= 3 ) {
		if( !v ) {
			mag.setIntValue(3);
		} else {
			mag.setIntValue(4);
		}
	}
}
