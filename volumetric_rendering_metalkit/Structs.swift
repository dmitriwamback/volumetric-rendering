//
//  Structs.swift
//  volumetric_rendering_metalkit
//
//  Created by Dmitri Wamback on 2025-06-14.
//

import simd

struct inVertex {
    var position: SIMD4<Float>
}

struct UniformBuffer {
    var projection: simd_float4x4
    var lookAt: simd_float4x4
    var time: Float
}
