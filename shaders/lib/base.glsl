#ifdef VERT


#ifdef LIGHTMAP
out vec2 lmcoord;
#endif
#ifdef TEXTURED
out vec2 texcoord;
#endif
out vec4 glcolor;

void render() {
	gl_Position = ftransform();
	#ifdef TEXTURED
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	#endif
	#ifdef LIGHTMAP
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	#endif
	glcolor = gl_Color;
}

#ifdef DEFAULT
void main() {
	render();
}
#endif


#endif



#ifdef FRAG


#ifdef LIGHTMAP
uniform sampler2D lightmap;
#endif
#ifdef TEXTURED
uniform sampler2D tex;
#endif
#ifdef ENTITY_COLOR
uniform vec4 entityColor;
#endif

#ifdef LIGHTMAP
in vec2 lmcoord;
#endif
#ifdef TEXTURED
in vec2 texcoord;
#endif
in vec4 glcolor;

void render() {
	#ifdef TEXTURED
	vec4 color = texture(tex, texcoord) * glcolor;
	#else
	vec4 color = glcolor;
	#endif
	#ifdef ENTITY_COLOR
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	#endif
	#ifdef LIGHTMAP
	color *= texture(lightmap, lmcoord);
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
