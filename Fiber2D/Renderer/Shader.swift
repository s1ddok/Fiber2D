//
//  Shader.swift
//  Fiber2D
//
//  Created by Stuart Carnie on 9/11/16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

let ShaderUniformDefaultGlobals = "cc_GlobalUniforms"
let ShaderUniformProjection = "cc_Projection"
let ShaderUniformProjectionInv = "cc_ProjectionInv"
let ShaderUniformViewSize = "cc_ViewSize"
let ShaderUniformViewSizeInPixels = "cc_ViewSizeInPixels"
let ShaderUniformTime = "cc_Time"
let ShaderUniformSinTime = "cc_SinTime"
let ShaderUniformCosTime = "cc_CosTime"
let ShaderUniformRandom01 = "cc_Random01"
let ShaderUniformMainTexture = "cc_MainTexture"
let ShaderUniformSecondaryTexture = "cc_SecondaryTexture"
let ShaderUniformAlphaTestValue = "cc_AlphaTestValue"

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
