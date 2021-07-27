#ifdef VERT


#ifdef TEXTURED
attribute vec2 mc_Entity;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

#ifdef LIGHTMAP
out vec2 lmcoord;
#endif
out vec2 texcoord;
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
#define FOG_DENSITY 0.8 // [0, 1]
#define FLUID_FOG_DENSITY 0.5 // [0, 1]
#endif

// Includes
#ifdef FOG
#include "/lib/fog.glsl"
#endif

// Constants
#ifdef FOG
/*
const bool gaux1Clear = false;
*/
#endif

// Uniforms
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
// uniform float frameTime; // how long it took for the last frame to render
// uniform sampler2D gaux1;
#endif

#ifdef LIGHTMAP
in vec2 lmcoord;
#endif
in vec2 texcoord;
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
	#ifdef FOG
	// https://github.com/XorDev/XorDevs-Default-Shaderpack/blob/c13319fb7ca1a178915fba3b18dee47c54903cc3/shaders/gbuffers_textured.fsh#L42
	// render fog
	float fog;
	float fogStart;
	float fogEnd;
	// float submergeTime = texture(gaux1, texcoord).r;
	if (isEyeInWater == 0) { // normal fog
		// if (submergeTime > 0) {
		// 	submergeTime = 0;
		// }

		fogStart = far * FOG_DENSITY;
		fogEnd = far;
	} else { // underwater fog
		// increment submerge time by the frame time
		// submergeTime = submergeTime + frameTime;

		// calculate fog visibility
		float fogVisibility = 192;
		// fogVisibility *= max(0.25, underwaterVisibility(submergeTime));
		fogVisibility *= 0.9;

		// if (isSwampBiome) { // swamp fog
		// 	fogVisibility *= 0.85;
		// }

		// fog properties
		fogStart = -8;
		fogEnd = fogVisibility * FLUID_FOG_DENSITY;
	}
	// calculate fog
	fog = smoothstep(fogStart, fogEnd, vertDist);
	color.rgb = mix(color.rgb, fogColor.rgb, fog);
	#ifdef DEBUG
	if (gl_FragCoord.x >= 1499 && gl_FragCoord.y >= 800) {
		color.rgb = vec3(fogStart / 255);
	} else if (gl_FragCoord.x >= 1499 && gl_FragCoord.y >= 700 && gl_FragCoord.y <= 800) {
		color.rgb = vec3(fogEnd / 255);
	}
	#endif
	#endif

	/* DRAWBUFFERS:04 */
	#ifdef LIGHTMAP
	gl_FragData[0] = color; //gcolor
	#else
	// https://github.com/XorDev/XorDevs-Default-Shaderpack/blob/c13319fb7ca1a178915fba3b18dee47c54903cc3/shaders/gbuffers_basic.fsh#L34
	gl_FragData[0] = color * vec4(vec3(1 - blindness), 1); //gcolor
	#endif
	// #ifdef FOG
	// gl_FragData[1] = vec4(submergeTime, 0, 0, 0);
	// #endif
}

#ifdef DEFAULT
void main() {
	render();
}
#endif


#endif
