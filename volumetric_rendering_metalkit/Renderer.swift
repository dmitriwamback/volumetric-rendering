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
    
    // ----- CAMERA ----- //
    static var camera: Camera!
    static var movement: SIMD4<Float>!
    
    static var width: CGFloat!
    static var height: CGFloat!
    
    // ----- PIPELINE ----- //
    var pipelineState: MTLRenderPipelineState!
    var gBufferPipelineState: MTLRenderPipelineState!
    var computePipelineState: MTLComputePipelineState!
    var outputTexture: MTLTexture!
    
    var cube: Cube!
    var rayMarchingQuad: RayMarchingQuad!
    
    // ----- UNIFORMS ----- //
    var uniforms: UniformBuffer!
    var uniformBuffer: MTLBuffer!
    var debugTime: Float!
    
    // ----- GBUFFER ----- //
    var gPosition: MTLTexture!
    var gNormal: MTLTexture!
    var gAlbedo: MTLTexture!
    var depthTexture: MTLTexture!
    
    var depthStencilState: MTLDepthStencilState!
    
    init (metal: MTKView) {
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Couldn't create MTLDevice")
        }
        metal.device = device
        Renderer.device = device
        Renderer.commandQueue = device.makeCommandQueue()
        Renderer.width = metal.frame.width
        Renderer.height = metal.frame.height
                
        super.init()
        
        metal.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metal.delegate = self
        metal.depthStencilPixelFormat = .depth32Float
        
        cube = Cube()
        rayMarchingQuad = RayMarchingQuad()
        
        // -------------------------------------------------------------------------------- //
        
        createGBufferTextures()
        
        // -------------------------------------------------------------------------------- //
        
        let vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.attributes[0].format = .float4 // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float3 // normal
        vertexDescriptor.attributes[1].offset = MemoryLayout<float4>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.attributes[2].format = .float2 // uv
        vertexDescriptor.attributes[2].offset = MemoryLayout<float4>.stride + MemoryLayout<float3>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<inVertex>.stride
        
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
        let gbufferVertexFunction = library?.makeFunction(name: "vgbuffer")
        let gbufferFragmentFunction = library?.makeFunction(name: "fgbuffer")

        let gBufferDescriptor = MTLRenderPipelineDescriptor()
        gBufferDescriptor.vertexFunction = gbufferVertexFunction
        gBufferDescriptor.fragmentFunction = gbufferFragmentFunction
        gBufferDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        gBufferDescriptor.colorAttachments[1].pixelFormat = .rgba16Float
        gBufferDescriptor.colorAttachments[2].pixelFormat = .rgba16Float
        gBufferDescriptor.vertexDescriptor = vertexDescriptor
        gBufferDescriptor.depthAttachmentPixelFormat = .depth32Float

        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metal.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        Renderer.camera = Camera()
        
        uniforms = UniformBuffer(projection: Renderer.camera.projectionMatrix,
                                 lookAt: Renderer.camera.lookAtMatrix,
                                 inverseProjection: Renderer.camera.projectionMatrix.inverse,
                                 inverseLookAt: Renderer.camera.lookAtMatrix.inverse,
                                 cameraPosition: Renderer.camera.position,
                                 time: 0)
        uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<UniformBuffer>.stride, options: [])
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<UniformBuffer>.stride)
        
        debugTime = 0
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            computePipelineState = try device.makeComputePipelineState(function: volumetricCloudKernelFunction!)
            gBufferPipelineState = try device.makeRenderPipelineState(descriptor: gBufferDescriptor)
        }
        catch let error {
            fatalError("\(error.localizedDescription)")
        }
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = Renderer.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func createGBufferTextures() {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: Int(Renderer.width),
            height: Int(Renderer.height),
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]

        gPosition = Renderer.device.makeTexture(descriptor: descriptor)
        gNormal = Renderer.device.makeTexture(descriptor: descriptor)
        gAlbedo = Renderer.device.makeTexture(descriptor: descriptor)

        let depthDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: Int(Renderer.width),
            height: Int(Renderer.height),
            mipmapped: false
        )
        depthDesc.usage = [.renderTarget]
        depthTexture = Renderer.device.makeTexture(descriptor: depthDesc)
    }
    
    func createGBufferRenderPassDescriptor() -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
            
        descriptor.colorAttachments[0].texture = gPosition
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)

        descriptor.colorAttachments[1].texture = gNormal
        descriptor.colorAttachments[1].loadAction = .clear
        descriptor.colorAttachments[1].storeAction = .store
        descriptor.colorAttachments[1].clearColor = MTLClearColorMake(0, 0, 0, 1)

        descriptor.colorAttachments[2].texture = gAlbedo
        descriptor.colorAttachments[2].loadAction = .clear
        descriptor.colorAttachments[2].storeAction = .store
        descriptor.colorAttachments[2].clearColor = MTLClearColorMake(0, 0, 0, 1)

        descriptor.depthAttachment.texture = depthTexture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .dontCare
        descriptor.depthAttachment.clearDepth = 1.0

        return descriptor
    }
}

extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        
        // -------------------------------------------------------------------------------- //
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge

        let samplerState = Renderer.device.makeSamplerState(descriptor: samplerDescriptor)
        
        // -------------------------------------------------------------------------------- //
        
        Renderer.width = view.drawableSize.width
        Renderer.height = view.drawableSize.height
        
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer() else { return }
            
        if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            computeEncoder.setSamplerState(samplerState, index: 0)
            computeEncoder.setComputePipelineState(computePipelineState)
            computeEncoder.setTexture(outputTexture, index: 0)
            computeEncoder.setTexture(gAlbedo, index: 1)
            computeEncoder.setTexture(gNormal, index: 2)
            computeEncoder.setTexture(gPosition, index: 3)
            computeEncoder.setTexture(rayMarchingQuad.cloudNoiseTexture, index: 4)
            computeEncoder.setBuffer(uniformBuffer, offset: 0, index: 0)
            
            let threads = 32
            
            let threadsPerThreadgroup = MTLSizeMake(threads, threads, 1)
            let threadgroups = MTLSizeMake(
                (Int(Renderer.width) + threads-1) / threads,
                (Int(Renderer.height) + threads-1) / threads,
                1)
            
            computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
            computeEncoder.endEncoding()
        }
        
        renderToGBuffer(commandBuffer: commandBuffer)
        
        // -------------------------------------------------------------------------------- //
        
        guard let descriptor = view.currentRenderPassDescriptor else { return }
        
        descriptor.depthAttachment.texture = view.depthStencilTexture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        descriptor.depthAttachment.clearDepth = 1.0
        
        // -------------------------------------------------------------------------------- //
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
                
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(rayMarchingQuad.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(outputTexture, index: 0)
        
        // -------------------------------------------------------------------------------- //
        
        Renderer.camera.update()
        
        uniforms.lookAt             = Renderer.camera.lookAtMatrix
        uniforms.projection         = Renderer.camera.projectionMatrix
        uniforms.inverseLookAt      = Renderer.camera.lookAtMatrix.inverse
        uniforms.inverseProjection  = Renderer.camera.projectionMatrix.inverse
        uniforms.cameraPosition     = Renderer.camera.position
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<UniformBuffer>.stride)
        
        // -------------------------------------------------------------------------------- //
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        renderEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else { return }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func renderToGBuffer(commandBuffer: MTLCommandBuffer) {
        
        let descriptor = createGBufferRenderPassDescriptor()
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        encoder.setRenderPipelineState(gBufferPipelineState)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setVertexBuffer(cube.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)

        uniforms.lookAt = Renderer.camera.lookAtMatrix
        uniforms.projection = Renderer.camera.projectionMatrix
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<UniformBuffer>.stride)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36)

        encoder.endEncoding()
    }
}
