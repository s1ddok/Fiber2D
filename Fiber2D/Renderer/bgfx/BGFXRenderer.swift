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

let vs_shader =
    "using namespace metal; \n" +
        "struct xlatMtlShaderInput { \n" +
        "  float4 a_position  [[attribute(0)]]; \n" +
        "  float2 a_texcoord0 [[attribute(1)]]; \n" +
        "  float2 a_texcoord1 [[attribute(2)]]; \n" +
        "  float4 a_color0    [[attribute(3)]]; \n" +
        "}; \n" +
        "struct xlatMtlShaderOutput { \n" +
        "  float4 gl_Position [[position]]; \n" +
        "  float2 v_texcoord0; " +
        "  float2 v_texcoord1; " +
        "  float4 v_color0; \n" +
        "}; \n" +
        "struct xlatMtlShaderUniform { \n" +
        "  float4x4 u_modelViewProj; \n" +
        "}; \n" +
        "vertex xlatMtlShaderOutput xlatMtlMain (xlatMtlShaderInput _mtl_i [[stage_in]], constant xlatMtlShaderUniform& _mtl_u [[buffer(0)]]) \n" +
        "{ \n" +
        "  xlatMtlShaderOutput _mtl_o; \n" +
        "  float4 tmpvar_1; \n" +
        "  //tmpvar_1.w = 1.0; \n" +
        "  tmpvar_1 = _mtl_i.a_position; \n" +
        //"  _mtl_o.gl_Position = (_mtl_u.u_modelViewProj * tmpvar_1); \n" +
        "  _mtl_o.gl_Position = _mtl_i.a_position; \n" +
        "  _mtl_o.v_texcoord0 = _mtl_i.a_texcoord0; \n" +
        "  _mtl_o.v_texcoord1 = _mtl_i.a_texcoord1; \n" +
        "  _mtl_o.v_color0 = _mtl_i.a_color0; \n" +
        "  return _mtl_o; \n" +
"} \n";

let fs_shader =
    "using namespace metal; \n" +
        "struct xlatMtlShaderInput { \n" +
        "  float4 v_color0; \n" +
        "}; \n" +
        "struct xlatMtlShaderOutput { \n" +
        "  float4 gl_FragColor; \n" +
        "}; \n" +
        "struct xlatMtlShaderUniform { \n" +
        "}; \n" +
        "fragment xlatMtlShaderOutput xlatMtlMain (xlatMtlShaderInput _mtl_i [[stage_in]], constant xlatMtlShaderUniform& _mtl_u [[buffer(0)]]) \n" +
        "{ \n" +
        "  xlatMtlShaderOutput _mtl_o; \n" +
        "  _mtl_o.gl_FragColor = _mtl_i.v_color0; \n" +
        "  return _mtl_o; \n" +
"} \n"

let fs_texture_shader =
    "using namespace metal; \n" +
        "struct xlatMtlShaderInput { \n" +
        "  float4 v_color0; \n" +
        "  float2 v_texcoord0; \n" +
        "}; \n" +
        "struct xlatMtlShaderOutput { \n" +
        "  float4 gl_FragColor; \n" +
        "}; \n" +
        "struct xlatMtlShaderUniform { \n" +
        "}; \n" +
        "fragment xlatMtlShaderOutput xlatMtlMain (xlatMtlShaderInput _mtl_i [[stage_in]]," +
        "                                          constant xlatMtlShaderUniform& _mtl_u [[buffer(0)]], \n" +
        "                                          texture2d<float> u_mainTexture [[texture(0)]]," +
        "                                          sampler u_mainTextureSampler [[sampler(0)]])" +
        "{ \n" +
        "  xlatMtlShaderOutput _mtl_o; \n" +
        "  _mtl_o.gl_FragColor = _mtl_i.v_color0 * u_mainTexture.sample(u_mainTextureSampler, _mtl_i.v_texcoord0); \n" +
        "  return _mtl_o; \n" +
"} \n"

class BGFXRenderer: Renderer {
    
    var projection: Matrix4x4f = Matrix4x4f.identity
    
    var bindings = BGFXBufferBindings()
    
    let prog: Program
    let texture: Texture
    init() {
        let vs = Shader(source: vs_shader, language: .metal, type: .vertex)
        let fs = Shader(source: fs_texture_shader, language: .metal, type: .fragment)
        prog = Program(vertex: vs, fragment: fs)
        
        let image = Image(pngFile: try! CCFileLocator.shared().fileNamed(withResolutionSearch: "circle.png"))

        texture = Texture.make(from: image)
        bgfx.frame()
    }
    
    func enqueueClear(color: vec4) {
        bgfx.setViewClear(viewId: 0, options: [.color, .depth], rgba: 0x30_30_30_ff, depth: 1.0, stencil: 0)
    }
    
    func enqueueTriangles(count: UInt, verticesCount: UInt, state: RendererState, globalSortOrder: Int) -> RendererBuffer {
        return bindings.makeView(vertexCount: Int(verticesCount), triangleCount: Int(count))
    }
    
    func prepare(withProjection: Matrix4x4f, framebuffer: FrameBufferObject) {
        self.bindings.clear()
        let proj = unsafeBitCast(withProjection, to: SwiftMath.Matrix4x4f.self)
        bgfx.setViewSequential(viewId: 0, enabled: true)
        bgfx.setViewRect(viewId: 0, x: 0, y: 0, width: 1024, height: 750)
        bgfx.touch(0)

        bgfx.setViewTransform(viewId: 0, proj: proj)
    }
    
    func flush() {
        bgfx.debugTextClear()
        bgfx.debugTextPrint(x: 0, y: 1, foreColor: .white, backColor: .darkGray, format: "going")
        
        if bindings.vertexCount == 0 || bindings.indexCount == 0 {
            return
        }
        
        let vb = TransientVertexBuffer(count: UInt32(bindings.vertexCount), layout: RendererVertex.layout)
        memcpy(vb.data, bindings.vertices, bindings.vertexCount * MemoryLayout<RendererVertex>.size)
        bgfx.setVertexBuffer(vb)
        
        let ib = TransientIndexBuffer(count: UInt32(bindings.indexCount))
        memcpy(ib.data, bindings.indices, bindings.indexCount * MemoryLayout<UInt16>.size)
        bgfx.setIndexBuffer(ib)

        let renderState = RenderStateOptions.default
            // Why would premultiplied blend mode produce such a strange result?
            //| RenderStateOptions.blend(source: .blendSourceAlpha, destination: .blendInverseSourceAlpha)
            //| RenderStateOptions.blend(equation: .blendEquationAdd)
        bgfx.setRenderState(renderState, colorRgba: 0x00)
        let uniform = Uniform(name: "u_mainTexture", type: .int1)
        bgfx.setTexture(0, sampler: uniform, texture: texture)
        bgfx.submit(0, program: prog)
        bgfx.frame()
        bgfx.renderFrame()
    }
    
    func makeFrameBufferObject() -> FrameBufferObject {
        return SwiftBGFX.FrameBuffer(ratio: .equal, format: .bgra8)
    }
}

class BGFXBufferBindings {
    fileprivate var vertices: [RendererVertex]
    fileprivate var vertexCount: Int
    fileprivate var indices: [UInt16]
    fileprivate var indexCount: Int
    
    init() {
        vertices    = [RendererVertex](repeating: RendererVertex(), count: 16*1024)
        vertexCount = 0
        indices     = [UInt16](repeating: 0, count: 1024)
        indexCount  = 0
    }
    
    func clear() {
        self.vertexCount = 0
        self.indexCount  = 0
    }
    
    func makeView(vertexCount: Int, triangleCount: Int) -> View {
        let vrequired = self.vertexCount + vertexCount
        if vertices.capacity < self.vertexCount + vertexCount {
            // Why 1.5? https://github.com/facebook/folly/blob/master/folly/docs/FBVector.md
            vertices.reserveCapacity(Int(Double(vrequired) * 1.5))
        }
        
        let irequired = self.indexCount + triangleCount*3
        if indices.capacity < irequired {
            indices.reserveCapacity(Int(Double(irequired) * 1.5))
        }
        
        let v = View(buf: self, vertexOffset: self.vertexCount, indexOffset: self.indexCount)
        self.vertexCount += vertexCount
        self.indexCount  += triangleCount*3
        return v
    }
    
    class View: RendererBuffer {
        var buf: BGFXBufferBindings
        let vertexOffset: Int
        let indexOffset: Int
        
        init(buf: BGFXBufferBindings, vertexOffset: Int, indexOffset: Int) {
            self.buf = buf
            self.vertexOffset = vertexOffset
            self.indexOffset  = indexOffset
        }
        
        func setVertex(index: Int, vertex: RendererVertex) {
            //let v = unsafeBitCast(vertex, to: BGFXRendererVertex.self)
            buf.vertices[vertexOffset+index] = vertex
        }
        
        func setTriangle(index: Int, v1: UInt16, v2: UInt16, v3: UInt16) {
            buf.indices[indexOffset + index * 3 + 0] = UInt16(vertexOffset)+v1
            buf.indices[indexOffset + index * 3 + 1] = UInt16(vertexOffset)+v2
            buf.indices[indexOffset + index * 3 + 2] = UInt16(vertexOffset)+v3
        }
    }
}

extension SwiftBGFX.FrameBuffer: FrameBufferObject {
    
}

extension CCFrameBufferObject: FrameBufferObject {
    
}

extension CCRenderState: RendererState {
    
}

/* Why?
private struct _texcoord {
    var u, v: Float
    init() {
        u = 0
        v = 0
    }
}

private struct _color {
    var r, g, b, a: Float
    init() {
        r = 0
        g = 0
        b = 0
        a = 0
    }
}

private struct BGFXRendererVertex {
    var x, y, z, w: Float
    var texCoord0: _texcoord
    var texCoord1: _texcoord
    var color0: _color
    init() {
        x = 0
        y = 0
        z = 0
        w = 0
        texCoord0 = _texcoord()
        texCoord1 = _texcoord()
        color0 = _color()
    }
}*/

extension RendererVertex {
    static var layout: VertexLayout {
        let l = VertexLayout()
        l.begin()
            .add(attrib: .position, num: 4, type: .float)
            .add(attrib: .texCoord0, num: 2, type: .float)
            .add(attrib: .texCoord1, num: 2, type: .float)
            .add(attrib: .color0, num: 4, type: .float, normalized: true)
            .end()
        
        return l
    }
}
