/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2015 Cocos2D Authors
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

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import "CCFileLocator.h"
#import "ccUtils.h"
#import "CCSetup.h"


#if __CC_PLATFORM_IOS
#import <UIKit/UIKit.h>
#endif

#if __CC_PLATFORM_ANDROID
#import "CCActivity.h"
#import "CCDirectorAndroid.h"

#import <AndroidKit/AndroidWindowManager.h>
#import <AndroidKit/AndroidDisplay.h>
#endif

#if __CC_PLATFORM_MAC
#import <AppKit/AppKit.h>
#endif


#if __CC_PLATFORM_MAC
@interface CCSetup() <NSWindowDelegate>
@end
#endif

NSString * const CCSetupPixelFormat = @"CCSetupPixelFormat";
NSString * const CCSetupScreenMode = @"CCSetupScreenMode";
NSString * const CCSetupScreenOrientation = @"CCSetupScreenOrientation";
NSString * const CCSetupFrameSkipInterval = @"CCSetupFrameSkipInterval";
NSString * const CCSetupFixedUpdateInterval = @"CCSetupFixedUpdateInterval";
NSString * const CCSetupShowDebugStats = @"CCSetupShowDebugStats";
NSString * const CCSetupTabletScale2X = @"CCSetupTabletScale2X";

NSString * const CCSetupDepthFormat = @"CCSetupDepthFormat";
NSString * const CCSetupPreserveBackbuffer = @"CCSetupPreserveBackbuffer";
NSString * const CCSetupMultiSampling = @"CCSetupMultiSampling";
NSString * const CCSetupNumberOfSamples = @"CCSetupNumberOfSamples";
NSString * const CCSetupScreenModeFixedDimensions = @"CCScreenModeFixedDimensions";

NSString * const CCScreenOrientationLandscape = @"CCScreenOrientationLandscape";
NSString * const CCScreenOrientationPortrait = @"CCScreenOrientationPortrait";
NSString * const CCScreenOrientationAll = @"CCScreenOrientationAll";

NSString * const CCScreenModeFlexible = @"CCScreenModeFlexible";
NSString * const CCScreenModeFixed = @"CCScreenModeFixed";

NSString * const CCMacDefaultWindowSize = @"CCMacDefaultWindowSize";


static CGFloat FindPOTScale(CGFloat size, CGFloat fixedSize)
{
    int scale = 1;
    while(fixedSize*scale < size) scale *= 2;

    return scale;
}

@implementation CCSetup {
    CCGraphicsAPI _graphicsAPI;
}

-(instancetype)init
{
    if((self = [super init])){
        _contentScale = 1.0;
        _assetScale = 1.0;
        _UIScale = 1.0;
        _fixedUpdateInterval = 1.0/60.0;
    }
    
    return self;
}

//MARK: Singleton

static CCSetup *
CCSetupSingleton(Class klass, BOOL useCustom)
{
    static CCSetup *sharedSetup = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSetup = [[klass alloc] init];
    });
    
    return sharedSetup;
}

+(void)createCustomSetup
{
    CCSetupSingleton([self class], YES);
}

+(instancetype)sharedSetup
{
    return CCSetupSingleton([self class], NO);
}

@end
