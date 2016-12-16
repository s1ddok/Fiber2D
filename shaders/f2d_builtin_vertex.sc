$input a_position, a_texcoord0, a_texcoord1, a_color0
$output v_texcoord0, v_color0

void main()
{
	gl_Position = a_position;
  v_texcoord0 = a_texcoord0;
	v_color0 = a_color0;
}
