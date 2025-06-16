//
//  shaders.metal
//  volumetric_rendering_metalkit
//
//  Created by Dmitri Wamback on 2025-06-14.
//
#include <metal_stdlib>
using namespace metal;

struct inVertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

struct outVertex {
    float4 position [[position]];
    float3 normal;
    float2 uv;
};

struct Uniforms {
    float4x4 projection;
    float4x4 lookAt;
    float time;
};

struct GBufferOut {
    float4 position [[position]];
    float3 worldPos;
    float3 normal;
    float2 uv;
};

struct GBufferOutFragment {
    float4 fragp [[color(0)]];
    float4 normal [[color(1)]];
    float4 albedo [[color(2)]];
};

vertex outVertex vmain(uint vertexID [[vertex_id]], constant inVertex *vertexArray [[buffer(0)]], constant Uniforms& uniforms [[buffer(1)]]) {
    
    outVertex out;
    
    inVertex vert = vertexArray[vertexID];

    out.position    = float4(vert.position.xy, 0.0, 1.0);
    out.normal      = vert.normal.xyz;
    out.uv          = vert.uv;
    
    return out;
}

fragment float4 fmain(outVertex in [[stage_in]], texture2d<float> inTexture [[texture(0)]], sampler inSampler [[sampler(0)]]) {
    float4 t = inTexture.sample(inSampler, float2(in.uv.x, 1 - in.uv.y));
    return float4(t.rgb, 1.0);
}


vertex GBufferOut vgbuffer(
    uint vertexID [[vertex_id]], constant inVertex *vertexArray [[buffer(0)]],
    constant Uniforms& uniforms [[buffer(1)]]) {
    
    inVertex vert = vertexArray[vertexID];
    GBufferOut out;
    
    float4 world    = uniforms.lookAt * float4(vert.position, 1.0);
    out.position    = uniforms.projection * world;
    out.worldPos    = world.xyz;
    out.normal      = vert.normal;
    out.uv          = vert.uv;
    
    return out;
}

fragment GBufferOutFragment fgbuffer(GBufferOut in [[stage_in]]) {
    GBufferOutFragment out;
    out.fragp   = float4(in.worldPos, 1.0);
    out.normal  = float4(normalize(in.normal), 1.0);
    out.albedo  = float4(1.0, 0.5, 0.2, 1.0);
    return out;
}


kernel void volumetricClouds(texture2d<float, access::write> output [[texture(0)]],
                             texture2d<float, access::sample> albedo [[texture(1)]],
                             texture2d<float, access::sample> normal [[texture(2)]],
                             texture2d<float, access::sample> fragp [[texture(3)]],
                             sampler inSampler [[sampler(0)]],
                             uint2 gid [[thread_position_in_grid]]) {
    
    uint2 size = uint2(output.get_width(), output.get_height());
    float2 uv = float2(gid) / float2(size);
    
    float4 _albedo = albedo.sample(inSampler, uv);
        
    if (gid.x >= size.x || gid.y >= size.y) {
        return;
    }
    
    output.write(_albedo, gid);
}
