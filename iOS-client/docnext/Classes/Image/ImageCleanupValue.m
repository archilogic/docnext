//
//  ImageCleanupValue.m
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "ImageCleanupValue.h"
#import "ImageCornerMethod.h"

@implementation ImageCleanupValue

@synthesize isIn;
@synthesize srcMat;
@synthesize dstMat;
@synthesize shouldAdjust;
@synthesize start;
@synthesize duration;
@synthesize goal;

#pragma mark private

- (id)init {
    self = [super init];

    if (self) {
        self.isIn = NO;
        self.srcMat = [[[ImageMatrix alloc] init] autorelease];
        self.dstMat = [[[ImageMatrix alloc] init] autorelease];
    }
    
    return self;
}

- (void)dealloc {
    self.srcMat = nil;
    self.dstMat = nil;
    
    [super dealloc];
}

- (void)calcZoom:(CGPoint)point matrix:(ImageMatrix *)matrix surface:(CGSize)surface padding:(CGSize)padding dstScale:(float)dstScale {
    [self.srcMat set:matrix];
    [self.dstMat set:dstScale tx:dstScale / matrix.scale * (matrix.tx - (point.x - padding.width)) + surface.width / 2 ty:dstScale / matrix.scale * (matrix.ty - (point.y - padding.height) ) + surface.height / 2];

    self.shouldAdjust = YES;
    self.start = CFAbsoluteTimeGetCurrent();
    self.duration = 0.25;
    self.goal = -1;
    
    self.isIn = YES;
}

- (int)numberOfZoomLevel:(float)minScale maxScale:(float)maxScale {
    return ceil(log(maxScale / minScale) / log(2));
}

- (float)cubicEaseOut:(float)value {
    return 1 - pow(1 - value, 3);
}

#pragma mark public

- (void)calcDoubleTap:(CGPoint)point matrix:(ImageMatrix *)matrix minScale:(float)minScale maxScale:(float)maxScale surface:(CGSize)surface padding:(CGSize)padding {
    float dstScale;
    
    if (matrix.scale < maxScale) {
        // 1.01 for rounding
        float delta = (float)pow(maxScale / minScale, 1.01 / [self numberOfZoomLevel:minScale maxScale:maxScale]);
        
        dstScale = MIN(maxScale, delta * matrix.scale);
    } else {
        dstScale = minScale;
    }
    
    [self calcZoom:point matrix:matrix surface:surface padding:padding dstScale:dstScale];
}

- (void)calcFling:(CGPoint)velocity matrix:(ImageMatrix *)matrix page:(CGSize)page surface:(CGSize)surface {
    [self.srcMat set:matrix];
    
    // divide by 2 is for interpolation (smoothing)
    float dx = velocity.x / 3;
    float dy = velocity.y / 3;
    
    [self.dstMat set:matrix.scale tx:matrix.tx + dx ty:matrix.ty + dy];
    
    self.shouldAdjust = YES;
    self.start = CFAbsoluteTimeGetCurrent();
    self.duration = 1;
    
    float xLimit = velocity.x > 0 ? -matrix.tx / dx : (surface.width - page.width * matrix.scale - matrix.tx) / dx;
    float yLimit = velocity.y > 0 ? -matrix.ty / dy : (surface.height - page.height * matrix.scale - matrix.ty) / dy;
    
    self.goal = MIN(MAX(xLimit, yLimit), 1);
    
    self.isIn = YES;
}

- (void)calcLevelZoom:(ImageMatrix *)matrix minScale:(float)minScale maxScale:(float)maxScale surface:(CGSize)surface padding:(CGSize)padding delta:(int)delta {
    // 1.01 for rounding
    float scaleDelta = (float)pow(maxScale / minScale, 1.01 / [self numberOfZoomLevel:minScale maxScale:maxScale] * delta );
    
    float dstScale = MAX(minScale, MIN(maxScale, scaleDelta * matrix.scale));
    
    [self calcZoom:CGPointMake(surface.width / 2, surface.height / 2) matrix:matrix surface:surface padding:padding dstScale:dstScale];
}

// This method has a bug. Since not consider padding, always set isIn = true
- (void)calcNormal:(ImageMatrix *)matrix minScale:(float)minScale maxScale:(float)maxScale page:(CGSize)page surface:(CGSize)surface corner:(ImageCorner)corner nx:(int)nx ny:(int)ny {
    if (matrix.scale < minScale || matrix.scale > maxScale || matrix.tx > 0 || matrix.ty > 0 || matrix.tx < surface.width - page.width * matrix.scale * nx || matrix.ty < surface.height - page.height * matrix.scale * ny) {
        [self.srcMat set:matrix];
        
        if (matrix.scale < minScale) {
            [self.dstMat set:minScale tx:0 ty:0];
        } else if (matrix.scale > maxScale) {
            [self.dstMat set:maxScale tx:(maxScale * matrix.tx - (maxScale - matrix.scale) * surface.width / 2) / matrix.scale ty:(maxScale * matrix.ty - (maxScale - matrix.scale) * surface.height / 2)
             / matrix.scale];
        } else {
            if (corner != ImageCornerUndefined) {
                [self.dstMat set:matrix.scale tx:[ImageCornerMethod x:corner scale:matrix.scale surface:surface page:page nPage:nx] ty:[ImageCornerMethod y:corner scale:matrix.scale surface:surface page:page nPage:ny]];
            } else {
                [self.dstMat set:matrix];
            }
            
            [self.dstMat adjust:surface page:page nx:nx ny:ny];
        }
        
        self.shouldAdjust = NO;
        self.start = CFAbsoluteTimeGetCurrent();
        self.duration = 0.2;
        self.goal = -1;
        
        self.isIn = YES;
    } else {
        self.isIn = NO;
    }
}

- (void)calcScale:(float)scale matrix:(ImageMatrix *)matrix surface:(CGSize)surface page:(CGSize)page padding:(CGSize)padding nx:(int)nx {
    [self.srcMat set:matrix];
    [self.dstMat set:scale tx:surface.width - page.width * scale * nx ty:0];
    
    self.shouldAdjust = YES;
    self.start = CFAbsoluteTimeGetCurrent();
    self.duration = 0.25;
    self.goal = -1;
    
    self.isIn = YES;
}

- (void)calcTranslate:(CGPoint)point matrix:(ImageMatrix *)matrix {
    [self.srcMat set:matrix];
    [self.dstMat set:matrix.scale tx:point.x ty:point.y];
    
    self.shouldAdjust = YES;
    self.start = CFAbsoluteTimeGetCurrent();
    self.duration = 0.25;
    self.goal = -1;
    
    self.isIn = YES;
}

- (void)update:(ImageMatrix *)matrix page:(CGSize)page surface:(CGSize)surface nx:(int)nx ny:(int)ny {
    float elapsed = (CFAbsoluteTimeGetCurrent() - self.start) / self.duration;
    
    BOOL willFinish = NO;
    
    if (elapsed > 1) {
        elapsed = 1;
        willFinish = YES;
    }
    
    float val = [self cubicEaseOut:elapsed];
    
    if (goal > 0 && val > goal) {
        willFinish = YES;
    }
    
    [matrix interpolate:val src:self.srcMat dst:self.dstMat];
    
    if (self.shouldAdjust) {
        [matrix adjust:surface page:page nx:nx ny:ny];
    }
    
    if (willFinish) {
        self.isIn = false;
    }
}

@end
