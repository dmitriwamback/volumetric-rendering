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

vertex float4 vmain(const inVertex invertex [[ stage_in ]]) {
    return invertex.position;
}

fragment half4 fmain() {
    return half4(1.0);
}
