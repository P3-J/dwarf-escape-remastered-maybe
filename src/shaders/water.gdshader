shader_type spatial;
// unshaded означает, что свет и отражения НЕ влияют на материал. 
// Он всегда будет выглядеть ярко и правильно, даже в полной темноте.
render_mode unshaded, depth_draw_opaque, cull_back;

// === ТЕКСТУРЫ ===
uniform sampler2D normal_map : source_color;      // анимированная normal map (рябь)
uniform sampler2D flow_map : source_color;        // направление течения (R=X, G=Y)
uniform sampler2D base_texture : source_color;    // текстура лавы (светлые части будут светиться)

// === ПАРАМЕТРЫ ===
uniform vec3 cool_color : source_color = vec3(0.05, 0.01, 0.0);  // цвет остывшей корки (почти черный)
uniform vec3 hot_color : source_color = vec3(1.0, 0.4, 0.0);     // цвет раскаленной лавы (оранжевый/желтый)
uniform float emission_strength = 3.0;                           // общая сила свечения
uniform float emission_flicker_speed = 2.0;                      // скорость мерцания лавы
uniform vec2 base_texture_scale = vec2(4.0, 4.0);                // масштаб повторения текстуры

uniform float wave_speed = 0.3;
uniform float wave_strength = 0.05;
uniform float flow_strength = 0.5;

// === ВЕРШИННЫЕ ВОЛНЫ ===
void vertex() {
    vec2 uv_flow = UV + TIME * wave_speed * 0.1;
    float wave = sin(UV.x * 20.0 + TIME * 2.0) * cos(UV.y * 15.0 + TIME * 1.5);
    VERTEX.y += wave * wave_strength;
}

// === ФРАГМЕНТ ===
void fragment() {
    // --- Flow map (течение) ---
    vec2 flow_dir = texture(flow_map, UV).rg * 2.0 - 1.0;
    vec2 uv1 = UV + flow_dir * flow_strength * TIME * 0.05;
    vec2 uv2 = UV + flow_dir * flow_strength * (TIME * 0.05 + 0.5);

    // --- Анимированная normal map ---
    vec3 n1 = texture(normal_map, uv1).rgb;
    vec3 n2 = texture(normal_map, uv2).rgb;
    vec3 blended_normal = normalize(n1 + n2 - vec3(1.0));
    NORMAL_MAP = blended_normal;
    NORMAL_MAP_DEPTH = 1.0;

    // --- Base texture с повторением и течением ---
    vec2 tiled_uv = UV * base_texture_scale;
    vec2 final_uv = tiled_uv + flow_dir * flow_strength * TIME * 0.05;
    vec4 base = texture(base_texture, final_uv);

    // --- Цвет и Свечение (Emission) на основе текстуры ---
    // Вычисляем яркость текстуры (0.0 = черный, 1.0 = белый)
    float brightness = dot(base.rgb, vec3(0.299, 0.587, 0.114));
    
    // Смешиваем холодный и горячий цвет на основе яркости текстуры
    // smoothstep делает переход более резким, как у реальной корки лавы
    vec3 final_color = mix(cool_color, hot_color, smoothstep(0.2, 0.7, brightness));
    
    // Добавляем легкое мерцание для живости
    float flicker = sin(TIME * emission_flicker_speed + UV.x * 10.0 + UV.y * 5.0) * 0.1 + 0.9;
    
    // Свечение напрямую зависит от яркости текстуры
    vec3 emission = hot_color * emission_strength * brightness * flicker;

    // --- Настройки материала ---
    ALBEDO = final_color;
    EMISSION = emission;
    
    // Эти параметры не влияют на unshaded, но оставлены для совместимости
    ROUGHNESS = 0.1;
    METALLIC = 0.0;
    ALPHA = 1.0; // Абсолютно непрозрачный, сквозь него ничего не видно
}