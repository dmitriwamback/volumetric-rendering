#version 410 core

uniform sampler2D position;
uniform sampler2D distanceToCamera;
uniform sampler2D normal;
uniform sampler2D albedo;
uniform sampler3D noiseTexture;
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


vec3 boxPosition = vec3(0, 0, -4.0);
vec3 boxMin = boxPosition - vec3(2.0, 2.0, 2.0) * 1;
vec3 boxMax = boxPosition + vec3(2.0, 2.0, 2.0) * 1;

bool intersectBox(vec3 ro, vec3 rd, out float tNear, out float tFar) {
    vec3 invDir = 1.0 / rd;
    vec3 t0s = (boxMin - ro) * invDir;
    vec3 t1s = (boxMax - ro) * invDir;

    vec3 tsmaller = min(t0s, t1s);
    vec3 tbigger = max(t0s, t1s);

    tNear = max(max(tsmaller.x, tsmaller.y), tsmaller.z);
    tFar = min(min(tbigger.x, tbigger.y), tbigger.z);

    return tFar >= max(tNear, 0.0);
}

float rayMarch(vec3 ro, vec3 rd, out vec3 hitPos) {

    float tNear, tFar;
    if (!intersectBox(ro, rd, tNear, tFar)) {
        hitPos = vec3(0.0);
        return -1.0;
    }

    float t = max(tNear, 0.0);
    float stepSize = 0.01;

    while (t < tFar) {
        vec3 p = ro + rd * t;
        vec3 localP = p + vec3(0.0, 0.0, 2.0);
        vec3 texCoord = (p - boxMin) / (boxMax - boxMin);

        float n = texture(noiseTexture, texCoord).r;
        
        if (n < 0.5) {
            t += stepSize;
            continue;
        }

        float band = 0.05;
        float density = smoothstep(0.5 - band, 0.5 + band, n);

        if (density > 0.5) {
            hitPos = p;
            return t;
        }
        t += stepSize;
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


void main() {
    float depth = texture(distanceToCamera, fs_in.uv).w;
    vec3 rayDir = getRayDirection(gl_FragCoord.xy);
    vec3 hitPos;
    float dist = rayMarch(cameraPosition, rayDir, hitPos);

    vec4 viewHit = inverseLookAt * vec4(hitPos, 1.0);
    float rayDepth = -viewHit.z;

    if (dist > 0.0) {
        float n = 1;
        fragc = vec4(vec3(hitPos.y + 2)/4.0 * n, 1.0);
    }
    else {
        fragc = texture(normal, fs_in.uv);
    }
}
