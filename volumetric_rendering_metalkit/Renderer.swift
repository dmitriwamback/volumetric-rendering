//
//  Renderer.swift
//  volumetric_rendering_metalkit
//
//  Created by Dmitri Wamback on 2025-06-14.
//

import MetalKit
import simd

class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    
    static var camera: Camera!
    static var movement: SIMD4<Float>!
    
    static var width: CGFloat!
    static var height: CGFloat!
    
    var pipelineState: MTLRenderPipelineState!
    var computePipelineState: MTLComputePipelineState!
    var outputTexture: MTLTexture!
    
    var triangle: Triangle!
    
    var uniforms: UniformBuffer!
    var uniformBuffer: MTLBuffer!
    var debugTime: Float!
    
    var depthStencilState: MTLDepthStencilState!
    
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
        metal.depthStencilPixelFormat = .depth32Float
        
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
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Int(metal.drawableSize.width),
            height: Int(metal.drawableSize.height),
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        // -------------------------------------------------------------------------------- //
        
        outputTexture = device.makeTexture(descriptor: textureDescriptor)
        
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vmain")
        let fragmentFunction = library?.makeFunction(name: "fmain")
        let volumetricCloudKernelFunction = library?.makeFunction(name: "volumetricClouds")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metal.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        Renderer.camera = Camera()
        
        uniforms = UniformBuffer(projection: Renderer.camera.projectionMatrix, lookAt: Renderer.camera.lookAtMatrix, time: 0)
        uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<UniformBuffer>.stride, options: [])
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<UniformBuffer>.stride)
        
        debugTime = 0
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            computePipelineState = try device.makeComputePipelineState(function: volumetricCloudKernelFunction!)
        }
        catch let error {
            fatalError("\(error.localizedDescription)")
        }
        
        Renderer.width = metal.frame.width
        Renderer.height = metal.frame.height
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = Renderer.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
}

extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        
        Renderer.width = view.drawableSize.width
        Renderer.height = view.drawableSize.height
        
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else { return }
            
        if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            computeEncoder.setComputePipelineState(computePipelineState)
            computeEncoder.setTexture(outputTexture, index: 0)
            
            let threadsPerThreadgroup = MTLSizeMake(8, 8, 1)
            let threadgroups = MTLSizeMake(
                (Int(Renderer.width) + 7) / 8,
                (Int(Renderer.height) + 7) / 8,
                1)
            
            computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
            computeEncoder.endEncoding()
        }

        guard let descriptor = view.currentRenderPassDescriptor else { return }
        
        descriptor.depthAttachment.texture = view.depthStencilTexture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        descriptor.depthAttachment.clearDepth = 1.0
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge

        let samplerState = Renderer.device.makeSamplerState(descriptor: samplerDescriptor)
        
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(triangle.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(outputTexture, index: 0)
        
        debugTime += 0.1
        
        Renderer.camera.update()
        
        uniforms.lookAt = Renderer.camera.lookAtMatrix
        uniforms.projection = Renderer.camera.projectionMatrix
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<UniformBuffer>.stride)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36)
        
        renderEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else { return }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
