//
//  ViewController.swift
//  volumetric_rendering_metalkit
//
//  Created by Dmitri Wamback on 2025-06-14.
//

import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController {

    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view = MTKView(frame: CGRect(x: 0, y: 0, width: 1200, height: 800))
        
        guard let metal = view as? MTKView else {
            fatalError("Metal view not set up")
        }
        
        renderer = Renderer(metal: metal)
    }

    override var representedObject: Any? {
        didSet {
        
        }
    }


}

