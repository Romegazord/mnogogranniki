shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (int(UV.x*10000.0) % 250 == 0 || int(UV.y*10000.0) % 250 == 0){
		ALPHA = 1.0;
	}
	else{
		ALPHA = 0.0;
	}
	ALBEDO = vec3(0.4);

}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
