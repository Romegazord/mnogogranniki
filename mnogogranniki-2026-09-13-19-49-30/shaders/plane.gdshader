shader_type spatial;
render_mode cull_disabled, unshaded;
uniform vec3 color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = color;
		if (int((SCREEN_UV.x+SCREEN_UV.y)*10000.0) % 200 > 100){
		ALPHA = 0.3;
	}
	else{
		ALPHA = 0.0;
	}
}