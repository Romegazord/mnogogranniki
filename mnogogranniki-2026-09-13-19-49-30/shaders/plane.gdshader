shader_type spatial;
render_mode cull_disabled, unshaded;
uniform vec3 color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = color;
	ALPHA = .3;
}