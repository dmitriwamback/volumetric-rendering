//
//  Renderer.swift
//  volumetric_rendering_metalkit
//
//  Created by Dmitri Wamback on 2025-06-14.
//

import MetalKit

class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    var mesh: MTKMesh!
    var pipelineState: MTLRenderPipelineState!
    var triangle: Triangle!
    var uniformBuffer: MTLBuffer!
    
    init (metal: MTKView) {
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Couldn't create MTLDevice")
        }
        metal.device = device
        Renderer.device = device
        Renderer.commandQueue = device.makeCommandQueue()
        
        super.init()
        
        metal.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metal.delegate = self
        
        triangle = Triangle()
        
        // -------------------------------------------------------------------------------- //
        
        let vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.layouts[0].stride = MemoryLayout<inVertex>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // -------------------------------------------------------------------------------- //
        
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vmain")
        let fragmentFunction = library?.makeFunction(name: "fmain")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metal.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch let error {
            fatalError("\(error.localizedDescription)")
        }
    }
}

extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(triangle.vertexBuffer, offset: 0, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
