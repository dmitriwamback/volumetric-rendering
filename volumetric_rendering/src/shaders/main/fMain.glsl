#version 410 core

layout (location = 0) out vec4 fragp;
layout (location = 1) out vec4 dst;
layout (location = 2) out vec4 normal;
layout (location = 3) out vec4 fragc;

uniform vec3 cameraPosition;

in prop {
    vec3 normal;
    vec3 fragp;
} fs_in;

void main() {
    fragc = vec4(vec3(1.0), 1.0);
    fragp = vec4(fs_in.fragp, 1.0);
    normal = vec4(fs_in.normal, 1.0);

    float linearDepth = length(fs_in.fragp - cameraPosition);
    dst = vec4(linearDepth, 0.0, 0.0, 1.0);
}

