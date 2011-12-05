//
//  BindQueueItem.h
//  docnext
//
//  Created by  on 11/10/06.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface BindQueueItem : NSObject

@property(nonatomic) int page;
@property(nonatomic) int level;
@property(nonatomic) int px;
@property(nonatomic) int py;
@property(nonatomic) GLubyte* data;

+ (BindQueueItem *)itemWithParam:(int)page level:(int)level px:(int)px py:(int)py data:(GLubyte *)data;

@end
