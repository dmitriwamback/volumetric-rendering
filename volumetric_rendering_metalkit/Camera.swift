//
//  Camera.swift
//  volumetric_rendering_metalkit
//
//  Created by Dmitri Wamback on 2025-06-14.
//

import simd
import CoreFoundation
import Foundation

class Camera {
    
    var projectionMatrix: simd_float4x4!
    var lookAtMatrix: simd_float4x4!
    
    var position: SIMD3<Float>!
    var lookDirection: SIMD3<Float>!
    var velocity: SIMD3<Float>!
    
    var lastMousePositionX: Float!
    var lastMousePositionY: Float!
    
    var pitch: Float!
    var yaw: Float!
    
    var movement: SIMD4<Float>!
    var isRightMouseDown: Bool!
    
    init() {
        position = SIMD3<Float>(0, 0, 1)
        velocity = SIMD3<Float>(0, 0, 0)
        lookDirection = SIMD3<Float>(0, 0, -1)
        
        movement = SIMD4<Float>(0, 0, 0, 0)
        
        lastMousePositionX = 0
        lastMousePositionY = 0
        
        projectionMatrix = createProjectionMatrix(fov: 3.14159265358979/2.0, aspect: 1200/800, far: 1000.0, near: 0.1)
        lookAtMatrix = createLookAtMatrix(eye: position, target: position + lookDirection, up: SIMD3<Float>(0, 1, 0))
        
        pitch = 0
        yaw = 3.0 * 3.14159265358/2.0
        
        isRightMouseDown = false
    }
    
    func update() {
        
        let forward = movement.x
        let backward = movement.y
        let left = movement.z
        let right = movement.w
        
        let motion: SIMD3<Float> = lookDirection
        
        let rightDirection = normalize(cross(motion, SIMD3<Float>(0, 1, 0)))
        velocity = (motion * (forward + backward)) + (rightDirection * (right + left))
        
        position += velocity
        
        lookDirection = normalize(SIMD3<Float>(cos(yaw) * cos(pitch),
                                               sin(pitch),
                                               sin(yaw) * cos(pitch)))
        
        lookAtMatrix = createLookAtMatrix(eye: position, target: position + lookDirection, up: SIMD3<Float>(0, 1, 0))
        
        let width: CGFloat = Renderer.width
        let height: CGFloat = Renderer.height
                
        projectionMatrix = createProjectionMatrix(fov: 3.14159265358979/2.0, aspect: Float(width/height), far: 1000.0, near: 0.1)
    }
    
    func updateRotation(mousePosition: NSPoint) {
        
        if (isRightMouseDown) {
            let deltaX = Float(mousePosition.x) - lastMousePositionX
            let deltaY = Float(mousePosition.y) - lastMousePositionY
            
            pitch += deltaY * 0.0055
            yaw += deltaX * 0.0055
            
            if (pitch >  1.55) { pitch =  1.55 }
            if (pitch < -1.55) { pitch = -1.55 }
            
            lookDirection = normalize(SIMD3<Float>(cos(yaw) * cos(pitch),
                                                   sin(pitch),
                                                   sin(yaw) * cos(pitch)))
        }
        
        lastMousePositionX = Float(mousePosition.x)
        lastMousePositionY = Float(mousePosition.y)
    }
}
