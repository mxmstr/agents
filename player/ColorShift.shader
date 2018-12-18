shader_type canvas_item;
render_mode blend_add;

uniform vec4 input_color;
uniform vec4 output_color;

void fragment() {
	int precision = 90;
	
    vec4 curr_color = texture(TEXTURE,UV); // Get current color of pixel
	
	vec4 curr_color_round = vec4(
		float(int(curr_color.x * float(precision))), 
		float(int(curr_color.x * float(precision))), 
		float(int(curr_color.x * float(precision))),
		float(int(curr_color.x * float(precision)))
		);
	vec4 target_color_round = vec4(
		float(int(input_color.x * float(precision))), 
		float(int(input_color.x * float(precision))), 
		float(int(input_color.x * float(precision))),
		float(int(input_color.x * float(precision)))
		);
	
    if (curr_color_round == target_color_round){
        COLOR = output_color;
    }else{
        COLOR = vec4(0, 0, 0, 0);
    }
}