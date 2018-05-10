#version 300 es
precision highp float;

#define EPS 0.0001
#define PI 3.1415962

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_gb0;
uniform sampler2D u_gb1;
uniform sampler2D u_gb2;

uniform float u_Time;

uniform mat4 u_View;
uniform vec4 u_CamPos;   

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}

vec3 mix3(vec3 v1, vec3 v2, vec3 v3, float f) {
  if (f < 0.6) {
    return mix(v1, v2, f * 1.666666666f);
  } else {
    return mix(v2, v3, (f - 0.6) * 2.5f);
  }
}

void main() { 
	// read from GBuffers
	vec4 gb0 = texture(u_gb0, fs_UV);
	vec4 gb2 = texture(u_gb2, fs_UV);

	// To find position - unused
	// float x = fs_UV.x * 2.f - 1.f;
	// float y = 1.f - fs_UV.y * 2.f;
	vec4 nor = vec4(gb0.xyz, 0.f);

	// Camera's forward vector
	vec4 forward = vec4(u_View[0][2], u_View[1][2], u_View[2][2], 0.f);
	forward = (forward * u_View[2]); // because the light rotation was not proportional to the camera's
	// vec4 ref = u_CamPos * forward;

	// Blinn-Phong calculation
	vec4 avg = (normalize(vec4(5.f, 5.f, 5.f, 0.f)) + forward) / 2.f;
	float specularIntensity = max(pow(dot(normalize(avg), normalize(nor)), 35.f), 0.f);

	// Calculate the diffuse term for Lambert shading - light source = camera
    float diffuseTerm = dot(normalize(nor), normalize(forward));
	// Avoid negative lighting values
	diffuseTerm = min(diffuseTerm, 1.0);
    diffuseTerm = max(diffuseTerm, 0.0);
	// Adds ambient lighting
	float ambientTerm = 0.2;
    float lightIntensity = diffuseTerm + ambientTerm;
    
	vec3 col = gb2.xyz;
	col = gb2.xyz * lightIntensity;

	if (gb0.w < 0.f) {
		out_Col = vec4(col + specularIntensity, 1.f);
	} else {
		float waterMove  = sin(u_Time * 0.5) * 0.5 + sin(u_Time) * 0.3 + sin(u_Time * 2.5) * 0.2 + cos((u_Time + 2700.f) * 0.01) * 0.3;
          // previously 10 + waterMove and 5 + waterMove
        float watText = sqrt(sqrt(abs(snoise(vec3(fs_UV, 0.0) * (5.f + waterMove) )))) * 0.4 + 
						sqrt(sqrt(abs(snoise(vec3(1.f - fs_UV, 0.0) * (3.1f + waterMove))))) * 0.35 +
						sqrt(sqrt(abs(snoise(vec3(fs_UV.x + waterMove / 2.f, 1.f - fs_UV.y + waterMove, 0.0) * (5.f + waterMove) )))) * 0.15 + 
						sqrt(sqrt(abs(snoise(vec3(1.f - fs_UV.x + waterMove, fs_UV.y - waterMove / 3.f, 0.0) * (3.1f + waterMove))))) * 0.1;
        col = mix3(vec3(1.f, 1.f, 1.f), vec3(24.f / 255.f, 140.f / 255.f, 160.f / 255.f), vec3(0.f, 0.07f, 0.55f), watText);
        
		out_Col = vec4(col, 1.f);
	}
}