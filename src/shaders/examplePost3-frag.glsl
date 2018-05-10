#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform float u_Time;
uniform float u_Bloom;
uniform vec2 u_Dimensions;

void main() {
	// Gaussian Blur
	vec3 total = vec3(0, 0, 0);
	vec2 tempScale = fs_UV * u_Dimensions;
    float pi = 3.1415926535897932384626433832795;
    float e = 2.7182818284590452353602874713526;
    float sigma = 3.f;
	float scale = 6.f;
    for (float i = tempScale.x - scale; i <= tempScale.x + scale; i++) {
        for (float j = tempScale.y - scale; j <= tempScale.y + scale; j++) {
            vec2 temp = vec2(i / u_Dimensions.x, j / u_Dimensions.y);
			vec3 t = texture(u_frame, temp).xyz;

			// At first I tested if temp is above the range and should be included in the blur, if not, factor the correct texture 
			if (t.x > 1.f - 0.8f * u_Bloom && 	//into this equation instead of the one at 'temp.' But since I realized a technical 
				t.y > 1.f - 0.5f * u_Bloom && 	//bloom effect adds the blurred pixels on top of the given image, this might be a 
				t.z > 1.f - 0.95f * u_Bloom) {  //more accurate effect, and appeared to not need another pass.

				float dist = distance(tempScale, vec2(i,j));
				float exponent = (-1.f * dist * dist) /
						(2.f * sigma * sigma);

				float g = pow(e, exponent) / (2.f * pi * pow(sigma, 2.f));
				
				total += (g * t);
			}
        }
    }

	// At first I still scaled the end result 
	out_Col = vec4(texture(u_frame, fs_UV).xyz + total, 1.0);
}

//Previous shader for comparison purposes
// // Interpolate between regular color and channel-swizzled color
// // on right half of screen. Also scale color to range [0, 5].
// void main() {
// 	vec3 color = texture(u_frame, fs_UV).xyz;
// 	color += 10.0 * max(color - 0.5, vec3(0.0)); // color is not clamped to 1.0 in 32 bit color

// 	vec3 color2 = color.brg;
// 	float t = 0.5 + 0.5 * cos(1.5 * 3.14 * (u_Time + 0.25));
// 	t *= step(0.5, fs_UV.x);
// 	color = mix(color, color2, smoothstep(0.0, 1.0, t));
// 	out_Col = vec4(color, 1.0);
// }
