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
    float4x4 inverseProjection;
    float4x4 inverseLookAt;
    float3 cameraPosition;
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


vertex GBufferOut vgbuffer(uint vertexID [[vertex_id]], constant inVertex *vertexArray [[buffer(0)]], constant Uniforms& uniforms [[buffer(1)]]) {
    
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
    out.albedo  = float4(1.0, 1.0, 1.0, 1.0);
    return out;
}




constant float3 boxPosition = float3(0.0, 0.0, -10.0);
constant float3 halfSize = float3(2.0, 2.0, 2.0);
constant float3 boxMin = boxPosition - halfSize;
constant float3 boxMax = boxPosition + halfSize;

constant float3 cloudAmbient = float3(0.2, 0.3, 0.6);

constant float3 zenithColor = float3(0.05, 0.15, 0.4);
constant float3 horizonColor = float3(0.6, 0.7, 0.9);
constant float3 groundColor = float3(0.4, 0.35, 0.3);


bool intersectBox(float3 RO, float3 RD, thread float* tNear, thread float* tFar) {
    float3 inverseDirection = 1.0 / RD;
    float3 t0 = (boxMin - RO) * inverseDirection;
    float3 t1 = (boxMax - RO) * inverseDirection;
    
    float3 tmin = min(t0, t1);
    float3 tmax = max(t0, t1);
    
    float near = max(max(tmin.x, tmin.y), tmin.z);
    float far = min(min(tmax.x, tmax.y), tmax.z);
    
    *tNear = near;
    *tFar  = far;
    
    return far >= max(near, 0.0);
}


//float rayMarch(float3 rayOrigin, float3 rayDirection, thread float3* hitPosition, thread float3* cloudColor) {
//
//}



float3 computeRayDirection(float2 fragp, float4x4 inverseProjection, float4x4 inverseLookAt) {
    
    float2 uv = fragp * 2.0 - 1.0;
    float4 clip = float4(uv, -1.0, 1.0);
    float4 view = inverseProjection * clip;
    view.z = -1.0;
    view.w = 0;
    float4 world = inverseLookAt * view;
    return normalize(world.xyz);
}

kernel void volumetricClouds(constant Uniforms& uniforms [[buffer(0)]],
                             texture2d<float, access::write> output [[texture(0)]],
                             texture2d<float, access::sample> albedo [[texture(1)]],
                             texture2d<float, access::sample> normal [[texture(2)]],
                             texture2d<float, access::sample> fragp [[texture(3)]],
                             sampler inSampler [[sampler(0)]],
                             uint2 gid [[thread_position_in_grid]]) {
    
    uint2 size = uint2(output.get_width(), output.get_height());
        
    if (gid.x >= size.x || gid.y >= size.y) {
        return;
    }
    
    float2 uv = float2(gid) / float2(size);
    uv.y = 1 - uv.y;
    
    float3 ray = computeRayDirection(uv, uniforms.inverseProjection, uniforms.inverseLookAt);
    float y = ray.y;
    
    float3 skyColor;
    if (y > 0.0) {
        float t = pow(y, 0.65);
        skyColor = mix(horizonColor, zenithColor, t);
    }
    else {
        float t = pow(-y, 0.7);
        skyColor = mix(horizonColor, groundColor, t);
    }
    
    float4 _albedo = float4(skyColor, 1.0);
    
    float tNear = 0, tFar = 0;
    if (intersectBox(uniforms.cameraPosition, ray, &tNear, &tFar)) {
        _albedo = float4(1.0, 1.0, 1.0, 1.0);
    }
    
    
    //_albedo = albedo.sample(inSampler, uv);
    
    
    
    output.write(_albedo, gid);
}
