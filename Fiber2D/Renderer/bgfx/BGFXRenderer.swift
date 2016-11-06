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

extension Program {
    public static let posColor: Program = {
        let vs = Shader(source: vs_shader, language: .metal, type: .vertex)
        let fs = Shader(source: fs_shader, language: .metal, type: .fragment)
        return Program(vertex: vs, fragment: fs)
    }()
    
    public static let posTexture: Program = {
        let vs = Shader(source: vs_shader, language: .metal, type: .vertex)
        let fs = Shader(source: fs_texture_shader, language: .metal, type: .fragment)
        return Program(vertex: vs, fragment: fs)
    }()
}

internal class BGFXRenderer: Renderer {
    internal var viewStack = [UInt8]()
    
    internal var currentViewID = ROOT_VIEW_ID
    
    internal var currentRenderTargetViewID = ROOT_RTT_ID
    
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
    }
    
    public func submit(shader: Program) {
        bgfx.submit(currentViewID, program: shader)
    }
    
    func flush() {
        bgfx.debugTextClear()
        bgfx.debugTextPrint(x: 0, y: 1, foreColor: .white, backColor: .darkGray, format: "going")

        bgfx.frame()
        //bgfx.renderFrame()
        
        currentViewID = ROOT_VIEW_ID
        currentRenderTargetViewID = ROOT_RTT_ID
    }
    
    func makeFrameBufferObject() -> FrameBufferObject {
        return SwiftBGFX.FrameBuffer(ratio: .equal, format: .bgra8)
    }
}

extension SwiftBGFX.FrameBuffer: FrameBufferObject {
    
}

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
