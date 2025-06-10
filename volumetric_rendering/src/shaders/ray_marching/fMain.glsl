#version 410 core

uniform sampler2D position;
uniform sampler2D distanceToCamera;
uniform sampler2D normal;
uniform sampler2D albedo;
out vec4 fragc;

in prop {
    vec3 normal;
    vec3 fragp;
    vec2 uv;
} fs_in;


void main() {
    
    float depth = 1 - texture(distanceToCamera, fs_in.uv).w;
    fragc = texture(albedo, fs_in.uv);
    fragc.rgb = 1 - fragc.rgb;
}
