shader_type spatial;
render_mode unshaded, cull_back;

// Your lava texture
uniform sampler2D lava_texture : source_color;
uniform float texture_scale : hint_range(0.1, 20.0) = 1.0;

// Overall lava appearance
uniform vec4 lava_tint : source_color = vec4(1.0, 0.18, 0.02, 1.0);
uniform float brightness : hint_range(0.0, 5.0) = 1.4;

// Emission
uniform vec4 emission_color : source_color = vec4(1.0, 0.08, 0.005, 1.0);
uniform float emission_strength : hint_range(0.0, 20.0) = 5.0;
uniform float emission_pulse : hint_range(0.0, 2.0) = 0.15;

// Lava movement
uniform float wave_speed : hint_range(0.0, 5.0) = 0.35;
uniform float wave_strength : hint_range(0.0, 0.2) = 0.035;
uniform float wave_scale : hint_range(0.1, 10.0) = 2.5;

// Second layer gives the lava a more organic flow
uniform float flow_speed : hint_range(0.0, 5.0) = 0.18;
uniform float flow_strength : hint_range(0.0, 0.2) = 0.025;

// Hot/cold breakup
uniform float hot_threshold : hint_range(0.0, 1.0) = 0.55;
uniform float hot_contrast : hint_range(0.1, 5.0) = 1.8;

void vertex() {
	// Very subtle physical wave movement.
	// This is especially nice on a subdivided plane.
	float t = TIME * wave_speed;

	float wave1 = sin(VERTEX.x * wave_scale + t);
	float wave2 = cos(VERTEX.z * wave_scale * 0.8 + t * 1.2);

	VERTEX.y += (wave1 + wave2) * wave_strength;

	// Small offset variation so it doesn't look perfectly sinusoidal
	VERTEX.y += sin((VERTEX.x + VERTEX.z) * 5.0 + TIME) * wave_strength * 0.25;
}

void fragment() {
	float t = TIME;

	// ---------------------------------------------------------
	// Animated UV distortion
	// ---------------------------------------------------------

	vec2 uv = UV * texture_scale;

	// Large slow waves
	vec2 wave;

	wave.x = sin(uv.y * 8.0 + t * flow_speed * 3.0);
	wave.y = cos(uv.x * 7.0 - t * flow_speed * 2.5);

	uv += wave * flow_strength;

	// Smaller secondary waves
	vec2 detail_wave;

	detail_wave.x = sin(uv.y * 19.0 - t * wave_speed * 2.0);
	detail_wave.y = cos(uv.x * 17.0 + t * wave_speed * 1.7);

	uv += detail_wave * wave_strength;

	// ---------------------------------------------------------
	// Sample lava
	// ---------------------------------------------------------

	vec4 lava = texture(lava_texture, uv);

	// Base color
	vec3 base_color = lava.rgb * lava_tint.rgb * brightness;

	// ---------------------------------------------------------
	// Hot spots
	// ---------------------------------------------------------

	// Luminance of the texture determines where the lava is hottest
	float heat = dot(lava.rgb, vec3(0.299, 0.587, 0.114));

	heat = smoothstep(
		hot_threshold,
		hot_threshold + 0.35,
		heat
	);

	heat = pow(heat, hot_contrast);

	// ---------------------------------------------------------
	// Pulsing emission
	// ---------------------------------------------------------

	float pulse = 1.0 + sin(t * 2.0) * emission_pulse;

	vec3 emission = emission_color.rgb
		* heat
		* emission_strength
		* pulse;

	// Some base emission so the dark lava isn't completely dead
	emission += emission_color.rgb
		* 0.15
		* emission_strength;

	// ---------------------------------------------------------
	// Output
	// ---------------------------------------------------------

	ALBEDO = base_color;
	EMISSION = emission;

	// Rough lava surface
	ROUGHNESS = mix(0.9, 0.65, heat);

	// Slightly metallic is usually NOT desirable for lava
	METALLIC = 0.0;
}