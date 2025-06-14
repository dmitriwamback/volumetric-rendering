//
//  shaders.metal
//  volumetric_rendering_metalkit
//
//  Created by Dmitri Wamback on 2025-06-14.
//
#include <metal_stdlib>
using namespace metal;

struct inVertex {
    float4 position [[attribute(0)]];
};

struct Uniforms {
    float4x4 projection;
    float4x4 lookAt;
    float time;
};

vertex float4 vmain(const inVertex invertex [[ stage_in ]], constant Uniforms& uniforms [[buffer(1)]]) {
    return uniforms.projection * uniforms.lookAt * float4(invertex.position.xyz, 1.0);
}

kernel void volumetricClouds(texture2d<float, access::write> output [[texture(0)]], uint2 gid [[thread_position_in_grid]]) {
    
}

fragment half4 fmain() {
    return half4(1.0, 1.0, 0.8, 1.0);
}
