//
//  ImageCleanupValue.h
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageMatrix.h"
#import "ImageTypes.h"

@interface ImageCleanupValue : NSObject

@property(nonatomic) BOOL isIn;
@property(nonatomic, retain) ImageMatrix* srcMat;
@property(nonatomic, retain) ImageMatrix* dstMat;
@property(nonatomic) BOOL shouldAdjust;
@property(nonatomic) double start;
@property(nonatomic) double duration;
@property(nonatomic) float goal;

- (void)calcDoubleTap:(CGPoint)point matrix:(ImageMatrix *)matrix minScale:(float)minScale maxScale:(float)maxScale surface:(CGSize)surface padding:(CGSize)padding;
- (void)calcFling:(CGPoint)velocity matrix:(ImageMatrix *)matrix page:(CGSize)page surface:(CGSize)surface;
- (void)calcLevelZoom:(ImageMatrix *)matrix minScale:(float)minScale maxScale:(float)maxScale surface:(CGSize)surface padding:(CGSize)padding delta:(int)delta;
- (void)calcNormal:(ImageMatrix *)matrix minScale:(float)minScale maxScale:(float)maxScale page:(CGSize)page surface:(CGSize)surface corner:(ImageCorner)corner nx:(int)nx ny:(int)ny;
- (void)calcScale:(float)scale tx:(float)tx ty:(float)ty matrix:(ImageMatrix *)matrix;
- (void)calcTranslate:(CGPoint)point matrix:(ImageMatrix *)matrix;
- (void)update:(ImageMatrix *)matrix page:(CGSize)page surface:(CGSize)surface nx:(int)nx ny:(int)ny;

@end
