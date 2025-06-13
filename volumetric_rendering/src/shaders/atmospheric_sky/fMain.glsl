//
//  fMain.glsl
//  volumetric_rendering
//
//  Created by Dmitri Wamback on 2025-06-13.
//

#version 410 core

// ----- G-BUFFER TEXTURES ----- //
uniform sampler2D position;
uniform sampler2D distanceToCamera;
uniform sampler2D normal;
uniform sampler2D albedo;

// ----- 3D Noise Texture ----- //
uniform sampler3D noiseTexture;

// ----- Output Color ----- //
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

// ----- Cloud Box ----- //

vec3 zenithColor = vec3(0.05, 0.15, 0.4);
vec3 horizonColor = vec3(0.6, 0.7, 0.9);
vec3 groundColor = vec3(0.4, 0.35, 0.3);

// ----------------------------------------------------------- //
// ----------------------------------------------------------- //

vec3 computeRayDirection(vec2 fragp) {
    vec2 uv = (fragp / screenSize) * 2.0 - 1.0;
    vec4 clip = vec4(uv, -1.0, 1.0);
    vec4 view = inverseProjection * clip;
    view.z = -1.0;
    view.w = 0.0;
    vec4 world = inverseLookAt * view;
    return normalize(world.xyz);
}

// ----------------------------------------------------------- //
// ----------------------------------------------------------- //

void main() {
    
    vec2 uv = gl_FragCoord.xy;
    float depth = texture(distanceToCamera, uv / screenSize).r;

    if (depth <= 0.0001) {
        vec3 viewDir = computeRayDirection(gl_FragCoord.xy);
        float y = viewDir.y;

        vec3 skyColor;
        if (y > 0.0) {
            float t = pow(y, 0.65);
            skyColor = mix(horizonColor, zenithColor, t);
        } else {
            float t = pow(-y, 0.7);
            skyColor = mix(horizonColor, groundColor, t);
        }

        fragc = vec4(skyColor, 1.0);
    }
    else {
        fragc = texture(normal, fs_in.uv);
    }
}
