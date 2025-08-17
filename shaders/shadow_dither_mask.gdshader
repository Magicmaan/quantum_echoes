shader_type canvas_item;
render_mode unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// VARIABLES
	float dither_brightness = 3.0; // Brightness multiplier
	float bg_opacity = 0.1; // Background alpha value (0.0 = fully transparent, 1.0 = fully opaque)
	float dither_opacity = 0.3;


	// 2x2 Bayer matrix
	// 4x4 Bayer matrix
	float bayer4x4[16] = float[16](
		0.0,  8.0,  2.0, 10.0,
		12.0, 4.0, 14.0,  6.0,
		3.0, 11.0,  1.0,  9.0,
		15.0, 7.0, 13.0,  5.0
	);
//
	vec4 base = texture(TEXTURE, UV);
	float gray = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	base = vec4(gray,gray,gray, base.a);
	base = base / dither_brightness; // Apply brightness multiplier
//
	//// Use base.r as shadow amount: 1.0 = full shadow (opaque), 0.0 = light (transparent)
	float shadow = base.r;


//
	//// Scale dithering to 4x the size (each Bayer cell covers 4x4 pixels)
	int bx = int(mod(floor(UV.x * (1.0 / TEXTURE_PIXEL_SIZE.x) / 1.0), 2.0));
	int by = int(mod(floor(UV.y * (1.0 / TEXTURE_PIXEL_SIZE.y) / 1.0), 2.0));
	int bayer_index = by * 4 + bx;
	float threshold = bayer4x4[bayer_index] / 16.0;

	//COLOR = vec4(1.0-base.r,1.0-base.g,1.0-base.b,1.0);
	//// Always dither, even for full darkness
	if (shadow > threshold) {
		COLOR = vec4(0.0, 0.0, 0.0, dither_opacity); // Black, opaque
	} else if (shadow > 0.0) {
		COLOR = vec4(vec3(0.0),bg_opacity);
	} else {
		COLOR = vec4(0.0);
	}
	//else {
		//if (shadow == 0.0) {
			//COLOR = vec4(0.0, 0.0, 0.0, 0.0); // Transparent based on shadow amount
		//} else {
			//COLOR = vec4(0.0,0.0,0.0,1.0);
//
		//}
	//}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
