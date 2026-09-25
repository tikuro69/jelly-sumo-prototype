shader_type spatial;
// Smooth analytic contact shadows replace the jagged shadow-map edge on the floor.
// No extra geometry at the feet, so there is no overlapping surface to flicker.
render_mode shadows_disabled;
uniform vec3 body_0 = vec3(0.0, -10.0, 0.0);
uniform vec3 body_1 = vec3(0.0, -10.0, 0.0);
uniform vec3 body_2 = vec3(0.0, -10.0, 0.0);
uniform vec4 surface_color : source_color = vec4(0.666667, 0.650980, 0.560784, 1.0);
varying vec3 world_position;
varying float top_face;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    top_face = max(dot(normalize(MODEL_NORMAL_MATRIX * NORMAL), vec3(0.0, 1.0, 0.0)), 0.0);
}

float contact_shadow(vec3 body) {
    float visibility = smoothstep(-0.8, -0.05, body.y) * (1.0 - smoothstep(0.2, 1.8, body.y));
    vec2 offset = world_position.xz - body.xz - vec2(0.12, 0.08);
    float radius_squared = dot(offset / vec2(0.98, 0.86), offset / vec2(0.98, 0.86));
    float feather = exp(-radius_squared * 2.0) * (1.0 - smoothstep(1.4, 3.0, radius_squared));
    return feather * visibility * 0.38;
}

void fragment() {
    float shadow = 1.0 - (1.0 - contact_shadow(body_0)) * (1.0 - contact_shadow(body_1)) * (1.0 - contact_shadow(body_2));
    ALBEDO = surface_color.rgb * (1.0 - shadow * smoothstep(0.8, 1.0, top_face));
    ROUGHNESS = 0.9;
}
