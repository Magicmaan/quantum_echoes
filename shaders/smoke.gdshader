shader_type canvas_item;

uniform sampler2D texture_albedo;

float bayer_dither(vec2 screen_uv, float value, vec2 p_size) {
	// 4x4 Bayer matrix stored as a 1D array
	float bayer[16] = float[16](
		0.0,  8.0,  2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0,  9.0,
		15.0, 7.0, 13.0, 5.0
	);

	// Convert screen UV to integer pixel coordinates
	ivec2 pixel = ivec2(floor(screen_uv * p_size));
	int x = pixel.x % 4;
	int y = pixel.y % 4;

	// Convert 2D index to 1D index in 4x4 matrix
	int index = y * 4 + x;

	float threshold = bayer[index] / 16.0;

	return value > threshold ? 1.0 : 0.0;
}

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;


// Helper: fade function for smooth interpolation
float fade(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// 2D gradient function
float grad(int hash, vec2 pos) {
    int h = hash & 3; // Convert low 2 bits of hash code
    float u = h < 2 ? pos.x : pos.y;
    float v = h < 2 ? pos.y : pos.x;
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

// Permutation table (classic 256)
const int perm[256] = int[256](
    151,160,137,91,90,15,
    131,13,201,95,96,53,194,233,7,225,
    140,36,103,30,69,142,8,99,37,240,21,10,23,
    190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,
    35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,
    168, 68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,
    111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
    102,143,54, 65,25,63,161,1,216,80,73,209,76,132,187,208,
    89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,
    186, 3,64,52,217,226,250,124,123,5,202,38,147,118,126,255,
    82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,
    183,170,213,119,248,152, 2,44,154,163,70,221,153,101,155,167,
    43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,
    185,112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,
    179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,181,
    199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,
    215,61,156,180
);

// Permutation lookup helper
int permLookup(int i) {
    return perm[i & 255];
}

float perlinNoise(vec2 pos) {
    // Calculate grid cell coordinates and offsets
    ivec2 i = ivec2(floor(pos));
    vec2 f = fract(pos);

    // Compute fade curves for x and y
    vec2 u = vec2(fade(f.x), fade(f.y));

    // Hash coordinates of the 4 square corners
    int aa = permLookup(i.x + permLookup(i.y));
    int ab = permLookup(i.x + permLookup(i.y + 1));
    int ba = permLookup(i.x + 1 + permLookup(i.y));
    int bb = permLookup(i.x + 1 + permLookup(i.y + 1));

    // Calculate gradient contributions from corners
    float gradAA = grad(aa, f - vec2(0.0, 0.0));
    float gradBA = grad(ba, f - vec2(1.0, 0.0));
    float gradAB = grad(ab, f - vec2(0.0, 1.0));
    float gradBB = grad(bb, f - vec2(1.0, 1.0));

    // Interpolate the four results
    float lerpX1 = mix(gradAA, gradBA, u.x);
    float lerpX2 = mix(gradAB, gradBB, u.x);
    float lerpY = mix(lerpX1, lerpX2, u.y);

    // Normalize to [0,1]
    return 0.5 + 0.5 * lerpY;
}

float bayerDither(vec2 uv, float alpha, vec2 pixel_size) {
    float bayerVals[4] = float[](0.0, 0.5, 0.75, 0.25);
    ivec2 lowres_pixel_pos = ivec2(floor(uv / pixel_size));
    int x = lowres_pixel_pos.x % 2;
    int y = lowres_pixel_pos.y % 2;
    int index = y * 2 + x;
    float threshold = bayerVals[index];
    return alpha > threshold ? alpha * 2.0 : 0.0;
}

void fragment() {
	float time = mod(TIME,5.0)/5.0;
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    vec2 uv = floor(UV / pixel_size) * pixel_size + pixel_size * 0.5;

    vec2 center = vec2(0.5, 1.0-time);
    float radius = 0.5;

    float dist = distance(uv, center);
	if (dist > radius+0.25) {
		discard;
	}


    // Base alpha fading with quantized dist
    float alpha = pow(1.0 - (round(dist * 32.0) / 32.0), 6.0);

    // Apply Perlin noise modulated on alpha
    float noiseVal = perlinNoise(uv * 5.0)*4.0; // 20.0 is noise scale
    alpha *= (noiseVal);

    // Bayer dithering
    float dithered_alpha = bayerDither(uv, alpha, pixel_size);
	dithered_alpha /= time*16.0;
    COLOR = vec4(vec3(1.0), dithered_alpha);
}
