  
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Hash function for random cell points
float2 hash2(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)),
               dot(p, float2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453123);
}

// Simplex noise for subtle surface variation
float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
float2 mod289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
float3 permute(float3 x) { return mod289(((x * 34.0) + 1.0) * x); }

float snoise(float2 v) {
    const float4 C = float4(0.211324865405187, 0.366025403784439,
                            -0.577350269189626, 0.024390243902439);
    float2 i  = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
    float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m * m; m = m * m;
    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
    float3 g;
    g.x  = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// Smooth Voronoi — returns (distance to edge, distance to center)
float2 voronoi(float2 uv) {
    float2 n = floor(uv);
    float2 f = fract(uv);

    float distToCenter = 8.0;
    float distToEdge = 8.0;
    float2 closestPoint = float2(0.0);

    // Find closest cell center
    for (int j = -2; j <= 2; j++) {
        for (int i = -2; i <= 2; i++) {
            float2 g = float2(float(i), float(j));
            float2 o = hash2(n + g);
            // Jitter the cell points with some organic randomness
            o = 0.5 + 0.5 * sin(6.2831 * o + 0.5);
            float2 delta = g + o - f;
            float d = dot(delta, delta);
            if (d < distToCenter) {
                distToCenter = d;
                closestPoint = delta;
            }
        }
    }
    distToCenter = sqrt(distToCenter);

    // Find distance to nearest cell edge
    for (int j = -2; j <= 2; j++) {
        for (int i = -2; i <= 2; i++) {
            float2 g = float2(float(i), float(j));
            float2 o = hash2(n + g);
            o = 0.5 + 0.5 * sin(6.2831 * o + 0.5);
            float2 delta = g + o - f;
            if (dot(delta - closestPoint, delta - closestPoint) > 0.001) {
                float2 midpoint = 0.5 * (closestPoint + delta);
                float2 edgeDir = normalize(delta - closestPoint);
                float edgeDist = dot(midpoint, edgeDir);
                distToEdge = min(distToEdge, edgeDist);
            }
        }
    }

    return float2(distToEdge, distToCenter);
}

[[ stitchable ]]
half4 velvetTexture(float2 position, half4 color, float2 size,
                    float scale, float intensity, float napBias) {
    float2 uv = position / size;

    // Scale UV for pebble density
    float2 st = uv * scale;

    // Add organic warping so pebbles aren't on a perfect grid
    float warp = snoise(uv * scale * 0.3) * 0.4;
    st += float2(warp, snoise(uv * scale * 0.25 + 50.0) * 0.4);

    float2 v = voronoi(st);
    float edgeDist = v.x;
    float centerDist = v.y;

    // Create the groove (dark channel between pebbles)
    float groove = smoothstep(0.0, 0.12, edgeDist);

    // Create rounded pebble bump — raised center, falling off at edges
    float bump = smoothstep(0.0, 0.5, edgeDist);

    // Soft highlight on top of each pebble (simulate light from above)
    float highlight = smoothstep(0.45, 0.05, centerDist) * 0.4;

    // Combine: darken grooves, add subtle highlight on pebble tops
    float shading = mix(-intensity * 1.8, 0.0, groove)  // groove darkening
                  + bump * intensity * 0.3                // edge-to-center gradient
                  + highlight * intensity;                // center highlight

    // Add very fine fiber noise on top for fabric feel
    float fiber = snoise(uv * scale * 8.0) * intensity * 0.15;

    float total = shading + fiber;

    return half4(color.rgb + half3(total), color.a);
}
