#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform float u_Time;

void main() {
	//Formula by Reinhard
	vec3 texColor = texture(u_frame, fs_UV).xyz;
	texColor *= texColor; // skews colors because I liked it like this
    texColor *= 5.f;  // Hardcoded Exposure Adjustment because of color range
    texColor /= (1.f + texColor);
	// gamma correction
    vec3 retColor = vec3(pow(texColor.x, 1.0 / 2.2), pow(texColor.y, 1.0 / 2.2), pow(texColor.z, 1.0 / 2.2));

	out_Col = vec4(retColor, 1.f);
}

// // previous main() for comparison purposes
// void main() {
// 	// TODO: proper tonemapping
// 	// This shader just clamps the input color to the range [0, 1]
// 	// and performs basic gamma correction.
// 	// It does not properly handle HDR values; you must implement that.

// 	vec3 color = texture(u_frame, fs_UV).xyz;
// 	color = min(vec3(1.0), color);

// 	// gamma correction
// 	color = pow(color, vec3(1.0 / 2.2));
// 	out_Col = vec4(color, 1.0);
// }
