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
            inVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 0)),
            
            // Back face
            inVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3( 0,  0, -1), uv: SIMD2(0, 0)),
            
            // Right face
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 1,  0,  0), uv: SIMD2(0, 0)),
            
            // Left face
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(-1,  0,  0), uv: SIMD2(0, 0)),
            
            // Top face
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3( 0,  1,  0), uv: SIMD2(0, 0)),
            
            // Bottom face
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3( 0, -1,  0), uv: SIMD2(0, 0)),
        ]
        
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: MemoryLayout<inVertex>.stride * vertices.count, options: [])
    }
}
