#ifdef VERT


uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

in vec2 mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out float vertDist;

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
	float light = 0.8 - 0.25 * abs(normal.x * 0.9 + normal.z * 0.3) + normal.y * 0.2;

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
#define FOG_DENSITY 0.75 // [0, 1]
#define FLUID_FOG_DENSITY 0.5 // [0, 1]

// Includes
#include "/lib/fog.glsl"

// Constants
/*
// const bool gaux1Clear = false;
*/

// Uniforms
uniform sampler2D lightmap;
uniform float blindness;
uniform sampler2D tex;
uniform vec4 entityColor;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float far;
uniform int isEyeInWater;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in float vertDist;

void render() {
	vec4 color;
	#ifdef TEXTURED
	color = texture(tex, texcoord) * glcolor;
	#else
	color = glcolor;
	#endif

	vec3 light;
	float blindAmount = 1 - blindness; // what to multiply the light by

	// apply blindness effect
	#ifdef BLINDNESS
	// calculate lighting
	#ifdef LIGHTMAP
	// https://github.com/XorDev/XorDevs-Default-Shaderpack/blob/c13319fb7ca1a178915fba3b18dee47c54903cc3/shaders/gbuffers_textured.fsh#L35
	// combine the lightmap with blindness
	light = (blindAmount) * texture(lightmap, lmcoord).rgb;
	#else
	light = vec3(blindAmount);
	#endif
	#else
	// calculate lighting
	light = vec3(blindAmount);
	#endif

	color *= vec4(light, 1);

	// apply mob entity flashes
	#ifdef ENTITY_COLOR
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	#endif

	// render fog
	#ifdef FOG
	float fog;
	float fogStart;
	float fogEnd;
	float fogVisibility;

	switch (isEyeInWater) {
		case 0: // normal fog
			fogStart = far * FOG_DENSITY;
			fogEnd = far;
			break;
		case 1: // underwater fog
			// calculate fog visibility
			fogVisibility = 192 * 0.9;

			// fog properties
			fogStart = -8;
			fogEnd = fogVisibility * FLUID_FOG_DENSITY;
			break;
		case 2: // lava fog
			// calculate fog visibility
			fogVisibility = 2 * 0.5;

			// fog properties
			fogStart = -8;
			fogEnd = fogVisibility * FLUID_FOG_DENSITY;
			break;
	}

	// calculate fog
	fog = smoothstep(fogStart, fogEnd, vertDist);

	// mix fog color with sky color
	if (isEyeInWater == 0) {
		color.rgb = mix(color.rgb, skyColor.rgb, fog);
	}
	color.rgb = mix(color.rgb, fogColor.rgb, fog);

	// squares for debugging
	#ifdef DEBUG
	if (gl_FragCoord.x >= 1499 && gl_FragCoord.y >= 800) {
		color.rgb = vec3(fogStart / 255);
	} else if (gl_FragCoord.x >= 1499 && gl_FragCoord.y >= 700 && gl_FragCoord.y <= 800) {
		color.rgb = vec3(fogEnd / 255);
	}
	#endif
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}

#ifdef DEFAULT
void main() {
	render();
}
#endif


#endif
