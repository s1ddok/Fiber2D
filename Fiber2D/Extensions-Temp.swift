//
//  Extensions-Temp.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 04.08.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

// TEMPORARY
extension Color {
    var glkVector4: GLKVector4 {
        return GLKVector4(v: (d.x, d.y, d.z, d.w))
    }
}

extension Matrix4x4f {
    var glkMatrix4: GLKMatrix4 {
        return unsafeBitCast(d, to: GLKMatrix4.self)
    }
}

extension Vector3f {
    var glkVector3: GLKVector3 {
        return GLKVector3(v: (d.x, d.y, d.z))
    }
}

extension Vector2f {
    var cgPoint: CGPoint {
        return CGPoint(x: Double(x), y: Double(y))
    }
    
    var glkVec2: GLKVector2 {
        return GLKVector2Make(x, y)
    }
    
    init(_ cgPoint: CGPoint) {
        d = float2(Float(cgPoint.x), Float(cgPoint.y))
    }
}

extension GLKVector2 {
    var isZero: Bool {
        return x == 0.0 && y == 0.0
    }
    
    init(point: CGPoint) {
        v.0 = Float(point.x)
        v.1 = Float(point.y)
    }
}

extension Matrix4x4f {
    init(target: Node) {
        let size = target.contentSizeInPoints
        let w = Float(size.width)
        let h = Float(size.height)
        
        let m = Matrix4x4f.ortho(left: 0, right: w, bottom: 0, top: h, near: -1024, far: 1024)
        d = m.d
    }
}

extension Size {
    init(CGSize: CGSize) {
        self.init(Float(CGSize.width), Float(CGSize.height))
    }
    
    var cgSize: CGSize {
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
}

extension Rect {
    init(CGRect: CGRect) {
        self.init(origin: p2d(CGRect.origin), size: Size(CGSize: CGRect.size))
    }
}
