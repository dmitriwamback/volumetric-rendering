//
//  vMain.glsl
//  volumetric_rendering
//
//  Created by Dmitri Wamback on 2025-06-13.
//

#version 410 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec2 uv;

uniform mat4 projection;
uniform mat4 lookAt;
uniform mat4 model;

out prop {
    vec3 normal;
    vec3 fragp;
    vec2 uv;
} vs_out;

void main() {
    vs_out.normal = normalize(transpose(inverse(mat3(model))) * normal);
    vs_out.fragp = vec3(model * vec4(position, 1.0));
    vs_out.uv = uv;

    gl_Position = vec4(position.xy, 0.0, 1.0);
    gl_PointSize = 20.0;
}
