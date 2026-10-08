shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.75, 0.02, 0.05, 1.0);

void fragment() {
	vec2 uv = (UV - vec2(0.5)) * vec2(1.0, 1.0);
	float dist = length(uv * vec2(1.15, 1.4));
	float vig = smoothstep(0.35, 0.95, dist);
	COLOR = vec4(vignette_color.rgb, vig * vignette_color.a * strength);
}
