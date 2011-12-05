//
//  EAGLView.m
//  docnext
//
//  Created by  on 11/10/26.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "EAGLView.h"
#import "ESRenderer.h"

//#import <OpenGLES/EAGL.h>
//#import <OpenGLES/EAGLDrawable.h>
//#import <OpenGLES/ES1/gl.h>
//#import <OpenGLES/ES1/glext.h>
#import <QuartzCore/QuartzCore.h>

#define ANIMATION_FRAME_INTERVAL 1

@interface EAGLView ()

@property(nonatomic, retain) CADisplayLink* displayLink;

@end

@implementation EAGLView

@synthesize renderer;

@synthesize displayLink;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        CAEAGLLayer* eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        eaglLayer.contentsScale = [UIScreen mainScreen].scale;
        
        self.renderer = [[[ESRenderer alloc] init] autorelease];
        
        if (!self.renderer) {
            [self release];
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc {
    self.renderer = nil;
    
    self.displayLink = nil;
    
    [super dealloc];
}

- (void)drawView:(id)sender {
    [self.renderer render];
}

- (void)layoutSubviews {
    [self.renderer resizeFromLayer:(CAEAGLLayer *)self.layer];
    [self drawView:nil];
}

#pragma mark public

- (void)setRendererDelegate:(id<ESRendererDelegate>)delegate {
    self.renderer.delegate = delegate;
}

- (void)startAnimation {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
    [self.displayLink setFrameInterval:ANIMATION_FRAME_INTERVAL];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopAnimation {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

@end
