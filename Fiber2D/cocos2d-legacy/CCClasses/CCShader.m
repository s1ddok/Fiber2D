/*
 * Cocos2D-SpriteBuilder: http://cocos2d.spritebuilder.com
 *
 * Copyright (c) 2014 Cocos2D Authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


#import "ccMacros.h"

#import "CCShader_private.h"
#import "CCRenderer_Private.h"
#import "CCTexture_private.h"
#import "CCMetalSupport_Private.h"

#import "CCFileLocator.h"
#import "CCFile.h"
#import "CCCache.h"
#import "CCColor.h"
#import "CCSetup.h"


NSString * const CCShaderUniformDefaultGlobals = @"cc_GlobalUniforms";
NSString * const CCShaderUniformProjection = @"cc_Projection";
NSString * const CCShaderUniformProjectionInv = @"cc_ProjectionInv";
NSString * const CCShaderUniformViewSize = @"cc_ViewSize";
NSString * const CCShaderUniformViewSizeInPixels = @"cc_ViewSizeInPixels";
NSString * const CCShaderUniformTime = @"cc_Time";
NSString * const CCShaderUniformSinTime = @"cc_SinTime";
NSString * const CCShaderUniformCosTime = @"cc_CosTime";
NSString * const CCShaderUniformRandom01 = @"cc_Random01";
NSString * const CCShaderUniformMainTexture = @"cc_MainTexture";
NSString * const CCShaderUniformSecondaryTexture = @"cc_SecondaryTexture";
NSString * const CCShaderUniformAlphaTestValue = @"cc_AlphaTestValue";


// Stringify macros
#define STR(s) #s
#define XSTR(s) STR(s)

static NSString *CCDefaultVShader = @"CCDefaultVShader";

static NSString *CCMetalShaderHeader = 
	@"using namespace metal;\n\n"
	@"typedef struct CCVertex {\n"
	@"	float4 position;\n"
	@"	float2 texCoord1;\n"
	@"	float2 texCoord2;\n"
	@"	float4 color;\n"
	@"} CCVertex;\n\n"
	@"typedef struct CCFragData {\n"
	@"	float4 position [[position]];\n"
	@"	float2 texCoord1;\n"
	@"	float2 texCoord2;\n"
	@"	half4  color;\n"
	@"} CCFragData;\n\n"
	@"typedef struct CCGlobalUniforms {\n"
	@"	float4x4 projection;\n"
	@"	float4x4 projectionInv;\n"
	@"	float2 viewSize;\n"
	@"	float2 viewSizeInPixels;\n"
	@"	float4 time;\n"
	@"	float4 sinTime;\n"
	@"	float4 cosTime;\n"
	@"	float4 random01;\n"
	@"} CCGlobalUniforms;\n";

static void CCLogShader(NSString *label, NSArray *sources)
{
    NSLog(@"%@", label);
    NSMutableString *allSource = [[NSMutableString alloc] init];
    for (NSString *source in sources)
    {
        [allSource appendString:source];
    }
    
    NSArray *sourceLines = [allSource componentsSeparatedByString:@"\n"];
    int lineNumber = 1;
    for (NSString *line in sourceLines)
    {
        NSLog(@"%4d: %@", lineNumber, line);
        lineNumber++;
    }
}

@interface CCShaderCache : CCCache @end
@implementation CCShaderCache

-(id)createSharedDataForKey:(id<NSCopying>)key
{
	NSString *shaderName = (NSString *)key;
	
    id<MTLLibrary> library = [CCMetalContext currentContext].library;
    
    NSString *fragmentName = [shaderName stringByAppendingString:@"FS"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:fragmentName];
    NSAssert(fragmentFunction, @"CCShader: Fragment function named %@ not found in the default library.", fragmentName);
    
    NSString *vertexName = [shaderName stringByAppendingPathExtension:@"VS"];
    id<MTLFunction> vertexFunction = ([library newFunctionWithName:vertexName] ?: [library newFunctionWithName:@"CCVertexFunctionDefault"]);
    
    CCShader *shader = [[CCShader alloc] initWithMetalVertexFunction:vertexFunction fragmentFunction:fragmentFunction];
    shader.debugName = shaderName;
    
    return shader;
}

-(id)createPublicObjectForSharedData:(id)data
{
	return [data copy];
}

@end


@implementation CCShader {
	BOOL _ownsProgram;
}

#pragma mark Init Methods:

#if __CC_METAL_SUPPORTED_AND_ENABLED

static CCUniformSetter
MetalUniformSetBuffer(NSString *name, MTLArgument *vertexArg, MTLArgument *fragmentArg)
{
	NSUInteger vertexIndex = vertexArg.index;
	NSUInteger fragmentIndex = fragmentArg.index;
	
	// vertexArg may be nil.
	size_t bytes = (vertexArg.bufferDataSize ?: fragmentArg.bufferDataSize);
	
	CCMetalContext *context = [CCMetalContext currentContext];
	
	// Handle cc_VertexAttributes specially.
	if([name isEqualToString:@"cc_VertexAttributes"]){
		NSCAssert(vertexArg && !fragmentArg, @"cc_VertexAttributes should only be used by vertex functions.");
		NSCAssert(bytes == sizeof(CCVertex), @"cc_VertexAttributes data size is not sizeof(CCVertex).");
		
		return ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
			CCGraphicsBufferMetal *vertexBuffer = (CCGraphicsBufferMetal *)renderer->_buffers->_vertexBuffer;
			id<MTLBuffer> metalBuffer = vertexBuffer->_buffer;
			
			NSUInteger pageOffset = renderer->_vertexPageBound*(1<<16)*sizeof(CCVertex);
			[context->_currentRenderCommandEncoder setVertexBuffer:metalBuffer offset:pageOffset atIndex:vertexIndex];
		};
	} else {
		// If both args are active, they must match.
		NSCAssert(!vertexArg || !fragmentArg || vertexArg.bufferDataSize == fragmentArg.bufferDataSize, @"Vertex and fragment argument type don't match for '%@'.", vertexArg.name);
		
		// Round up to the next multiple of 16 since Metal types have an alignment of 16 bytes at most.
		size_t alignedBytes = ((bytes - 1) | 0xF) + 1;
		
		return ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
			CCGraphicsBufferMetal *uniformBuffer = (CCGraphicsBufferMetal *)renderer->_buffers->_uniformBuffer;
			id<MTLBuffer> metalBuffer = uniformBuffer->_buffer;
			
			NSUInteger offset = 0;
			
			NSValue *value = shaderUniforms[name];
			if(value){
				// Try finding a per-node value first and append it to the uniform buffer.
				void *buff = CCGraphicsBufferPushElements(uniformBuffer, alignedBytes);
				[value getValue:buff];
				
				offset = buff - uniformBuffer->_ptr;
			} else {
				// Look for a global offset instead.
				NSNumber *globalOffset = renderer->_globalShaderUniformBufferOffsets[name];
				NSCAssert(globalOffset, @"Shader value named '%@' not found.", name);
				
				offset = globalOffset.unsignedIntegerValue;
			}
			
			id<MTLRenderCommandEncoder> renderEncoder = context->_currentRenderCommandEncoder;
			if(vertexArg) [renderEncoder setVertexBuffer:metalBuffer offset:offset atIndex:vertexIndex];
			if(fragmentArg) [renderEncoder setFragmentBuffer:metalBuffer offset:offset atIndex:fragmentIndex];
		};
	}
}

static CCUniformSetter
MetalUniformSetSampler(NSString *name, MTLArgument *vertexArg, MTLArgument *fragmentArg)
{
	NSUInteger vertexIndex = vertexArg.index;
	NSUInteger fragmentIndex = fragmentArg.index;
	
	// For now, samplers and textures are locked together like in GL.
	NSString *textureName = [name substringToIndex:name.length - @"Sampler".length];
	
	CCMetalContext *context = [CCMetalContext currentContext];
	
	return ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
		CCTexture *texture = shaderUniforms[textureName] ?: globalShaderUniforms[textureName] ?: [CCTexture none];
		NSCAssert([texture isKindOfClass:[CCTexture class]], @"Shader uniform '%@' value must be a CCTexture object.", name);
		
		id<MTLSamplerState> sampler = [texture metalSampler];
		
		id<MTLRenderCommandEncoder> renderEncoder = context->_currentRenderCommandEncoder;
		if(vertexArg) [renderEncoder setVertexSamplerState:sampler atIndex:vertexIndex];
		if(fragmentArg) [renderEncoder setFragmentSamplerState:sampler atIndex:fragmentIndex];
	};
}

static CCUniformSetter
MetalUniformSetTexture(NSString *name, MTLArgument *vertexArg, MTLArgument *fragmentArg)
{
	NSUInteger vertexIndex = vertexArg.index;
	NSUInteger fragmentIndex = fragmentArg.index;
	
	CCMetalContext *context = [CCMetalContext currentContext];
	
	return ^(CCRenderer *renderer, NSDictionary *shaderUniforms, NSDictionary *globalShaderUniforms){
		CCTexture *texture = shaderUniforms[name] ?: globalShaderUniforms[name] ?: [CCTexture none];
		NSCAssert([texture isKindOfClass:[CCTexture class]], @"Shader uniform '%@' value must be a CCTexture object.", name);
		
		id<MTLTexture> metalTexture = [texture metalTexture];
		
		id<MTLRenderCommandEncoder> renderEncoder = context->_currentRenderCommandEncoder;
		if(vertexArg) [renderEncoder setVertexTexture:metalTexture atIndex:vertexIndex];
		if(fragmentArg) [renderEncoder setFragmentTexture:metalTexture atIndex:fragmentIndex];
	};
}

static NSDictionary *
MetalUniformSettersForFunctions(id<MTLFunction> vertexFunction, id<MTLFunction> fragmentFunction)
{
	// Get the shader reflection information by making a dummy render pipeline state.
	MTLRenderPipelineDescriptor *descriptor = [MTLRenderPipelineDescriptor new];
	descriptor.vertexFunction = vertexFunction;
	descriptor.fragmentFunction = fragmentFunction;
    MTLRenderPipelineColorAttachmentDescriptor *colorDescriptor = [MTLRenderPipelineColorAttachmentDescriptor new];
    colorDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    descriptor.colorAttachments[0] = colorDescriptor;
	
	NSError *error = nil;
	MTLRenderPipelineReflection *reflection = nil;
	[[CCMetalContext currentContext].device newRenderPipelineStateWithDescriptor:descriptor options:MTLPipelineOptionArgumentInfo reflection:&reflection error:&error];
	
	NSCAssert(!error, @"Error getting Metal shader arguments.");
	
	// Collect all of the arguments.
	NSMutableDictionary *vertexArgs = [NSMutableDictionary dictionary];
	for(MTLArgument *arg in reflection.vertexArguments){ if(arg.active){ vertexArgs[arg.name] = arg; }}
	
	NSMutableDictionary *fragmentArgs = [NSMutableDictionary dictionary];
	for(MTLArgument *arg in reflection.fragmentArguments){ if(arg.active){ fragmentArgs[arg.name] = arg; }}
	
	NSSet *argSet = [[NSSet setWithArray:vertexArgs.allKeys] setByAddingObjectsFromArray:fragmentArgs.allKeys];
	
	// Make uniform setters.
	NSMutableDictionary *uniformSetters = [NSMutableDictionary dictionary];
	
	for(NSString *name in argSet){
		MTLArgument *vertexArg = vertexArgs[name];
		MTLArgument *fragmentArg = fragmentArgs[name];
		
		// If neither argument is active. Skip.
		if(!vertexArg.active && !fragmentArg.active) continue;
		
		MTLArgumentType type = (vertexArg ? vertexArg.type : fragmentArg.type);
		NSCAssert(!vertexArg || !fragmentArg || type == fragmentArg.type, @"Vertex and fragment argument type don't match for '%@'.", name);
		
		switch(type){
			case MTLArgumentTypeBuffer: uniformSetters[name] = MetalUniformSetBuffer(name, vertexArg, fragmentArg); break;
			case MTLArgumentTypeSampler: uniformSetters[name] = MetalUniformSetSampler(name, vertexArg, fragmentArg); break;
			case MTLArgumentTypeTexture: uniformSetters[name] = MetalUniformSetTexture(name, vertexArg, fragmentArg); break;
			case MTLArgumentTypeThreadgroupMemory: NSCAssert(NO, @"Compute memory not supported. (yet?)"); break;
		}
	}
	
	return uniformSetters;
}

-(instancetype)initWithMetalVertexFunction:(id<MTLFunction>)vertexFunction fragmentFunction:(id<MTLFunction>)fragmentFunction
{
	if((self = [super init])){
		NSAssert(vertexFunction && fragmentFunction, @"Must have both a vertex and fragment function to make a CCShader.");
		
		_vertexFunction = vertexFunction;
		_fragmentFunction = fragmentFunction;
		
		_uniformSetters = MetalUniformSettersForFunctions(vertexFunction, fragmentFunction);
	}
	
	return self;
}

-(instancetype)initWithMetalVertexShaderSource:(NSString *)vertexSource fragmentShaderSource:(NSString *)fragmentSource
{
	CCMetalContext *context = [CCMetalContext currentContext];
	
	id<MTLFunction> vertexFunction = nil;
	if(vertexSource == CCDefaultVShader){
		// Use the default vertex shader.
		vertexFunction = [context.library newFunctionWithName:@"CCVertexFunctionDefault"];
	} else {
		// Append on the standard header since JIT compiled shaders can't use #import
		vertexSource = [CCMetalShaderHeader stringByAppendingString:vertexSource];
		
		// Compile the vertex shader.
		NSError *verr = nil;
		id<MTLLibrary> vlib = [context.device newLibraryWithSource:vertexSource options:nil error:&verr];
		if(verr)
        {
            CCLOG(@"Error compiling metal vertex shader: %@", verr);
            CCLogShader(@"Vertex Shader", @[vertexSource]);
        }
		vertexFunction = [vlib newFunctionWithName:@"ShaderMain"];
	}
	
	// Append on the standard header since JIT compiled shaders can't use #import
	fragmentSource = [CCMetalShaderHeader stringByAppendingString:fragmentSource];
	
	// compile the fragment shader.
	NSError *ferr = nil;
	id<MTLLibrary> flib = [context.device newLibraryWithSource:fragmentSource options:nil error:&ferr];
	if(ferr)
    {
        CCLOG(@"Error compiling metal fragment shader: %@", ferr);
        CCLogShader(@"Fragment Shader", @[fragmentSource]);
    }
    
	id<MTLFunction> fragmentFunction = [flib newFunctionWithName:@"ShaderMain"];
	
	// Done!
	return [self initWithMetalVertexFunction:vertexFunction fragmentFunction:fragmentFunction];
}
#endif

-(instancetype)initWithVertexShaderSource:(NSString *)vertexSource fragmentShaderSource:(NSString *)fragmentSource
{
    return [self initWithMetalVertexShaderSource:vertexSource fragmentShaderSource:fragmentSource];
}

-(instancetype)initWithFragmentShaderSource:(NSString *)source
{
	return [self initWithVertexShaderSource:CCDefaultVShader fragmentShaderSource:source];
}

-(instancetype)initWithRawVertexShaderSource:(NSString *)vertexSource rawFragmentShaderSource:(NSString *)fragmentSource
{
    return [self initWithMetalVertexShaderSource:vertexSource fragmentShaderSource:fragmentSource];
}


-(instancetype)copyWithZone:(NSZone *)zone
{
    return [[CCShader allocWithZone:zone] initWithMetalVertexFunction:_vertexFunction fragmentFunction:_fragmentFunction];
}

static CCShaderCache *CC_SHADER_CACHE = nil;
static CCShader *CC_SHADER_POS_COLOR = nil;
static CCShader *CC_SHADER_POS_TEX_COLOR = nil;
static CCShader *CC_SHADER_POS_TEXA8_COLOR = nil;
static CCShader *CC_SHADER_POS_TEX_COLOR_ALPHA_TEST = nil;

+(void)initialize
{
	// +initialize may be called due to loading a subclass.
	if(self != [CCShader class]) return;
	
	CC_SHADER_CACHE = [[CCShaderCache alloc] init];

    id<MTLLibrary> library = [CCMetalContext currentContext].library;
    NSAssert(library, @"Metal shader library not found.");
    
    id<MTLFunction> vertex = [library newFunctionWithName:@"CCVertexFunctionDefault"];
    
    CC_SHADER_POS_COLOR = [[self alloc] initWithMetalVertexFunction:vertex fragmentFunction:[library newFunctionWithName:@"CCFragmentFunctionDefaultColor"]];
    CC_SHADER_POS_COLOR.debugName = @"CCPositionColorShader";
    
    CC_SHADER_POS_TEX_COLOR = [[self alloc] initWithMetalVertexFunction:vertex fragmentFunction:[library newFunctionWithName:@"CCFragmentFunctionDefaultTextureColor"]];
    CC_SHADER_POS_TEX_COLOR.debugName = @"CCPositionTextureColorShader";
    
    CC_SHADER_POS_TEXA8_COLOR = [[self alloc] initWithMetalVertexFunction:vertex fragmentFunction:[library newFunctionWithName:@"CCFragmentFunctionDefaultTextureA8Color"]];
    CC_SHADER_POS_TEXA8_COLOR.debugName = @"CCPositionTextureA8ColorShader";
    
    CC_SHADER_POS_TEX_COLOR_ALPHA_TEST = [[self alloc] initWithMetalVertexFunction:vertex fragmentFunction:[library newFunctionWithName:@"CCFragmentFunctionUnsupported"]];
    CC_SHADER_POS_TEX_COLOR_ALPHA_TEST.debugName = @"CCPositionTextureColorAlphaTestShader";
}

+(instancetype)positionColorShader
{
	return CC_SHADER_POS_COLOR;
}

+(instancetype)positionTextureColorShader
{
	return CC_SHADER_POS_TEX_COLOR;
}

+(instancetype)positionTextureColorAlphaTestShader
{
	return CC_SHADER_POS_TEX_COLOR_ALPHA_TEST;
}

+(instancetype)positionTextureA8ColorShader
{
	return CC_SHADER_POS_TEXA8_COLOR;
}

+(instancetype)shaderNamed:(NSString *)shaderName
{
	return [CC_SHADER_CACHE objectForKey:shaderName];
}

@end
