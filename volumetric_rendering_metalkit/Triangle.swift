//
//  Triangle.swift
//  volumetric_rendering_metalkit
//
//  Created by Dmitri Wamback on 2025-06-14.
//

import simd
import Metal
import MetalKit

class Triangle {
    
    var vertices: [inVertex]!
    var vertexBuffer: MTLBuffer!
    
    init() {
        vertices = [
            inVertex(position: SIMD4<Float>( 0  , 0.5, 0, 1)),
            inVertex(position: SIMD4<Float>( 0.5,-0.5, 0, 1)),
            inVertex(position: SIMD4<Float>(-0.5,-0.5, 0, 1))
        ]
        
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: MemoryLayout<inVertex>.stride * vertices.count, options: [])
    }
}
