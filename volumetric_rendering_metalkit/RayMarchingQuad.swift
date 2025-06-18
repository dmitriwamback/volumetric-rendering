//
//  RayMarchingQuad.swift
//  volumetric_rendering_metalkit
//
//  Created by Dmitri Wamback on 2025-06-16.
//

import simd
import Metal
import MetalKit

class RayMarchingQuad {
    
    var vertices: [inVertex]!
    var vertexBuffer: MTLBuffer!
    var cloudNoiseTexture: MTLTexture!
    
    init() {
        vertices = [
            inVertex(position: SIMD3(-1.0,  1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 1)),
            inVertex(position: SIMD3( 1.0,  1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3(-1.0, -1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 0)),
            inVertex(position: SIMD3( 1.0,  1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 1)),
            inVertex(position: SIMD3( 1.0, -1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(1, 0)),
            inVertex(position: SIMD3(-1.0, -1.0,  0.0), normal: SIMD3( 0,  0,  1), uv: SIMD2(0, 0)),
        ]
        
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: MemoryLayout<inVertex>.stride * vertices.count, options: [])
        
        let size = 128
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type3D
        textureDescriptor.pixelFormat = .rgba32Float
        textureDescriptor.width = size
        textureDescriptor.height = size
        textureDescriptor.depth = size
        textureDescriptor.usage = [.shaderRead]
        
        var noiseData = [Float](repeating: 0.0, count: size * size * size * 4)
        let frequency: Float = 0.00421
        
        let seed = Float.random(in: 0...20000000)
        
        cloudNoiseTexture = Renderer.device.makeTexture(descriptor: textureDescriptor)
        
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let index = (x * size * size + y * size + z) * 4
                    
                    let noiseValue = layeredNoise3D(x: (Float(x)+seed)*frequency, y: (Float(y)+seed)*frequency, lacunarity: 1.5, persistance: 0.7, octaves: 10, seed: (Float(z)+seed)*frequency)
                    
                    noiseData[index + 0] = noiseValue
                    noiseData[index + 1] = noiseValue
                    noiseData[index + 2] = noiseValue
                    noiseData[index + 3] = 1.0
                }
            }
        }
        
        let region = MTLRegionMake3D(0, 0, 0, size, size, size)
        let bytesPerRow = size * MemoryLayout<Float>.stride * 4
        let bytesPerImage = bytesPerRow * size

        noiseData.withUnsafeBytes { ptr in
            cloudNoiseTexture.replace(region: region,
                                      mipmapLevel: 0,
                                      slice: 0,
                                      withBytes: ptr.baseAddress!,
                                      bytesPerRow: bytesPerRow,
                                      bytesPerImage: bytesPerImage)
        }
    }
}
