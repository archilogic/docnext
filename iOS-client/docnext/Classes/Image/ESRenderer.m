//
//  ESRenderer.m
//  docnext
//
//  Created by  on 11/10/26.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "ESRenderer.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface ESRenderer ()

@property(nonatomic) GLint backingWidth;
@property(nonatomic) GLint backingHeight;
@property(nonatomic) GLuint defaultFramebuffer;
@property(nonatomic) GLuint colorRenderbuffer;

@end

@implementation ESRenderer

@synthesize context;
@synthesize delegate;

@synthesize backingWidth;
@synthesize backingHeight;
@synthesize defaultFramebuffer;
@synthesize colorRenderbuffer;

- (id)init {
    self = [super init];
    
    if (self) {
        self.context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1] autorelease];
        
        if (!self.context || ![EAGLContext setCurrentContext:self.context]) {
            [self release];
            return nil;
        }
        
        GLuint framebuffer;
        glGenFramebuffersOES(1, &framebuffer);
        self.defaultFramebuffer = framebuffer;
        
        GLuint renderbuffer;
        glGenRenderbuffersOES(1, &renderbuffer);
        self.colorRenderbuffer = renderbuffer;
        
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, self.defaultFramebuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, self.colorRenderbuffer);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, self.colorRenderbuffer);
    }
    
    return self;
}

- (void)dealloc {
    if (self.defaultFramebuffer) {
        GLuint framebuffer = self.defaultFramebuffer;
        glDeleteFramebuffersOES(1, &framebuffer);
        self.defaultFramebuffer = 0;
    }
    
    if (self.colorRenderbuffer) {
        GLuint renderbuffer = self.colorRenderbuffer;
        glDeleteRenderbuffersOES(1, &renderbuffer);
        self.colorRenderbuffer = 0;
    }
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    self.context = nil;

    self.delegate = nil;
    
    [super dealloc];
}

#pragma mark public

- (void)render {
    [EAGLContext setCurrentContext:self.context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, self.defaultFramebuffer);
    glViewport(0, 0, self.backingWidth, self.backingHeight);
    
    [self.delegate performRender];
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, self.colorRenderbuffer);
    [self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer {
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, self.colorRenderbuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
    
    int width;
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &width);
    self.backingWidth = width;
    
    int height;
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &height);
    self.backingHeight = height;
    
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}

@end
