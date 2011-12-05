//
//  EAGLView.h
//  docnext
//
//  Created by  on 11/10/26.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESRenderer.h"

@interface EAGLView : UIView

@property(nonatomic, retain) ESRenderer* renderer;

- (void)setRendererDelegate:(id<ESRendererDelegate>)delegate;
- (void)startAnimation;
- (void)stopAnimation;

@end
