#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;

uniform float u_Time;
uniform vec2 u_Dimensions;
uniform vec3 u_Velocity;
uniform mat4 u_View;
uniform mat4 u_Proj;
uniform mat4 u_ViewProj; // the last frame's

uniform sampler2D u_gb1;

// Render R, G, and B channels individually
void main() {

	// if (u_ViewProj != u_Proj * u_View) {

	vec4 text = texture(u_gb1, fs_UV);

	// if (text.w == 1.f) { text.w = -100.f; } 
	// else {text.w = -25.f;}

	float x = fs_UV.x * 2.f - 1.f;
	float y = 1.f - fs_UV.y * 2.f;
	vec2 current = vec2(x, y);

	vec4 eye = vec4(u_View[3].xyz, 1.0);
	vec4 f = u_View[2];// * vec4(u_View[0][2], u_View[1][2], u_View[2][2], 0.0);//vec4(0.f, 0.f, 1.f, 0.0);//
	vec4 u = u_View[1];// * vec4(u_View[0][1], u_View[1][1], u_View[2][1], 0.0);//vec4(0.f, 1.f, 0.f, 0.0);//
	vec4 r = u_View[0];// * vec4(u_View[0][0], u_View[1][0], u_View[2][0], 0.0);//vec4(1.f, 0.f, 0.f, 0.0);//

	vec4 dir = abs(text.w) * f;

	float aspect = u_Dimensions.x / u_Dimensions.y;
	float a = (45.f * 3.1415962 / 180.0) / 2.0; // hardcoded FOVY/2
	// float len = length(dir);

	vec4 ref = eye + dir;
	float len = length(ref - eye);
	vec4 v = u * len * tan(a);
	vec4 h = r * len * aspect * tan(a);

	vec4 worldPos = ref + x * h + y * v;

	vec4 change = vec4(0.f, 0.f, 0.f, 0.f); 
	//if (text.w < -1.f) {
		change = vec4(u_Velocity * -sin(u_Time * 2.5f + 3.1415962 / 2.f), 0.f);
	//}//vec4(1.f, 0.f, 0.f, 0.f);

	vec4 previous = u_ViewProj * (worldPos - eye + change);
	// previous /= previous.w;
	// previous /= u_Dimensions.x;

	vec2 velocity = (current - previous.xy);

	// if (length(velocity) > 0.f) { //u_ViewProj != u_Proj * u_View) {//
		vec2 sampLoc = fs_UV;
		vec3 currCol = vec3(0.0);
		float num = 15.f;
		float total = 0.f;

		for (float i = 0.f; i < num; i++, sampLoc += (velocity / u_Dimensions)) {
			float bleh = 1.f - i / num;
			// only blurs using model pixels
			if (texture(u_gb1, sampLoc).w != 1.f) {
				currCol += texture(u_frame, sampLoc).xyz * bleh;
			} else {
				currCol += texture(u_frame, fs_UV).xyz * bleh;
			}
			total += bleh;
		}

		out_Col = vec4(currCol / total, 1.0);
	// } else {

	// out_Col = texture(u_frame, fs_UV);}
}

// // Render R, G, and B channels individually
// void main() {
// 	out_Col = vec4(texture(u_frame, fs_UV + vec2(0.33, 0.0)).r,
// 								 texture(u_frame, fs_UV + vec2(0.0, -0.33)).g,
// 								 texture(u_frame, fs_UV + vec2(-0.33, 0.0)).b,
// 								 1.0);
//  out_Col.rgb += texture(u_frame, fs_UV).xyz;
// }