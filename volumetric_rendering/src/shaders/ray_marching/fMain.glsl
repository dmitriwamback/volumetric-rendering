#version 410 core

uniform sampler2D position;
uniform sampler2D distanceToCamera;
uniform sampler2D normal;
uniform sampler2D albedo;
out vec4 fragc;

uniform mat4 inverseProjection;
uniform mat4 inverseLookAt;
uniform vec3 cameraPosition;
uniform vec2 screenSize;

in prop {
    vec3 normal;
    vec3 fragp;
    vec2 uv;
} fs_in;


float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p - vec3(0.0, 0.0, 2.0)) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float rayMarch(vec3 ro, vec3 rd, out vec3 hitPos) {
    float t = 0.0;
    const float maxDistance = 100.0;
    const int maxSteps = 100;
    const float epsilon = 0.001;
    vec3 boxHalfSize = vec3(1.0);

    for (int i = 0; i < maxSteps; i++) {
        vec3 p = ro + rd * t;
        float dist = sdBox(p, boxHalfSize);
        if (dist < epsilon) {
            hitPos = p;
            return t;
        }
        t += dist;
        if (t > maxDistance) break;
    }
    hitPos = vec3(0.0);
    return -1.0;
}

vec3 getRayDirection(vec2 fragCoord) {
    vec2 uv = (fragCoord.xy / screenSize) * 2.0 - 1.0;
    vec4 clip = vec4(uv, -1.0, 1.0);
    vec4 view = inverseProjection * clip;
    view.z = -1.0;
    view.w = 0.0;
    vec4 world = inverseLookAt * view;
    return normalize(world.xyz);
}


// Hash function
vec3 hash3(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Value noise
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    // Smooth interpolation
    vec3 u = f * f * (3.0 - 2.0 * f);

    // Trilinear interpolation
    return mix(
        mix(
            mix(dot(hash3(i + vec3(0, 0, 0)), f - vec3(0, 0, 0)),
                dot(hash3(i + vec3(1, 0, 0)), f - vec3(1, 0, 0)), u.x),
            mix(dot(hash3(i + vec3(0, 1, 0)), f - vec3(0, 1, 0)),
                dot(hash3(i + vec3(1, 1, 0)), f - vec3(1, 1, 0)), u.x),
            u.y),
        mix(
            mix(dot(hash3(i + vec3(0, 0, 1)), f - vec3(0, 0, 1)),
                dot(hash3(i + vec3(1, 0, 1)), f - vec3(1, 0, 1)), u.x),
            mix(dot(hash3(i + vec3(0, 1, 1)), f - vec3(0, 1, 1)),
                dot(hash3(i + vec3(1, 1, 1)), f - vec3(1, 1, 1)), u.x),
            u.y),
        u.z);
}



void main() {
    float depth = 1 - texture(distanceToCamera, fs_in.uv).w;

    vec3 rayDir = getRayDirection(gl_FragCoord.xy);
    vec3 hitPos;
    float dist = rayMarch(cameraPosition, rayDir, hitPos);

    if (dist > 0.0) {
        float d = noise(hitPos);
        if (d > 0.0) fragc = vec4(1.0, 0.5, 0.2, 0.5);
        else fragc = texture(normal, fs_in.uv);
    }
    else {
        fragc = texture(normal, fs_in.uv);
    }
    fragc.rgb = 1 - fragc.rgb;
}
