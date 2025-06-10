#version 410 core

out vec4 fragc;

in prop {
    vec3 normal;
    vec3 fragp;
} fs_in;


void main() {
    fragc = vec4(1.0);
}

