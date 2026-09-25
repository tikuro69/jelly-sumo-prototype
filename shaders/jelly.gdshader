shader_type spatial;
render_mode cull_back;
uniform vec4 body_color : source_color = vec4(0.2, 0.8, 0.7, 1.0);
uniform vec2 push_direction = vec2(1.0, 0.0);
uniform float compression = 0.0;

vec3 deform(vec3 p) {
    vec2 d = normalize(push_direction + vec2(0.00001));
    float along = dot(p.xz, d);
    vec2 side = p.xz - d * along;
    // Local belly dent on the contacting side; displaced volume bulges sideways.
    float contact_side = smoothstep(-0.25, 0.72, along);
    float belly_band = exp(-p.y * p.y * 2.2);
    p.xz -= d * compression * contact_side * belly_band;
    p.xz += side * compression * 0.65;
    p.y *= 1.0 + compression * 0.20;
    return p;
}

void vertex() {
    // Recompute normals from the same deformation so highlights follow the dent.
    vec3 p = VERTEX;
    vec3 n = NORMAL;
    vec3 tangent = normalize(cross(n, abs(n.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
    vec3 bitangent = normalize(cross(n, tangent));
    vec3 deformed = deform(p);
    NORMAL = normalize(cross(deform(p + tangent * 0.003) - deformed, deform(p + bitangent * 0.003) - deformed));
    VERTEX = deformed;
}

void fragment() {
    ALBEDO = body_color.rgb;
    ROUGHNESS = 0.29;
    SPECULAR = 0.48;
}
