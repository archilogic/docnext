//
//  ImageRenderEngine.h
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BindQueueItem.h"
#import "UnbindQueueItem.h"
#import "ImageState.h"

@interface ImageRenderEngine : NSObject

@property(nonatomic) int mod;
@property(atomic) BOOL suspend;

- (void)bindPageImage:(BindQueueItem *)item minLevel:(int)minLevel;
- (void)cleanup;
- (NSArray *)textureDimension:(int)page;
- (void)prepare:(int)nPage minLevel:(int)minLevel maxLevel:(int)maxLevel pageSize:(CGSize)pageSize surfaceSize:(CGSize)surfaceSize image:(ImageInfo *)image doc:(DocInfo *)doc;
- (void)render:(ImageState *)state;
- (void)unbindPageImage:(UnbindQueueItem *)item minLevel:(int)minLevel;

@end
