$input v_color0, v_texcoord0

// Default position texture shader

#include "bgfx_shader.sh"

SAMPLER2D(s_texColor, 0);

void main()
{
	gl_FragColor = mul(v_color0, texture2D(s_texColor, v_texcoord0));
}
