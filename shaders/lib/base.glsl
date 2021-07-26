#ifdef VERT


#ifdef TEXTURED
attribute vec2 mc_Entity;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

#ifdef LIGHTMAP
out vec2 lmcoord;
#endif
#ifdef TEXTURED
out vec2 texcoord;
#endif
out vec4 glcolor;
#ifdef FOG
out float vertDist;
#endif

void render() {
	#ifdef FOG
	vec4 position = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
	vec3 blockPos = position.xyz;
	vertDist = length(blockPos);
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	#else
	gl_Position = ftransform();
	#endif

	#ifdef TEXTURED
	// Calculate normals
	vec3 normal = gl_NormalMatrix * gl_Normal;
	// https://github.com/XorDev/XorDevs-Default-Shaderpack/blob/c13319fb7ca1a178915fba3b18dee47c54903cc3/shaders/gbuffers_textured.vsh#L39
	// Use flat for flat "blocks" or world space normal for solid blocks.
	normal = (mc_Entity.x == 4) ? vec3(0, 1, 0) : (gbufferModelViewInverse * vec4(normal, 0)).xyz;

	// https://github.com/XorDev/XorDevs-Default-Shaderpack/blob/c13319fb7ca1a178915fba3b18dee47c54903cc3/shaders/gbuffers_textured.vsh#L42
	// Calculate simple lighting
	// NOTE: This is as close to vanilla as XorDev can get it. It's not perfect, but it's close.
	float light = .8-.25*abs(normal.x*.9+normal.z*.3)+normal.y*.2;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	#endif
	#ifdef LIGHTMAP
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	#endif
	#ifdef TEXTURED
	glcolor = vec4(gl_Color.rgb * light, gl_Color.a);
	#else
	glcolor = gl_Color;
	#endif
}

#ifdef DEFAULT
void main() {
	render();
}
#endif


#endif



#ifdef FRAG


// Options
#ifdef FOG
#define FOG_COVERAGE 0.8 // [0, 1]
#define FLUID_FOG_DENSITY 0.175 // [0, 1]
#endif

#ifdef LIGHTMAP
uniform sampler2D lightmap;
#endif
uniform float blindness;
#ifdef TEXTURED
uniform sampler2D tex;
#endif
#ifdef ENTITY_COLOR
uniform vec4 entityColor;
#endif
#ifdef FOG
uniform vec3 fogColor;
uniform float far;
uniform int isEyeInWater;
#endif

#ifdef LIGHTMAP
in vec2 lmcoord;
#endif
#ifdef TEXTURED
in vec2 texcoord;
#endif
in vec4 glcolor;
#ifdef FOG
in float vertDist;
#endif

void render() {
	#ifdef TEXTURED
	vec4 color = texture(tex, texcoord) * glcolor;
	#else
	vec4 color = glcolor;
	#endif
	// https://github.com/XorDev/XorDevs-Default-Shaderpack/blob/c13319fb7ca1a178915fba3b18dee47c54903cc3/shaders/gbuffers_textured.fsh#L35
	#ifdef LIGHTMAP
	// combine the lightmap with blindness
	vec3 light = (1 - blindness) * texture(lightmap, lmcoord).rgb;
	color *= vec4(light, 1);
	#endif
	// apply mob entity flashes
	#ifdef ENTITY_COLOR
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	#endif
	// render fog
	#ifdef FOG
	// https://github.com/XorDev/XorDevs-Default-Shaderpack/blob/c13319fb7ca1a178915fba3b18dee47c54903cc3/shaders/gbuffers_textured.fsh#L42
	float fogStart = far * FOG_COVERAGE;
	float fogEnd = far;
	float fog = (isEyeInWater > 0) ? 1 - exp(-vertDist * FLUID_FOG_DENSITY) : smoothstep(fogStart, fogEnd, vertDist);
	color.rgb = mix(color.rgb, fogColor.rgb, fog);
	#endif

	#ifdef LIGHTMAP
/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
	#else
	// https://github.com/XorDev/XorDevs-Default-Shaderpack/blob/c13319fb7ca1a178915fba3b18dee47c54903cc3/shaders/gbuffers_basic.fsh#L34
/* DRAWBUFFERS:0 */
	gl_FragData[0] = color * vec4(vec3(1 - blindness), 1); //gcolor
	#endif
}

#ifdef DEFAULT
void main() {
	render();
}
#endif


#endif
