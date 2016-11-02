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


#import <zlib.h>


#import "CCFile_Private.h"
#import "Fiber2D-Swift.h"

#pragma mark Wrapped Streams

#define BUFFER_SIZE 32*1024

@implementation CCWrappedInputStream {
    @protected
    NSInputStream *_inputStream;
    BOOL _hasBytesAvailable;
    
    NSError *_error;
}

// Make the designated initializer warnings go away.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
-(instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    if((self = [super init])){
        _inputStream = inputStream;
        _hasBytesAvailable = YES;
    }
    
    return self;
}
#pragma clang diagnostic pop

-(instancetype)initWithURL:(NSURL *)url
{
    return [self initWithInputStream:[NSInputStream inputStreamWithURL:url]];
}

// Forward most of the methods on to the regular input stream object.
-(void)open{[_inputStream open];}
-(void)close {[_inputStream close];}
-(id<NSStreamDelegate>)delegate {return _inputStream.delegate;}
-(void)setDelegate:(id<NSStreamDelegate>)delegate {_inputStream.delegate = delegate;}
-(void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode {[_inputStream scheduleInRunLoop:runLoop forMode:mode];}
-(void)removeFromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode {[_inputStream removeFromRunLoop:runLoop forMode:mode];}
-(id)propertyForKey:(NSString *)key {return [_inputStream propertyForKey:key];}
-(BOOL)setProperty:(id)property forKey:(NSString *)key {return [_inputStream setProperty:property forKey:key];}

-(NSStreamStatus)streamStatus {
    if(_error){
        return NSStreamStatusError;
    } else {
        return _inputStream.streamStatus;
    }
}

-(NSError *)streamError {
    return (_error ?: _inputStream.streamError);
}

-(BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len
{
    return NO;
}

-(BOOL)hasBytesAvailable
{
    return _hasBytesAvailable;
}

-(NSData *)loadDataWithSizeHint:(NSUInteger)sizeHint error:(NSError **)error;
{
    NSMutableData *data = [NSMutableData dataWithLength:(sizeHint ?: BUFFER_SIZE)];
    NSUInteger totalBytesRead = 0;
    
    for(;;){
        totalBytesRead += [self read:data.mutableBytes + totalBytesRead maxLength:data.length - totalBytesRead];
        if(!self.hasBytesAvailable) break;
        
        [data increaseLengthBy:data.length*0.5];
    }
    
    if(self.streamStatus == NSStreamStatusError){
        if(error) *error = self.streamError;
    }
    
    data.length = totalBytesRead;
    return data;
}

@end

//MARK CCFileCGDataProvider

@implementation CCStreamedImageSource{
    CCStreamedImageSourceStreamBlock _streamBlock;
    NSInputStream *_inputStream;
}

-(instancetype)initWithStreamBlock:(CCStreamedImageSourceStreamBlock)streamBlock
{
    if((self = [super init])){
        _streamBlock = streamBlock;
    }
    
    return self;
}

-(NSInputStream *)inputStream
{
    if(_inputStream == nil){
        _inputStream = _streamBlock();
    }
    
    return _inputStream;
}

static size_t
DataProviderGetBytesCallback(void *info, void *buffer, size_t count)
{
    CCStreamedImageSource *provider = (__bridge CCStreamedImageSource *)info;
    return [provider.inputStream read:buffer maxLength:count];
}

static off_t
DataProviderSkipForwardCallback(void *info, off_t count)
{
    CCStreamedImageSource *provider = (__bridge CCStreamedImageSource *)info;
    
    // Skip forward in 32 kb chunks.
    const NSUInteger bufferSize = 32*1024;
    uint8_t buffer[bufferSize];
    
    NSUInteger skipped = 0;
    while(skipped < count){
        NSUInteger skip = MIN(bufferSize, (NSUInteger)count - skipped);
        skipped += [provider.inputStream read:buffer maxLength:skip];
        if(!provider.inputStream.hasBytesAvailable) break;
    }
    
    return skipped;
}

static void
DataProviderRewindCallback(void *info)
{
    CCStreamedImageSource *provider = (__bridge CCStreamedImageSource *)info;
    [provider->_inputStream close];
    provider->_inputStream = nil;
}

static void
DataProviderReleaseInfoCallback(void *info)
{
    //Close and discard the current input stream.
    DataProviderRewindCallback(info);
    
    CFRelease(info);
}

static const CGDataProviderSequentialCallbacks callbacks = {
    .version = 0,
    .getBytes = DataProviderGetBytesCallback,
    .skipForward = DataProviderSkipForwardCallback,
    .rewind = DataProviderRewindCallback,
    .releaseInfo = DataProviderReleaseInfoCallback,
};

-(CGDataProviderRef)createCGDataProvider
{
    return CGDataProviderCreateSequential((__bridge_retained void *)self, &callbacks);
}

-(CGImageSourceRef)createCGImageSource
{
    CGDataProviderRef provider = [self createCGDataProvider];
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    
    CGDataProviderRelease(provider);
    return source;
}

@end

#pragma mark CCFile

@implementation CCFile {
    Class _inputStreamClass;
    BOOL _loadDataFromStream;
}

-(instancetype)initWithName:(NSString *)name url:(NSURL *)url contentScale:(CGFloat)contentScale tagged:(BOOL)tagged;
{
    if((self = [super init])){
        _name = [name copy];
        _url = [url copy];
        _contentScale = contentScale;
        _hasResolutionTag = tagged;
        
        _inputStreamClass = [NSInputStream class];
        _loadDataFromStream = NO;
    }
    
    return self;
}

-(NSString *)absoluteFilePath
{
    if(_url.isFileURL){
        return _url.path;
    } else {
        return nil;
    }
}

-(CGFloat)autoScaleFactor
{
    if(self.hasResolutionTag){
        return 1.0;
    } else {
        /*float relativeScale = MAX(1.0, self.contentScale/[CCSetup sharedSetup].assetScale);
        return 1.0/ CCNextPOT(relativeScale;*/
        float relativeScale = MAX(1.0, self.contentScale / [Setup sharedInstance].assetScale);
        return 1.0 / CCNextPOT(relativeScale);
    }
}

-(NSInputStream *)openInputStream
{
    NSInputStream *stream = [_inputStreamClass inputStreamWithURL:self.url];
    
    if(stream == nil){
        //CCLOG(@"Error opening stream for %@", self.name);
    }
    
    [stream open];
    return stream;
}

-(id)loadPlist:(NSError *__autoreleasing *)error
{
    NSInputStream *stream = [self openInputStream];
    id plist = [NSPropertyListSerialization propertyListWithStream:stream options:0 format:NULL error:error];
    
    [stream close];
    
    if(error && *error){
        //CCLOG(@"Error reading property list from %@: %@", self.name, *error);
        return nil;
    } else {
        return plist;
    }
}

-(NSData *)loadData:(NSError *__autoreleasing *)error
{
    if(_loadDataFromStream){
       CCWrappedInputStream *stream = (CCWrappedInputStream *)[self openInputStream];
       NSData *data = [stream loadDataWithSizeHint:0 error:error];
       [stream close];
       
        return data; 
    } else {
        NSData *data = [NSData dataWithContentsOfURL:_url options:NSDataReadingMappedIfSafe error:error];
        
        if(error && *error){
            //CCLOG(@"Error reading data from from %@: %@", self.name, *error);
            return nil;
        } else {
            return data;
        }
    }
}

-(NSString *)loadString:(NSError **)error;
{
    return [[NSString alloc] initWithData:[self loadData:error] encoding:NSUTF8StringEncoding];
}

-(CGImageSourceRef)createCGImageSource
{
    if(_loadDataFromStream){
        CCStreamedImageSource *source = [[CCStreamedImageSource alloc] initWithStreamBlock:^{return [self openInputStream];}];
        return [source createCGImageSource];
    } else {
        return CGImageSourceCreateWithURL((__bridge CFURLRef)self.url, NULL);
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; Absolute path: '%@', UIScale: %d, scale %.2f>", [self class], (void *) self, self.absoluteFilePath, _useUIScale, _contentScale];
}

@end
