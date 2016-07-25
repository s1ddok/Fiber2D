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


#import "CCNS.h"

#import "CCTexture.h"
#import "CCImage_Private.h"
#import "CCTexture_Private.h"

#import "ccConfig.h"
#import "ccMacros.h"
#import "CCShader.h"
#import "Fiber2D-Swift.h"
#import "ccUtils.h"
#import "CCFileLocator.h"
#import "CCTextureCache.h"
#import "CCSetup.h"

#import "CCMetalSupport_Private.h"


NSString * const CCTextureOptionGenerateMipmaps = @"CCTextureOptionGenerateMipmaps";
NSString * const CCTextureOptionMinificationFilter = @"CCTextureOptionMinificationFilter";
NSString * const CCTextureOptionMagnificationFilter = @"CCTextureOptionMagnificationFilter";
NSString * const CCTextureOptionMipmapFilter = @"CCTextureOptionMipmapFilter";
NSString * const CCTextureOptionAddressModeX = @"CCTextureOptionAddressModeX";
NSString * const CCTextureOptionAddressModeY = @"CCTextureOptionAddressModeY";

//CLASS IMPLEMENTATIONS:

// This class implements what will hopefully be a temporary replacement
// for the retainCount trick used to figure out which cached objects are safe to purge.
@implementation CCProxy
{
    id _target;
}

- (id)initWithTarget:(id)target
{
    if ((self = [super init]))
    {
        _target = target;
    }
    
    return(self);
}

// Forward class checks for assertions.
-(BOOL)isKindOfClass:(Class)aClass {return [_target isKindOfClass:aClass];}

// Make concrete implementations for CCTexture methods commonly called at runtime.
-(CGFloat)contentScale {return [(CCTexture *)_target contentScale];}
-(CGSize)contentSize {return [_target contentSize];}
-(NSUInteger)pixelWidth {return [_target pixelWidth];}
-(NSUInteger)pixelHeight {return [_target pixelHeight];}
-(BOOL)hasPremultipliedAlpha {return [_target hasPremultipliedAlpha];}
-(SpriteFrame *)spriteFrame {return [_target spriteFrame];}

// Make concrete implementations for CCSpriteFrame methods commonly called at runtime.
-(CGRect)rect {return [_target rect];}
-(BOOL)rotated {return [_target rotated];}
-(CGPoint)trimOffset {return [_target trimOffset];}
-(CGSize)untrimmedSize {return [_target untrimmedSize];}
-(CCTexture *)texture {return [_target texture];}

// Let the rest fall back to a slow forwarded path.
- (id)forwardingTargetForSelector:(SEL)aSelector
{
//    CCLOGINFO(@"Forwarding selector [%@ %@]", NSStringFromClass([_target class]), NSStringFromSelector(aSelector));
//		CCLOGINFO(@"If there are many of these calls, we should add concrete forwarding methods. (TODO remove logging before release)");
    return(_target);
}

- (void)dealloc
{
		CCLOGINFO(@"Proxy for %p deallocated.", _target);
}

@end


#pragma mark -
#pragma mark CCTexture2D - Main

@implementation CCTexture {
    SpriteFrame *_spriteFrame;
	CCProxy __weak *_proxy;
}

static NSDictionary *NORMALIZED_OPTIONS = nil;

static CCTexture *CCTextureNone = nil;

+(void)initialize
{
	// +initialize may be called due to loading a subclass.
	if(self != [CCTexture class]) return;
    
    NORMALIZED_OPTIONS = @{
        CCTextureOptionGenerateMipmaps: @(NO),
        CCTextureOptionMinificationFilter: @(CCTextureFilterLinear),
        CCTextureOptionMagnificationFilter: @(CCTextureFilterLinear),
        CCTextureOptionMipmapFilter: @(CCTextureFilterMipmapNone),
        CCTextureOptionAddressModeX: @(CCTextureAddressModeClampToEdge),
        CCTextureOptionAddressModeY: @(CCTextureAddressModeClampToEdge),
    };
	
	CCTextureNone = [self alloc];
	CCTextureNone->_contentScale = 1.0;

    CCMetalContext *context = [CCMetalContext currentContext];
    NSAssert(context, @"Metal context is nil.");
    
    (CCTextureNone)->_metalSampler = [context.device newSamplerStateWithDescriptor:[MTLSamplerDescriptor new]];
    
    MTLTextureDescriptor *textureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:1 height:1 mipmapped:NO];
    (CCTextureNone)->_metalTexture = [context.device newTextureWithDescriptor:textureDesc];
	
}

+(instancetype)none
{
	return CCTextureNone;
}

static NSDictionary *_DEFAULT_OPTIONS = nil;

+ (id) textureWithFile:(NSString*)file
{
    return [[CCTextureCache sharedTextureCache] addImage:file];
}

+(instancetype)textureForKey:(NSString *)key loader:(CCTexture *(^)())loader
{
    key = [NSString stringWithFormat:@"CCTEXTURECACHE_KEY:%@", key];
    
    CCTexture *texture = [[CCTextureCache sharedTextureCache] textureForKey:key];
    
    if(texture == nil){
        texture = loader();
        [[CCTextureCache sharedTextureCache] addTexture:texture forKey:key];
    }
    
    return texture;
}

+(NSDictionary *)defaultOptions
{
    return _DEFAULT_OPTIONS;
}

+(void)setDefaultOptions:(NSDictionary *)options
{
    _DEFAULT_OPTIONS = options;
}

+(NSDictionary *)normalizeOptions:(NSDictionary *)options
{
    if(options == nil || options == NORMALIZED_OPTIONS){
        return NORMALIZED_OPTIONS;
    } else {
        // Merge the default values with the user values.
        NSMutableDictionary *opts = [NORMALIZED_OPTIONS mutableCopy];
        [opts addEntriesFromDictionary:options];
        
        return opts;
    }
}

//MARK: Setup/Init methods.

-(void)setupTexture:(CCTextureType)type rendertexture:(BOOL)rendertexture sizeInPixels:(CGSize)sizeInPixels options:(NSDictionary *)options;
{
    BOOL genMipmaps = [options[CCTextureOptionGenerateMipmaps] boolValue];
    
    CCTextureFilter minFilter = [options[CCTextureOptionMinificationFilter] unsignedIntegerValue];
    CCTextureFilter magFilter = [options[CCTextureOptionMagnificationFilter] unsignedIntegerValue];
    CCTextureFilter mipFilter = [options[CCTextureOptionMipmapFilter] unsignedIntegerValue];
    
    NSAssert(minFilter != CCTextureFilterMipmapNone, @"CCTextureFilterMipmapNone can only be used with CCTextureOptionMipmapFilter.");
    NSAssert(magFilter != CCTextureFilterMipmapNone, @"CCTextureFilterMipmapNone can only be used with CCTextureOptionMipmapFilter.");
    NSAssert(mipFilter == CCTextureFilterMipmapNone || genMipmaps, @"CCTextureOptionMipmapFilter must be CCTextureFilterMipmapNone unless CCTextureOptionGenerateMipmaps is YES");
    
    CCTextureAddressMode addressX = [options[CCTextureOptionAddressModeX] unsignedIntegerValue];
    CCTextureAddressMode addressY = [options[CCTextureOptionAddressModeY] unsignedIntegerValue];
    
    BOOL isPOT = CCSizeIsPOT(sizeInPixels);
    NSAssert(addressX == CCTextureAddressModeClampToEdge || isPOT, @"Only CCTextureAddressModeClampToEdge can be used with non power of two sized textures.");
    NSAssert(addressY == CCTextureAddressModeClampToEdge || isPOT, @"Only CCTextureAddressModeClampToEdge can be used with non power of two sized textures.");
    
    [self _setupTexture:type rendertexture:rendertexture sizeInPixels:sizeInPixels mipmapped:genMipmaps];
    [self _setupSampler:type minFilter:minFilter magFilter:magFilter mipFilter:mipFilter addressX:addressX addressY:addressY];
}

-(instancetype)initWithImage:(CCImage *)image options:(NSDictionary *)options;
{
    return [self initWithImage:image options:options rendertexture:NO];
}

-(instancetype)initWithImage:(CCImage *)image options:(NSDictionary *)options rendertexture:(BOOL)rendertexture;
{
    options = [CCTexture normalizeOptions:options];
    
    NSUInteger maxTextureSize = 4096;
    CGSize sizeInPixels = image.sizeInPixels;
    
    if(sizeInPixels.width > maxTextureSize || sizeInPixels.height > maxTextureSize){
        CCLOGWARN(@"cocos2d: Error: Image (%d x %d) is bigger than the maximum supported texture size %d",
            (int)sizeInPixels.width, (int)sizeInPixels.height, (int)maxTextureSize
        );
        
        return nil;
    }
    
	if((self = [super init])) {
        [self setupTexture:CCTextureType2D rendertexture:rendertexture sizeInPixels:sizeInPixels options:options];
        
        [self _uploadTexture2D:sizeInPixels miplevel:0 pixelData:image.pixelData.bytes];
        
        if([options[CCTextureOptionGenerateMipmaps] boolValue]){
            [self _generateMipmaps:CCTextureType2D];
        }
    
        _sizeInPixels = sizeInPixels;
        _contentScale = image.contentScale;
        _contentSizeInPixels = CC_SIZE_SCALE(image.contentSize, _contentScale);
    }
    
	return self;
}

-(instancetype)initWithMTLTexture:(id<MTLTexture>)tex options:(NSDictionary *)options {
    
    options = [CCTexture normalizeOptions:options];
    
    if (self = [super init]) {
        
        BOOL genMipmaps = [options[CCTextureOptionGenerateMipmaps] boolValue];
        
        CCTextureFilter minFilter = [options[CCTextureOptionMinificationFilter] unsignedIntegerValue];
        CCTextureFilter magFilter = [options[CCTextureOptionMagnificationFilter] unsignedIntegerValue];
        CCTextureFilter mipFilter = [options[CCTextureOptionMipmapFilter] unsignedIntegerValue];
        
        NSAssert(minFilter != CCTextureFilterMipmapNone, @"CCTextureFilterMipmapNone can only be used with CCTextureOptionMipmapFilter.");
        NSAssert(magFilter != CCTextureFilterMipmapNone, @"CCTextureFilterMipmapNone can only be used with CCTextureOptionMipmapFilter.");
        NSAssert(mipFilter == CCTextureFilterMipmapNone || genMipmaps, @"CCTextureOptionMipmapFilter must be CCTextureFilterMipmapNone unless CCTextureOptionGenerateMipmaps is YES");
        
        CCTextureAddressMode addressX = [options[CCTextureOptionAddressModeX] unsignedIntegerValue];
        CCTextureAddressMode addressY = [options[CCTextureOptionAddressModeY] unsignedIntegerValue];
        
        _metalTexture = tex;
        [self _setupSampler:CCTextureType2D minFilter:minFilter magFilter:magFilter mipFilter:mipFilter addressX:addressX addressY:addressY];
        
        if([options[CCTextureOptionGenerateMipmaps] boolValue]){
            [self _generateMipmaps:CCTextureType2D];
        }
        
        _sizeInPixels = CGSizeMake(tex.width, tex.height);
        _contentScale = 1.0;
        _contentSizeInPixels = CC_SIZE_SCALE(_sizeInPixels, _contentScale);
    }
    
    return self;
}
// -------------------------------------------------------------

- (BOOL)hasProxy
{
    @synchronized(self)
    {
        // NSLog(@"hasProxy: %p", self);
        return(_proxy != nil);
    }
}

- (CCProxy *)proxy
{
    @synchronized(self)
    {
        __strong CCProxy *proxy = _proxy;

        if (_proxy == nil)
        {
            proxy = [[CCProxy alloc] initWithTarget:self];
            _proxy = proxy;
        }
    
        return(proxy);
    }
}

-(CGSize)contentSize
{
    return CC_SIZE_SCALE(_contentSizeInPixels, 1.0/_contentScale);
}

// TODO should move this to the Metal/GL impls.
- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = %p | Dimensions = %lux%lu pixels >",
        [self class], self, (unsigned long)_sizeInPixels.width, (unsigned long)_sizeInPixels.height];
}

-(SpriteFrame*)spriteFrame
{
    if(_spriteFrame == nil){
        CGRect rect = {CGPointZero, self.contentSize};
        _spriteFrame = [[SpriteFrame alloc] initWithTexture:(CCTexture *)self.proxy rect:rect rotated:NO trimOffset:CGPointZero untrimmedSize:rect.size];
    }
    
    return _spriteFrame;
}

-(void)_setupTexture:(CCTextureType)type rendertexture:(BOOL)rendertexture sizeInPixels:(CGSize)sizeInPixels mipmapped:(BOOL)mipmapped;
{
    NSUInteger w = sizeInPixels.width;
    NSUInteger h = sizeInPixels.height;
    MTLPixelFormat format = (rendertexture ? MTLPixelFormatBGRA8Unorm : MTLPixelFormatRGBA8Unorm);
    MTLTextureDescriptor *textureDesc = nil;
    
    switch(type){
        case CCTextureType2D: textureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format width:w height:h mipmapped:mipmapped]; break;
        case CCTextureTypeCubemap: textureDesc = [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:format size:w mipmapped:mipmapped]; break;
    }
    
    if (rendertexture) {
        textureDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    }
    
    NSAssert(textureDesc, @"Bad texture type?");
    _metalTexture = [[CCMetalContext currentContext].device newTextureWithDescriptor:textureDesc];
}

-(void)_setupSampler:(CCTextureType)type
           minFilter:(CCTextureFilter)minFilter magFilter:(CCTextureFilter)magFilter mipFilter:(CCTextureFilter)mipFilter
            addressX:(CCTextureAddressMode)addressX addressY:(CCTextureAddressMode)addressY
{
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    
    static const MTLSamplerMinMagFilter FILTERS[] = {
        MTLSamplerMinMagFilterLinear, // Invalid, fall back to linear.
        MTLSamplerMinMagFilterNearest,
        MTLSamplerMinMagFilterLinear,
    };
    
    static const MTLSamplerMipFilter MIP_FILTERS[] = {
        MTLSamplerMipFilterNotMipmapped,
        MTLSamplerMipFilterNearest,
        MTLSamplerMipFilterLinear,
    };
    
    samplerDesc.minFilter = FILTERS[minFilter];
    samplerDesc.magFilter = FILTERS[magFilter];
    samplerDesc.mipFilter = MIP_FILTERS[mipFilter];
    
    static const MTLSamplerAddressMode ADDRESSING[] = {
        MTLSamplerAddressModeClampToEdge,
        MTLSamplerAddressModeRepeat,
        MTLSamplerAddressModeMirrorRepeat,
    };
    
    samplerDesc.sAddressMode = ADDRESSING[addressX];
    samplerDesc.tAddressMode = ADDRESSING[addressY];
    
    _metalSampler = [[CCMetalContext currentContext].device newSamplerStateWithDescriptor:samplerDesc];
}

-(void)_uploadTexture2D:(CGSize)sizeInPixels miplevel:(NSUInteger)miplevel pixelData:(const void *)pixelData
{
    if(pixelData){
        NSUInteger bytesPerRow = sizeInPixels.width*4;
        [_metalTexture replaceRegion:MTLRegionMake2D(0, 0, sizeInPixels.width, sizeInPixels.height) mipmapLevel:miplevel withBytes:pixelData bytesPerRow:bytesPerRow];
    }
}

-(void)_uploadTextureCubeFace:(NSUInteger)face sizeInPixels:(CGSize)sizeInPixels miplevel:(NSUInteger)miplevel pixelData:(const void *)pixelData
{
    if(pixelData){
        NSUInteger bytesPerRow = sizeInPixels.width*4;
        [_metalTexture replaceRegion:MTLRegionMake2D(0, 0, sizeInPixels.width, sizeInPixels.height) mipmapLevel:miplevel slice:face withBytes:pixelData bytesPerRow:bytesPerRow bytesPerImage:0];
    }
}

-(void)_generateMipmaps:(CCTextureType)type
{
    CCMetalContext *context = [CCMetalContext currentContext];
    
    // Set up a command buffer for the blit operations.
    id<MTLCommandBuffer> blitCommands = [context.commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> blitter = [blitCommands blitCommandEncoder];
    
    // Generate mipmaps and commit.
    [blitter generateMipmapsForTexture:_metalTexture];
    [blitter endEncoding];
    [blitCommands commit];
}

@end


@implementation CCTexture(Cubemap)

-(instancetype)initCubemapFromImagesPosX:(CCImage *)posX negX:(CCImage *)negX
                                    posY:(CCImage *)posY negY:(CCImage *)negY
                                    posZ:(CCImage *)posZ negZ:(CCImage *)negZ
                                    options:(NSDictionary *)options;
{
    options = [CCTexture normalizeOptions:options];
    
    NSUInteger maxTextureSize = 4096;
    CGSize sizeInPixels = posX.sizeInPixels;
    
    if(sizeInPixels.width > maxTextureSize || sizeInPixels.height > maxTextureSize){
        CCLOGWARN(@"cocos2d: Error: Image (%d x %d) is bigger than the maximum supported texture size %d",
            (int)sizeInPixels.width, (int)sizeInPixels.height, (int)maxTextureSize
        );
        
        return nil;
    }
    
	if((self = [super init])) {
        [self setupTexture:CCTextureTypeCubemap rendertexture:NO sizeInPixels:sizeInPixels options:options];
        
        [self _uploadTextureCubeFace:0 sizeInPixels:sizeInPixels miplevel:0 pixelData:posX.pixelData.bytes];
        [self _uploadTextureCubeFace:1 sizeInPixels:sizeInPixels miplevel:0 pixelData:negX.pixelData.bytes];
        [self _uploadTextureCubeFace:2 sizeInPixels:sizeInPixels miplevel:0 pixelData:posY.pixelData.bytes];
        [self _uploadTextureCubeFace:3 sizeInPixels:sizeInPixels miplevel:0 pixelData:negY.pixelData.bytes];
        [self _uploadTextureCubeFace:4 sizeInPixels:sizeInPixels miplevel:0 pixelData:posZ.pixelData.bytes];
        [self _uploadTextureCubeFace:5 sizeInPixels:sizeInPixels miplevel:0 pixelData:negZ.pixelData.bytes];
        
        // Generate mipmaps.
        if([options[CCTextureOptionGenerateMipmaps] boolValue]){
            [self _generateMipmaps:CCTextureTypeCubemap];
        }
    
        
        _type = CCTextureTypeCubemap;
        _sizeInPixels = sizeInPixels;
        _contentScale = posX.contentScale;
        _contentSizeInPixels = CC_SIZE_SCALE(posX.contentSize, _contentScale);
    }
    
	return self;
}

-(instancetype)initCubemapFromFilesPosX:(NSString *)posXFilePath negX:(NSString *)negXFilePath
                                   posY:(NSString *)posYFilePath negY:(NSString *)negYFilePath
                                   posZ:(NSString *)posZFilePath negZ:(NSString *)negZFilePath
                                   options:(NSDictionary *)options;
{
    NSMutableDictionary *opts = [options mutableCopy];
    opts[CCImageOptionFlipVertical] = @(YES);
    
    CCFileLocator *locator = [CCFileLocator sharedFileLocator];
    return [self initCubemapFromImagesPosX:[[CCImage alloc] initWithCCFile:[locator fileNamedWithResolutionSearch:posXFilePath error:nil] options:opts]
        negX:[[CCImage alloc] initWithCCFile:[locator fileNamedWithResolutionSearch:negXFilePath error:nil] options:opts]
        posY:[[CCImage alloc] initWithCCFile:[locator fileNamedWithResolutionSearch:posYFilePath error:nil] options:opts]
        negY:[[CCImage alloc] initWithCCFile:[locator fileNamedWithResolutionSearch:negYFilePath error:nil] options:opts]
        posZ:[[CCImage alloc] initWithCCFile:[locator fileNamedWithResolutionSearch:posZFilePath error:nil] options:opts]
        negZ:[[CCImage alloc] initWithCCFile:[locator fileNamedWithResolutionSearch:negZFilePath error:nil] options:opts]
        options:opts
    ];
}

-(instancetype)initCubemapFromFilePattern:(NSString *)aFilePathPattern options:(NSDictionary *)options;
{
	return [self initCubemapFromFilesPosX:[NSString stringWithFormat: aFilePathPattern, @"PosX"]
        negX:[NSString stringWithFormat:aFilePathPattern, @"NegX"]
        posY:[NSString stringWithFormat:aFilePathPattern, @"PosY"]
        negY:[NSString stringWithFormat:aFilePathPattern, @"NegY"]
        posZ:[NSString stringWithFormat:aFilePathPattern, @"PosZ"]
        negZ:[NSString stringWithFormat:aFilePathPattern, @"NegZ"]
        options:options
    ];
}

@end
