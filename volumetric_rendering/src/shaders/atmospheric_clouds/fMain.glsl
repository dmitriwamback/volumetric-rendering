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
vec3 boxPosition = vec3(0.0, 0.0, -10.0);
vec3 halfSize = vec3(2.0, 2.0, 2.0) * 2.25;
vec3 boxMin = boxPosition - halfSize;
vec3 boxMax = boxPosition + halfSize;

vec3 cloudAmbient = vec3(0.2, 0.3, 0.6);


vec3 zenithColor = vec3(0.05, 0.15, 0.4);
vec3 horizonColor = vec3(0.6, 0.7, 0.9);
vec3 groundColor = vec3(0.4, 0.35, 0.3);


// ----------------------------------------------------------- //
// ----------------------------------------------------------- //

// Ray-box signed distance function for the clouds //
bool intersectBox(vec3 RO, vec3 RD, out float tNear, out float tFar) {
    vec3 inverseDirection = 1.0 / RD;
    vec3 t0 = (boxMin - RO) * inverseDirection;
    vec3 t1 = (boxMax - RO) * inverseDirection;

    vec3 tmin = min(t0, t1);
    vec3 tmax = max(t0, t1);

    tNear = max(max(tmin.x, tmin.y), tmin.z);
    tFar  = min(min(tmax.x, tmax.y), tmax.z);

    return tFar >= max(tNear, 0.0);
}


float phaseSchlick(float cosTheta, float k) {
    cosTheta = clamp(cosTheta, -1.0, 1.0);

    k = clamp(k, 0.0, 0.999);

    float denom = 1.0 + k * (k - 2.0 * cosTheta);
    denom = max(denom, 0.001);

    float result = (1.0 - k * k) / (4.0 * 3.141592 * pow(denom, 1.5));

    return max(result, 1.0);
}

// ----------------------------------------------------------- //
// ----------------------------------------------------------- //

// Compute the light from a point in the cloud
float computeLightTransmittance(vec3 p, vec3 lightDirection) {
    float t = 0.0;
    float attenuation = 0.0;
    const float stepSize = 0.05;
    
    // use ray marching to calculate the attenuation
    for (int i = 0; i < 16; ++i) {
        vec3 samplePos = p + lightDirection * t;
        vec3 uv = (samplePos - boxMin) / (boxMax - boxMin);
        if (any(lessThan(uv, vec3(0.0))) || any(greaterThan(uv, vec3(1.0))))
            break;

        float sampledNoise = texture(noiseTexture, uv).r;
        float localDensity = clamp(pow(sampledNoise, 1.4) * 1.2 - 0.2, 0.0, 1.0);
        attenuation += localDensity * stepSize;
        t += stepSize;
    }

    return exp(-attenuation * 10.1);
}

// ----------------------------------------------------------- //
// ----------------------------------------------------------- //

// Main ray marching function
float rayMarch(vec3 rayOrigin, vec3 rayDirection, out vec3 hitPosition, out vec3 cloudColor) {
    
    // Get the closest and farthest points in the imaginary cube
    float tNear, tFar;
    if (!intersectBox(rayOrigin, rayDirection, tNear, tFar)) {
        hitPosition = vec3(0.0);
        cloudColor = vec3(0.0);
        return -1.0;
    }
    
    // Constants
    const float stepSize = 0.05;
    const float k = 0.5;
    const vec3 lightDirection = normalize(vec3(1.0, 1.0, 0.5));
    
    int maxSteps = int(min(128.0, (tFar - tNear) / stepSize));
    float t = max(tNear, 0.0);
    float opacity = 0.0;
    vec3 color = vec3(0.0);
    
    // Iterate through all steps
    for (int i = 0; i < maxSteps && t < tFar; ++i) {
        
        // Get ray information and texture coordinates
        vec3 rayPosition = rayOrigin + rayDirection * t;
        vec3 uv = ((rayPosition - boxPosition) / halfSize) * 0.5 + 0.5;
        
        if (any(lessThan(uv, vec3(0.0))) || any(greaterThan(uv, vec3(1.0)))) {
            t += stepSize;
            continue;
        }
        
        // Sample the from the 3D noise (Voronoi noise + Layered noise)
        float sampledNoise = texture(noiseTexture, uv).r;

        
        float margin = 0.1;

        float fadeX = smoothstep(0.0, margin, uv.x) * (1.0 - smoothstep(1.0 - margin, 1.0, uv.x));
        float fadeY = smoothstep(0.0, margin, uv.y) * (1.0 - smoothstep(1.0 - margin, 1.0, uv.y));
        float fadeZ = smoothstep(0.0, margin, uv.z) * (1.0 - smoothstep(1.0 - margin, 1.0, uv.z));

        float edgeFade = fadeX * fadeY * fadeZ;

        float radialFalloff = 1.0;

        float density = clamp(pow(sampledNoise, 2.0) * 3.0 - 0.2, 0.0, 1.0);
        density *= edgeFade * 2.5;
        
        if (density < 0.01) {
            t += stepSize * 2.0;
            continue;
        }
        
        // Calculate the light penetrating the clouds
        float transmittance = computeLightTransmittance(rayPosition, lightDirection);
        float cosTheta = dot(rayDirection, lightDirection);
        float phase = phaseSchlick(cosTheta, k);
        
        // Calculate scatter color and opacity
        vec3 lightColor = vec3(1.0);
        
        vec3 ambient = cloudAmbient * density;
        vec3 scatter = lightColor * transmittance * phase * density + ambient;
        
        color += (1.0 - opacity) * scatter * stepSize;
        opacity += (1.0 - opacity) * density * stepSize;

        if (opacity >= 0.99) break;
        t += stepSize;
    }
    
    if (opacity > 0.0) {
        hitPosition = rayOrigin + rayDirection * t;
        cloudColor = color * 1.75;
        return opacity;
    }
    else {
        hitPosition = vec3(0.0);
        cloudColor = vec3(0.0);
        return -1.0;
    }
}

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
    vec3 rayDirection = computeRayDirection(gl_FragCoord.xy);
    
    vec2 uv = gl_FragCoord.xy;
    float depth = texture(distanceToCamera, uv / screenSize).r;

    vec3 viewDir = computeRayDirection(gl_FragCoord.xy);
    float y = viewDir.y;

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

    float tNear, tFar;
        
    if (!intersectBox(cameraPosition, rayDirection, tNear, tFar)) {
        fragc += texture(normal, fs_in.uv);
        return;
    }
    
    vec3 hitPosition, cloudColor;
    float opacity = rayMarch(cameraPosition, rayDirection, hitPosition, cloudColor);

    vec3 background = fragc.rgb;
    
    vec3 toneMappedCloud = cloudColor / (cloudColor + vec3(1.0));
    toneMappedCloud = pow(toneMappedCloud, vec3(1.0 / 2.2));

    fragc = (opacity > 0.0) ? vec4(mix(background, toneMappedCloud, opacity), 1.0) : vec4(background, 1.0);
}
