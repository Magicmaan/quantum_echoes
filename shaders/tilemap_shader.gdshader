shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform sampler2D polygon_texture;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	//vec4 tex = texture(TEXTURE,UV);
	//vec2 texel = TEXTURE_PIXEL_SIZE;
	//vec4 to_right = texture(TEXTURE, UV + (texel*2.0));
	//if (to_right.a == 0.0) {
		//COLOR = vec4(1.0,0.0,0.0,1.0);
	//} else {
		//COLOR = to_right;
	//}

	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	vec2 screen_texel = SCREEN_PIXEL_SIZE;
	vec4 c_to_right = textureLod(screen_texture, SCREEN_UV - (screen_texel * 4.0),0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
		COLOR *= c;
	} else {
		COLOR = vec4(0.0);
		if (c_to_right.a > 0.001) {
			COLOR = vec4(0.0,0.0,0.0,0.5);
		}

	}



	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
