//
//  BGFXRenderer.swift
//  Fiber2D
//
//  Created by Stuart Carnie on 9/11/16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

import SwiftMath
import Cbgfx
import SwiftBGFX

internal let ROOT_RTT_ID  = UInt8(0)
internal let ROOT_VIEW_ID = UInt8(190)

internal class BGFXRenderer: Renderer {
    internal var viewStack = [UInt8]()
    
    internal var currentViewID = ROOT_VIEW_ID
    
    internal var currentRenderTargetViewID = ROOT_RTT_ID
    
    internal var framesToUpdateStats = 10
    internal var frameCount = 0
    internal var gpuFreq = 0.0
    internal var cpuFreq = 0.0
    
    internal var rtTrees = [Tree<UInt8>]()
    internal var currentTree: Tree<UInt8>?
    internal var currentFrameHasNestedRTS = false
    
    init() {
        bgfx.frame()
        
        bgfx.debug = [.text]
    }
    
    func enqueueClear(color: vec4) {
        bgfx.setViewClear(viewId: currentViewID, options: [.color, .depth], rgba: 0x30_30_30_ff, depth: 1.0, stencil: 0)
    }
    
    func prepare(withProjection proj: Matrix4x4f) {
        bgfx.setViewSequential(viewId: currentViewID, enabled: true)
        bgfx.setViewRect(viewId: currentViewID, x: 0, y: 0, ratio: .equal)
        bgfx.touch(currentViewID)

        bgfx.setViewTransform(viewId: currentViewID, proj: proj)
        
        // Prepare stuff for RTs
        if currentFrameHasNestedRTS {
            bgfx.clearViewRemap()
        }
        rtTrees.removeAll(keepingCapacity: true)
        currentFrameHasNestedRTS = false
    }
    
    public func submit(shader: Program) {
        bgfx.submit(currentViewID, program: shader)
    }
    
    func flush() {
        frameCount = (frameCount + 1) % framesToUpdateStats
        if frameCount == 0 {
            let stats = bgfx.stats
            
            gpuFreq = Double(stats.gpuTimeEnd - stats.gpuTimeBegin) / 1000
            cpuFreq = Double(stats.cpuTimeEnd - stats.cpuTimeBegin) / 1000
        }
        
        bgfx.debugTextClear()
        bgfx.debugTextPrint(x: 0, y: 1, foreColor: .white, backColor: .darkGray, format: "Fiber2D BGFX Renderer")
        bgfx.debugTextPrint(x: 0, y: 2, foreColor: .white, backColor: .darkGray, format: "CPU: \(cpuFreq)")
        bgfx.debugTextPrint(x: 0, y: 3, foreColor: .white, backColor: .darkGray, format: "GPU: \(gpuFreq)")
        
        if currentFrameHasNestedRTS {
            let treeViews = rtTrees.childrenFirstTraverse()
            var newViewOrder = [UInt8](repeating: 0, count: treeViews.count)
            for i in 0..<newViewOrder.count {
                newViewOrder[Int(treeViews[i] - ROOT_RTT_ID)] = ROOT_RTT_ID + UInt8(i)
            }
            bgfx.setViewOrder(viewId: ROOT_RTT_ID, ids: newViewOrder)
        }
        
        bgfx.frame()
        
        currentViewID = ROOT_VIEW_ID
        currentRenderTargetViewID = ROOT_RTT_ID
    }
    
    func makeFrameBufferObject() -> FrameBufferObject {
        return SwiftBGFX.FrameBuffer(ratio: .equal, format: .bgra8)
    }
}

extension SwiftBGFX.FrameBuffer: FrameBufferObject {
    
}

public extension RendererVertex {
    public static let layout: VertexLayout = {
        let l = VertexLayout()
        l.begin()
            .add(attrib: .position, num: 4, type: .float)
            .add(attrib: .texCoord0, num: 2, type: .float)
            .add(attrib: .texCoord1, num: 2, type: .float)
            .add(attrib: .color0, num: 4, type: .float, normalized: true)
            .end()
        
        return l
    }()
}
