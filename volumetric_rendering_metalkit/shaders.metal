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

constant half3 cloudAmbient = half3(0.2h, 0.3h, 0.6h);

constant half3 zenithColor  = half3(0.05h, 0.15h, 0.4h);
constant half3 horizonColor = half3(0.6h, 0.7h, 0.9h);
constant half3 groundColor  = half3(0.4h, 0.35h, 0.3h);


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

half phaseSchlick(half cosTheta, half k) {
    cosTheta = clamp(cosTheta, -1.0h, 1.0h);
    k = clamp(k, 0.0h, 0.999h);
    
    half denom = 1.0h + k * (k - 2.0h * cosTheta);
    denom = max(denom, 0.001h);
    
    half result = (1.0h - k * k) / (4.0h * 3.141592h * pow(denom, 1.5h));
    return max(result, 1.0h);
}

float computeLightTransmittance(float3 p, float3 lightDirection, texture3d<float> noiseTexture, sampler _sampler) {
    float t = 0.0;
    float attenuation = 0.0;
    const float stepSize = 0.02;
    
    for (int i = 0; i < 16; i++) {
        float3 samplePos = p + lightDirection * t;
        float3 uv = (samplePos - boxMin) / (boxMax - boxMin);
        if (any(uv < float3(0.0)) || any(uv > float3(1.0)))
            break;

        float sampledNoise = half(noiseTexture.sample(_sampler, uv).r);
        float localDensity = clamp(pow(sampledNoise, 2.4) * 1.2 - 0.2, 0.0, 1.0);
        attenuation += localDensity * stepSize;
        t += stepSize;
    }

    return exp(-attenuation * 10.1);
}

float rayMarch(float3 rayOrigin, float3 rayDirection, thread float3* hitPosition, thread float3* cloudColor, texture3d<float> noiseTexture, sampler _sampler) {
    
    float tNear, tFar;
    if (!intersectBox(rayOrigin, rayDirection, &tNear, &tFar)) {
        *hitPosition = float3(0.0);
        *cloudColor = float3(0.0);
        return -1.0;
    }
    
    // Constants
    constexpr float stepSize = 0.05;
    constexpr float k = 0.5;
    float3 lightDirection = normalize(float3(1.0, 1.0, 0.5));
    
    int maxSteps = int(min(128.0, (tFar - tNear) / stepSize));
    float t = max(tNear, 0.0) + 0.0001;
    float opacity = 0.0;
    half3 color = half3(0.0);
    
    for (int i = 0; i < maxSteps && t < tFar; ++i) {
        
        float3 rayPosition = rayOrigin + rayDirection * t;
        
        half3 uv = half3((rayPosition - boxPosition) / halfSize) * 0.5h + 0.5h;
        
        if (any(uv < half3(0.0)) || any(uv > half3(1.0))) {
            t += stepSize;
            continue;
        }
        
        constexpr half margin = 0.1;
        half fadeX = smoothstep(0.0h, margin, uv.x) * (1.0h - smoothstep(1.0h - margin, 1.0h, uv.x));
        half fadeY = smoothstep(0.0h, margin, uv.y) * (1.0h - smoothstep(1.0h - margin, 1.0h, uv.y));
        half fadeZ = smoothstep(0.0h, margin, uv.z) * (1.0h - smoothstep(1.0h - margin, 1.0h, uv.z));
        half edgeFade = fadeX * fadeY * fadeZ;
        
        half sampledNoise = noiseTexture.sample(_sampler, float3(uv)).r;
        
        half density = clamp(pow(sampledNoise, 2.0h) * 3.0 - 0.2, 0.0, 1.0);
        density *= edgeFade * 2.5;
        
        if (density < 0.1) {
            t += stepSize * 2.0;
            continue;
        }
        
        half transmittance = computeLightTransmittance(rayPosition, lightDirection, noiseTexture, _sampler);
        half cosTheta = dot(rayDirection, lightDirection);
        half phase = phaseSchlick(cosTheta, k);
        
        half3 lightColor = half3(1.0h);
        half3 ambient = cloudAmbient * density;
        half3 scatter = lightColor * transmittance * phase * density + ambient;
        
        color += (1.0 - opacity) * scatter * stepSize;
        opacity += (1.0 - opacity) * density * stepSize;
        
        if (opacity >= 0.99) {
            break;
        }
        
        t += stepSize;
    }
    
    if (opacity > 0.0) {
        *hitPosition = rayOrigin + rayDirection * t;
        *cloudColor = float3(color) * 1.75;
        return opacity;
    } else {
        *hitPosition = float3(0.0);
        *cloudColor = float3(0.0);
        return -1.0;
    }
}



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
                             texture3d<float, access::sample> noiseTexture [[texture(4)]],
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
    
    half3 skyColor;
    if (y > 0.0) {
        float t = pow(y, 0.65);
        skyColor = mix(horizonColor, zenithColor, t);
    }
    else {
        float t = pow(-y, 0.7);
        skyColor = mix(horizonColor, groundColor, t);
    }
    
    half4 _albedo = half4(skyColor, 1.0);
    
    float tNear = 0, tFar = 0;
    if (!intersectBox(uniforms.cameraPosition, ray, &tNear, &tFar)) {
        output.write(float4(_albedo), gid);
        return;
    }
    
    float3 hitPosition, cloudColor;
    float opacity = rayMarch(uniforms.cameraPosition, ray, &hitPosition, &cloudColor, noiseTexture, inSampler);
    
    half3 background = _albedo.rgb;
        
    half3 toneMappedCloud = half3(cloudColor) / (half3(cloudColor) + half3(1.0h));
    toneMappedCloud = pow(toneMappedCloud, half3(1.0 / 2.2));

    _albedo = (opacity > 0.0) ? half4(mix(background, toneMappedCloud, opacity), 1.0) : half4(background, 1.0);
    
    output.write(float4(_albedo), gid);
}
