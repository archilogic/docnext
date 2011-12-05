//
//  ESRenderer.h
//  docnext
//
//  Created by  on 11/10/26.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@protocol ESRendererDelegate <NSObject>

- (void)performRender;

@end

@interface ESRenderer : NSObject

@property(nonatomic, retain) EAGLContext* context;
@property(nonatomic, assign) id<ESRendererDelegate> delegate;

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer*)layer;

@end
