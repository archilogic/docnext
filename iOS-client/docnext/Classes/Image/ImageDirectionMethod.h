//
//  ImageDirectionMethod.h
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageCornerMethod.h"
#import "ImageState.h"
#import "ImageTypes.h"

@class ImageState;

@interface ImageDirectionMethod : NSObject

+ (BOOL)canMoveHorizontal:(ImageDirection)dir;
+ (BOOL)canMoveVertical:(ImageDirection)dir;
+ (ImageCorner)getCorner:(ImageDirection)dir isNext:(BOOL)isNext;
+ (BOOL)shouldChagneToNext:(ImageDirection)dir state:(ImageState *)state nPage:(int)nPage factor:(int)factor;
+ (BOOL)shouldChangeToPrev:(ImageDirection)dir state:(ImageState *)state nPage:(int)nPage factor:(int)factor;
+ (int)toXSign:(ImageDirection)dir;
+ (int)toYSign:(ImageDirection)dir;
+ (void)updateOffset:(ImageDirection)dir state:(ImageState *)state isNext:(BOOL)isNext nPage:(int)nPage;

@end
