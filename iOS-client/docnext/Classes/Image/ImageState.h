//
//  ImageState.h
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageInfo.h"
#import "ImageMatrix.h"
#import "ImageDirectionMethod.h"
#import "ImageTypes.h"
#import "ImageViewController.h"

@protocol PageHolder <NSObject>

@property(nonatomic) int page;

@end

@interface ImageState : NSObject <PageHolder>

@property(nonatomic, retain) NSString* docId;
@property(nonatomic) int page;
@property(nonatomic) int pages;
@property(nonatomic) int minLevel;
@property(nonatomic) int maxLevel;
@property(nonatomic, retain) ImageInfo* image;
@property(nonatomic, retain) ImageMatrix* matrix;
@property(nonatomic) CGSize pageSize;
@property(nonatomic) CGSize surfaceSize;
@property(nonatomic) ImageDirection direction;
@property(nonatomic) BOOL isInteracting;
@property(nonatomic, retain) NSMutableArray* highlights;
@property(nonatomic, retain) NSSet* spreadFirstPages;
@property(nonatomic, assign) id<PageLoader> loader;
@property(nonatomic, assign) id<PageChangeListener> pageChangeListener;

- (void)doubleTap:(CGPoint)point;
- (void)drag:(CGPoint)delta;
- (void)fling:(CGPoint)velocity;
- (CGSize)padding;
- (float)horizontalMargin;
- (float)horizontalPadding:(int)nPage;
- (void)initScale;
- (BOOL)isCleanup;
- (void)tap:(CGPoint)point;
- (void)update;
- (void)zoom:(float)scale focus:(CGPoint)focus;
- (int)nPage;
- (int)nPageToShow;
- (int)nPageToShow:(int)target;
- (void)changeScaleToOrigin:(BOOL)toDouble;

@end
