shader_type canvas_item;
//void vertex() {
	//// Called for every vertex the material is visible on.
//}

void fragment() {
	// Multiply original tile texture color with red
    COLOR = vec4(0.0,0.0,0.0,1.0);

}

void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
	LIGHT = vec4(0.0,0.0,0.0,1.0);
}
