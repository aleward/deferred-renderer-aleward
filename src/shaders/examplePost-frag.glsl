#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform float u_Time;
uniform float u_Depth;
uniform vec2 u_Dimensions;

uniform sampler2D u_gb0;

// Interpolation between color and greyscale over time on left half of screen
void main() {
	float depth = -1.f * texture(u_gb0, fs_UV).w;// * 100.f;
	
	// Gaussian Blur
	vec3 total = vec3(0, 0, 0);
	if (depth == -1.f) { depth = 100.f; }
	float d = depth - u_Depth;
	// if (d < -1.f) { d = max(-99.f, d * 1.5f);}
	d = abs(d) + 1.f;
	float imgScale = 3.f - sqrt(abs(d) / 100.f) * 2.9f; //(d * d / 1000.f)
	vec2 tempScale = fs_UV * u_Dimensions * imgScale;
    float pi = 3.1415926535897932384626433832795;
    float e = 2.7182818284590452353602874713526;
    float sigma = 3.f;
    float gSum = 0.f;
	float scale = 3.f;
    for (float i = tempScale.x - scale; i <= tempScale.x + scale; i++) {
        for (float j = tempScale.y - scale; j <= tempScale.y + scale; j++) {
            float dist = distance(tempScale, vec2(i,j));
			float exponent = (-1.f * dist * dist) /
                    (2.f * sigma * sigma);

            float g = pow(e, exponent) / (2.f * pi * pow(sigma, 2.f));
            
			vec2 temp = vec2(i / (u_Dimensions.x * imgScale), j / (u_Dimensions.y * imgScale));
            total += (g * texture(u_frame, temp).xyz);
            gSum += g;
        }
    }

	// vec3 color2 = vec3(dot(color, vec3(0.2126, 0.7152, 0.0722)));
	// float t = sin(3.14 * u_Time) * 0.5 + 0.5;
	// // t *= 1.0 - step(0.5, fs_UV.x);
	// color = mix(color, color2, smoothstep(0.0, 1.0, t));
	
	// if (d > 2.f) { out_Col = vec4(1.f, 0.f, 0.f, 1.f); } else {
	out_Col = vec4(total / gSum, 1.0);//}
}
