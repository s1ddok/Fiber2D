/*
 * Cocos2D-SpriteBuilder: http://cocos2d.spritebuilder.com
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 * Copyright (c) 2013-2014 Cocos2D Authors
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
 *
 */



#import "Fiber2D-Swift.h"
#import "ccMacros.h"

#import "CCAction_Private.h"

#import "CCActionInterval.h"
#import "CGPointExtension.h"

//
// Action Base Class
//
#pragma mark -
#pragma mark Action
@implementation CCAction

+(instancetype) action
{
	return [[self alloc] init];
}

-(NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = %p | Name = %@>", [self class], self, _name];
}

-(id) copyWithZone: (NSZone*) zone
{
	CCAction *copy = [[[self class] allocWithZone: zone] init];
	copy.name = _name;
    
	return copy;
}

-(void) startWithTarget:(id)aTarget
{
	_target = aTarget;
}

-(void) stop
{
	_target = nil;
}

-(BOOL) isDone
{
	return YES;
}

-(void) step: (CCTime) dt
{
	NSAssert(NO, @"[CCAction step] override me");
}

-(void) update: (CCTime) time
{
	NSAssert(NO, @"[CCAction update] override me");
}
@end

//
// FiniteTimeAction
//
#pragma mark -
#pragma mark FiniteTimeAction
@implementation CCActionFiniteTime
@synthesize duration = _duration;

- (CCActionFiniteTime*) reverse
{
	NSAssert(NO, @"[CCFiniteTimeAction reverse:] override me");
	return nil;
}
@end


//
// RepeatForever
//
#pragma mark -
#pragma mark RepeatForever
@implementation CCActionRepeatForever
@synthesize innerAction=_innerAction;
+(instancetype) actionWithAction: (CCActionInterval*) action
{
	return [[self alloc] initWithAction: action];
}

-(id) initWithAction: (CCActionInterval*) action
{
	if( (self=[super init]) )
		self.innerAction = action;

	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	CCAction *copy = [[[self class] allocWithZone: zone] initWithAction:[_innerAction copy] ];
    return copy;
}


-(void) startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	[_innerAction startWithTarget:_target];
}

-(void) step:(CCTime) dt
{
	[_innerAction step: dt];
	if( [_innerAction isDone] ) {
		CCTime diff = _innerAction.elapsed - _innerAction.duration;
		[_innerAction startWithTarget:_target];

		// to prevent jerk. issue #390, 1247
		[_innerAction step: 0.0f];
		[_innerAction step: diff];
	}
}


-(BOOL) isDone
{
	return NO;
}

- (CCActionInterval *) reverse
{
	return [CCActionRepeatForever actionWithAction:[_innerAction reverse]];
}
@end

//
// Speed
//
#pragma mark -
#pragma mark Speed
@implementation CCActionSpeed
@synthesize speed=_speed;
@synthesize innerAction=_innerAction;

+(instancetype) actionWithAction: (CCActionInterval*) action speed:(CGFloat)value
{
	return [[self alloc] initWithAction: action speed:value];
}

-(id) initWithAction: (CCActionInterval*) action speed:(CGFloat)value
{
	if( (self=[super init]) ) {
		self.innerAction = action;
		_speed = value;
	}
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	CCAction *copy = [[[self class] allocWithZone: zone] initWithAction:[_innerAction copy] speed:_speed];
    return copy;
}


-(void) startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	[_innerAction startWithTarget:_target];
}

-(void) stop
{
	[_innerAction stop];
	[super stop];
}

-(void) step:(CCTime) dt
{
	[_innerAction step: dt * _speed];
}

-(BOOL) isDone
{
	return [_innerAction isDone];
}

- (CCActionInterval *) reverse
{
	return [CCActionSpeed actionWithAction:[_innerAction reverse] speed:_speed];
}
@end


