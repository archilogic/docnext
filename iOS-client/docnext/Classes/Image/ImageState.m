//
//  ImageState.m
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "ImageState.h"
#import "ImageCleanupValue.h"
#import <limits.h>
#import "ImageLevelUtil.h"
#import "Utilities.h"
#import "ConfigProvider.h"
#import "LocalProviderUtil.h"
#import "ImageAnnotationInfo.h"
#import "OrientationUtil.h"
#import "AnnotationInfo.h"
#import "DebugLog.h"

#define EPSILON 0.001
#define FLING_VELOCITY_LIMIT 1000

@interface ImageState ()

@property(nonatomic) float minScale;
@property(nonatomic) float maxScale;
@property(nonatomic, retain) ImageCleanupValue* cleanup;
@property(nonatomic) BOOL preventCheckChangePage;
@property(nonatomic) BOOL willGoNextPage;
@property(nonatomic) BOOL willGoPrevPage;
@property(nonatomic) BOOL willTranslate;
@property(nonatomic) CGPoint willTranslatePoint;

@end

@implementation ImageState

@synthesize docId;
@synthesize page;
@synthesize pages;
@synthesize minLevel;
@synthesize maxLevel;
@synthesize image;
@synthesize matrix;
@synthesize pageSize;
@synthesize surfaceSize;
@synthesize direction;
@synthesize isInteracting;
@synthesize overlay;
@synthesize spreadFirstPages;
@synthesize loader;
@synthesize pageChangeListener;
@synthesize pageChanger;
@synthesize moviePresenter;

@synthesize minScale;
@synthesize maxScale;
@synthesize cleanup;
@synthesize preventCheckChangePage;
@synthesize willGoNextPage;
@synthesize willGoPrevPage;
@synthesize willTranslate;
@synthesize willTranslatePoint;

#pragma mark private

- (id)init {
    self = [super init];

    if (self) {
        self.page = 0;
        self.matrix = [[[ImageMatrix alloc] init] autorelease];
        self.isInteracting = NO;
        self.cleanup = [[[ImageCleanupValue alloc] init] autorelease];
        self.preventCheckChangePage = NO;
        self.willGoNextPage = NO;
        self.willGoPrevPage = NO;
        self.willTranslate = NO;
    }
    
    return self;
}

- (void)dealloc {
    self.docId = nil;
    self.image = nil;
    self.matrix = nil;
    self.overlay = nil;
    self.spreadFirstPages = nil;
    self.loader = nil;
    self.pageChangeListener = nil;
    self.pageChanger = nil;
    self.moviePresenter = nil;

    self.cleanup = nil;
    
    [super dealloc];
}

- (void)changeToNextPage {
    int delta;
    
    if ([OrientationUtil isSpreadMode]) {
        delta = self.nPageToShow;
        
        if ([self.spreadFirstPages containsObject:NUM_I(self.page + 1)]) {
            delta = self.direction == ImageDirectionR2L ? 2 : 1;
        }
        
        if (self.page + delta >= self.pages) {
            delta = 1;
        }
        
        if (delta == 1) {
#ifdef PRELOAD
            [self.loader unloadTop:self.page - 2];
            [self.loader unloadRest:self.page];
            [self.loader loadRest:self.page + 2];
            [self.loader loadTop:self.page + 4];
#else
            if (self.direction == ImageDirectionL2R) {
                if ([self.spreadFirstPages containsObject:NUM_I(self.page + 1)]) {
                    // case 0|1,2
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page + 1];
                    [self.loader loadTop:self.page + 2];
                    [self.loader loadRest:self.page + 1];
                    [self.loader loadRest:self.page + 2];
                } else {
                    // case 0|1
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page + 1];
                    [self.loader loadRest:self.page + 1];
                }
            } else {
                if ([self.spreadFirstPages containsObject:NUM_I(self.page)]) {
                    // case 1|0,-1
                    [self.loader unloadRest:self.page - 1];
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page - 1];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page + 1];
                    [self.loader loadRest:self.page + 1];
                } else {
                    // case 1|0
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page + 1];
                    [self.loader loadRest:self.page + 1];
                }
            }
#endif
        } else {
#ifdef PRELOAD
            [self.loader unloadTop:self.page - 2];
            [self.loader unloadTop:self.page - 1];
            [self.loader unloadRest:self.page];
            [self.loader unloadRest:self.page + 1];
            [self.loader loadRest:self.page + 2];
            [self.loader loadRest:self.page + 3];
            [self.loader loadTop:self.page + 4];
            [self.loader loadTop:self.page + 5];
#else
            if (self.direction == ImageDirectionL2R) {
                if ([self.spreadFirstPages containsObject:NUM_I(self.page + 2)]) {
                    // case 0,1|2,3
                    [self.loader unloadRest:self.page];
                    [self.loader unloadRest:self.page + 1];
                    [self.loader unloadTop:self.page];
                    [self.loader unloadTop:self.page + 1];
                    [self.loader loadTop:self.page + 2];
                    [self.loader loadTop:self.page + 3];
                    [self.loader loadRest:self.page + 2];
                    [self.loader loadRest:self.page + 3];
                } else {
                    // case 0,1|2
                    [self.loader unloadRest:self.page];
                    [self.loader unloadRest:self.page + 1];
                    [self.loader unloadTop:self.page];
                    [self.loader unloadTop:self.page + 1];
                    [self.loader loadTop:self.page + 2];
                    [self.loader loadRest:self.page + 2];
                }
            } else {
                if ([self.spreadFirstPages containsObject:NUM_I(self.page - 1)]) {
                    // case 2,1|0,-1
                    [self.loader unloadRest:self.page - 1];
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page - 1];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page + 1];
                    [self.loader loadTop:self.page + 2];
                    [self.loader loadRest:self.page + 1];
                    [self.loader loadRest:self.page + 2];
                } else {
                    // case 2,1|0
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page + 1];
                    [self.loader loadTop:self.page + 2];
                    [self.loader loadRest:self.page + 1];
                    [self.loader loadRest:self.page + 2];
                }
            }
#endif
        }
    } else {
        delta = 1;
        
#ifdef PRELOAD
        [self.loader unloadTop:self.page - 1];
        [self.loader unloadRest:self.page];
        [self.loader loadRest:self.page + 1];
        [self.loader loadTop:self.page + 2];
#else
        if ([OrientationUtil isIPhone]) {
            [self.loader unloadTop:self.page - 1];
            [self.loader unloadRest:self.page];
            [self.loader loadRest:self.page + 1];
            [self.loader loadTop:self.page + 2];
        } else {
            [self.loader unloadRest:self.page];
            [self.loader unloadTop:self.page];
            [self.loader loadTop:self.page + 1];
            [self.loader loadRest:self.page + 1];
        }
#endif
    }
    
    self.page += delta;
    
    [self.pageChangeListener pageChange:self.page];
    
    [ImageDirectionMethod updateOffset:self.direction state:self isNext:YES nPage:delta];

    if ([OrientationUtil isSpreadMode]) {
        self.matrix.tx -= self.horizontalMargin;
        self.matrix.tx -= [self horizontalPadding:self.nPageToShow] - [self horizontalPadding:[self nPageToShow:self.page - delta]];
    }
}

- (void)changeToPrevPage {
    int delta;
    
    if ([OrientationUtil isSpreadMode]) {
        delta = self.nPageToShow;
        
        if (self.direction == ImageDirectionR2L) {
            if (self.page == 1 && [self.spreadFirstPages containsObject:NUM_I(self.page - 1)]) {
                return;
            }
            
            if ([self.spreadFirstPages containsObject:NUM_I(self.page - 2)]) {
                delta = 1;
            }
        } else if (self.direction == ImageDirectionL2R) {
            delta = [self.spreadFirstPages containsObject:NUM_I(self.page - 2)] ? 2 : 1;
        }
        
        if (self.page - delta < 0) {
            delta = 1;
        }
        
        if (delta == 1) {
#ifdef PRELOAD
            [self.loader unloadTop:page + 3];
            [self.loader unloadRest:page + 1];
            [self.loader loadRest:page - 1];
            [self.loader loadTop:page - 3];
#else
            if (self.direction == ImageDirectionL2R) {
                if ([self.spreadFirstPages containsObject:NUM_I(self.page)]) {
                    // case -1|0,1
                    [self.loader unloadRest:self.page];
                    [self.loader unloadRest:self.page + 1];
                    [self.loader unloadTop:self.page];
                    [self.loader unloadTop:self.page + 1];
                    [self.loader loadTop:self.page - 1];
                    [self.loader loadRest:self.page - 1];
                } else {
                    // case -1|0
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page - 1];
                    [self.loader loadRest:self.page - 1];
                }
            } else {
                if ([self.spreadFirstPages containsObject:NUM_I(self.page - 2)]) {
                    // case 0|-1,-2
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page - 1];
                    [self.loader loadRest:self.page - 2];
                    [self.loader loadTop:self.page - 1];
                    [self.loader loadRest:self.page - 2];
                } else {
                    // case 0|-1
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page - 1];
                    [self.loader loadRest:self.page - 1];
                }
            }
#endif
        } else {
#ifdef PRELOAD
            [self.loader unloadTop:page + 3];
            [self.loader unloadTop:page + 2];
            [self.loader unloadRest:page + 1];
            [self.loader unloadRest:page];
            [self.loader loadRest:page - 1];
            [self.loader loadRest:page - 2];
            [self.loader loadTop:page - 3];
            [self.loader loadTop:page - 4];
#else
            if (self.direction == ImageDirectionL2R) {
                if ([self.spreadFirstPages containsObject:NUM_I(self.page)]) {
                    // case -2,-1|0,1
                    [self.loader unloadRest:self.page];
                    [self.loader unloadRest:self.page + 1];
                    [self.loader unloadTop:self.page];
                    [self.loader unloadTop:self.page + 1];
                    [self.loader loadTop:self.page - 1];
                    [self.loader loadTop:self.page - 2];
                    [self.loader loadRest:self.page - 1];
                    [self.loader loadRest:self.page - 2];
                } else {
                    // case -2,-1|0
                    [self.loader unloadRest:self.page];
                    [self.loader unloadTop:self.page];
                    [self.loader loadTop:self.page - 1];
                    [self.loader loadTop:self.page - 2];
                    [self.loader loadRest:self.page - 1];
                    [self.loader loadRest:self.page - 2];
                }
            } else {
                if ([self.spreadFirstPages containsObject:NUM_I(self.page - 3)]) {
                    // case 0,-1|-2,-3
                    [self.loader unloadRest:self.page];
                    [self.loader unloadRest:self.page - 1];
                    [self.loader unloadTop:self.page];
                    [self.loader unloadTop:self.page - 1];
                    [self.loader loadTop:self.page - 2];
                    [self.loader loadTop:self.page - 3];
                    [self.loader loadRest:self.page - 2];
                    [self.loader loadRest:self.page - 3];
                } else {
                    // case 0,-1|-2
                    [self.loader unloadRest:self.page];
                    [self.loader unloadRest:self.page - 1];
                    [self.loader unloadTop:self.page];
                    [self.loader unloadTop:self.page - 1];
                    [self.loader loadTop:self.page - 2];
                    [self.loader loadRest:self.page - 2];
                }
            }
#endif
        }
    } else {
        delta = 1;
        
#ifdef PRELOAD
        [self.loader unloadTop:page + 1];
        [self.loader unloadRest:page];
        [self.loader loadRest:page - 1];
        [self.loader loadTop:page - 2];
#else
        if ([OrientationUtil isIPhone]) {
            [self.loader unloadTop:page + 1];
            [self.loader unloadRest:page];
            [self.loader loadRest:page - 1];
            [self.loader loadTop:page - 2];
        } else {
            [self.loader unloadRest:page];
            [self.loader unloadTop:page];
            [self.loader loadTop:page - 1];
            [self.loader loadRest:page - 1];
        }
#endif
    }
    
    self.page -= delta;
    
    [self.pageChangeListener pageChange:self.page];

    [ImageDirectionMethod updateOffset:self.direction state:self isNext:NO nPage:delta];

    if ([OrientationUtil isSpreadMode]) {
        self.matrix.tx += self.horizontalMargin;
        self.matrix.tx += [self horizontalPadding:[self nPageToShow:self.page + delta]] - [self horizontalPadding:self.nPageToShow];
    }
}

- (BOOL)hasNextPage {
    return self.page + 1 < self.pages;
}

- (BOOL)hasPrevPage {
    return self.page - 1 >= 0;
}

// return isNext
- (NSNumber *)checkChangePage {
    if ([ImageDirectionMethod shouldChagneToNext:self.direction state:self nPage:self.nPageToShow factor:[OrientationUtil isIPhone] ? 1 : 2] && self.hasNextPage) {
        [self changeToNextPage];
        return NUM_B(YES);
    } else if([ImageDirectionMethod shouldChangeToPrev:self.direction state:self nPage:self.nPageToShow factor:[OrientationUtil isIPhone] ? 1 : 2] && self.hasPrevPage) {
        [self changeToPrevPage];
        return NUM_B(NO);
    }
    
    return nil;
}

- (void)checkCleanup {
    if (self.willTranslate) {
        self.willTranslate = NO;
        
        [self.cleanup calcTranslate:self.willTranslatePoint matrix:self.matrix];
    } else {
        ImageCorner corner = ImageCornerUndefined;
        
        if (self.preventCheckChangePage) {
            self.preventCheckChangePage = NO;
        } else if (self.willGoNextPage) {
            self.willGoNextPage = NO;
            
            [self changeToNextPage];
            corner = [ImageDirectionMethod getCorner:self.direction isNext:YES];
        } else if (self.willGoPrevPage) {
            self.willGoPrevPage = NO;
            
            [self changeToPrevPage];
            corner = [ImageDirectionMethod getCorner:self.direction isNext:NO];
        } else {
            NSNumber* isNext = self.checkChangePage;
            
            if (isNext) {
                corner = [ImageDirectionMethod getCorner:self.direction isNext:isNext.boolValue];
            }
        }
        
        [self.cleanup calcNormal:self.matrix minScale:self.minScale maxScale:self.maxScale page:self.pageSize surface:self.surfaceSize corner:corner nx:self.nPageToShow ny:1];
    }
}

- (void)changeFrameToLeft:(int)delta {
    BOOL spread = [OrientationUtil isSpreadMode];
    
    float right = self.surfaceSize.width - self.pageSize.width * self.matrix.scale * (spread ? 2 : 1);
    float bottom = self.surfaceSize.height - self.pageSize.height * self.matrix.scale;
    
    BOOL isLeft;
    BOOL isTop;
    
    if (delta > 0) { // prefer left bottom
        isLeft = self.matrix.tx > 0 - EPSILON;
        isTop = self.matrix.ty > bottom + EPSILON;
    } else { // prefer right top
        isLeft = self.matrix.tx > right + EPSILON;
        isTop = self.matrix.ty > 0 - EPSILON;
    }
    
    BOOL isHorizontal = !spread && [ConfigProvider readingDirection] == ConfigProviderReadingDirectionHorizontal;
    int hDelta = isHorizontal ? 0 : 1;
    
    int pos = (isLeft ? (isTop ? 1 + hDelta : 3) : (isTop ? 0 : 2 - hDelta)) + delta;
    
    if (pos == -1) {
        if (self.hasPrevPage) {
            self.willGoPrevPage = YES;
        }
    } else if(pos == 4) {
        if (self.hasNextPage) {
            self.willGoNextPage = YES;
        }
    } else {
        self.willTranslate = YES;
        if (isHorizontal) {
            self.willTranslatePoint = CGPointMake((pos % 2) ? 0 : right, (pos / 2) ? bottom : 0);
        } else {
            self.willTranslatePoint = CGPointMake((pos / 2) ? 0 : right, (pos % 2) ? bottom : 0);
        }
    }
}

- (void)changeFrameToRight:(int)delta {
    BOOL spread = [OrientationUtil isSpreadMode];
    
    float right = self.surfaceSize.width - self.pageSize.width * (spread ? 2 : 1) * self.matrix.scale;
    float bottom = self.surfaceSize.height - self.pageSize.height * self.matrix.scale;
    
    BOOL isLeft;
    BOOL isTop;
    
    if (delta > 0) { // prefer right bottom
        isLeft = self.matrix.tx > right + EPSILON;
        isTop = self.matrix.ty > bottom + EPSILON;
    } else { // prefer left top
        isLeft = self.matrix.tx > 0 - EPSILON;
        isTop = self.matrix.ty > 0 - EPSILON;
    }
    
    BOOL isHorizontal = !spread && [ConfigProvider readingDirection] == ConfigProviderReadingDirectionHorizontal;
    int hDelta = isHorizontal ? 0 : 1;
    
    int pos = (isLeft ? (isTop ? 0 : 2 - hDelta) : (isTop ? 1 + hDelta : 3)) + delta;
    
    if (pos == -1) {
        if (self.hasPrevPage) {
            self.willGoPrevPage = YES;
        }
    } else if(pos == 4) {
        if (self.hasNextPage) {
            self.willGoNextPage = YES;
        }
    } else {
        self.willTranslate = YES;
        if (isHorizontal) {
            self.willTranslatePoint = CGPointMake((pos % 2) ? right : 0, (pos / 2) ? bottom : 0);
        } else {
            self.willTranslatePoint = CGPointMake((pos / 2) ? right : 0, (pos % 2) ? bottom : 0);
        }
    }
}

- (void)changeFrame:(int)delta {
    if (self.direction == ImageDirectionL2R) {
        [self changeFrameToRight:delta];
    } else if(self.direction == ImageDirectionR2L) {
        [self changeFrameToLeft:delta];
    } else {
        assert(0);
    }
}

- (float)calcDoubleScale {
    return MIN(1.0 * self.surfaceSize.width / (self.pageSize.width * ([OrientationUtil isSpreadMode] ? 2 : 1)), 1.0 * self.surfaceSize.height / self.pageSize.height) * 2;
}

- (void)runAnnotation:(ImageAnnotationInfo *)imageAnnotation {
    AnnotationInfo* annotation = imageAnnotation.annotation;
    
    if ([annotation isKindOfClass:[PageLinkAnnotationInfo class]]) {
        PageLinkAnnotationInfo* pl = (PageLinkAnnotationInfo *)annotation;

        [self.pageChanger changePage:pl.page refresh:YES];
    } else if ([annotation isKindOfClass:[URILinkAnnotationInfo class]]) {
        URILinkAnnotationInfo* ul = (URILinkAnnotationInfo *)annotation;
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ul.uri]];
    } else if ([annotation isKindOfClass:[MovieAnnotationInfo class]]) {
        for (int delta = -1; delta <= 1; delta++) {
            [self.loader unloadRest:page + delta];
            
        }

        [self.moviePresenter showMovie:imageAnnotation];
    } else {
        assert(0);
    }
}

#pragma mark public

- (void)doubleTap:(CGPoint)point {
    [self.cleanup calcDoubleTap:point matrix:self.matrix minScale:self.minScale maxScale:self.maxScale surface:self.surfaceSize padding:self.padding];
}

- (void)drag:(CGPoint)delta {
    float EPS = 0.1f;
    
    if (self.surfaceSize.width + EPS >= self.pageSize.width * self.matrix.scale && ![ImageDirectionMethod canMoveHorizontal:self.direction]) {
        delta.x = 0;
    }
    
    if (self.surfaceSize.height + EPS >= self.pageSize.height * self.matrix.scale && ![ImageDirectionMethod canMoveVertical:self.direction]) {
        delta.y = 0;
    }
    
    self.matrix.tx += delta.x;
    self.matrix.ty += delta.y;
}

- (void)fling:(CGPoint)velocity {
    if ([self.matrix isInPage:self.surfaceSize page:self.pageSize nx:self.nPageToShow ny:1] && hypot(velocity.x, velocity.y) > FLING_VELOCITY_LIMIT) {
        [self.cleanup calcFling:velocity matrix:self.matrix page:self.pageSize surface:self.surfaceSize];
    }
}

- (CGSize)padding {
    return CGSizeMake([self horizontalPadding:self.nPageToShow], MAX(self.surfaceSize.height - self.pageSize.height * MAX(self.matrix.scale, self.minScale), 0 ) / 2);
}

- (float)horizontalMargin {
    return ceil(MAX(self.surfaceSize.width - self.pageSize.width * self.minScale, 0) / 2.0);
}

- (float)horizontalPadding:(int)nPage {
    return MAX(self.surfaceSize.width - self.pageSize.width * nPage * MAX(self.matrix.scale, self.minScale), 0) / 2;
}

- (void)initScale {
    BOOL onlyUseHorizontal = [OrientationUtil isIPhone] && [OrientationUtil isLandscape];
    float initScale = MIN(1.0 * self.surfaceSize.width / (self.pageSize.width * ([OrientationUtil isSpreadMode] ? 2 : 1)), onlyUseHorizontal ? 1e10 : 1.0 * self.surfaceSize.height / self.pageSize.height);
    
    self.minScale = MIN(initScale, self.calcDoubleScale);
    
    if ([OrientationUtil isSpreadMode]) {
        self.maxScale = MAX(self.maxLevel == self.image.maxLevel && self.image.isUseActualSize ? minLevel != maxLevel ? 1.0 * self.image.width / (TEXTURE_SIZE * pow(2, self.minLevel)) : 1 : pow(2, self.maxLevel - self.minLevel), MAX(initScale, self.calcDoubleScale));
    } else {
        self.maxScale = MAX(self.maxLevel == self.image.maxLevel && self.image.isUseActualSize ? 1.0 * self.image.width / self.surfaceSize.width : pow(2, self.maxLevel - self.minLevel), MAX(initScale, self.calcDoubleScale));
    }
    
    // workaround :(
    self.cleanup.isIn = NO;
    self.matrix.scale = initScale;
    self.matrix.tx = 0;
    self.matrix.ty = 0;
}

- (void)loadOverlay {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSMutableArray* buf = [NSMutableArray arrayWithCapacity:self.pages];
            
            for (int p = 0; p < self.pages; p++) {
                @autoreleasepool {
                    NSMutableArray* pBuf = [NSMutableArray array];
                    
                    for (AnnotationInfo* a in [LocalProviderUtil annotation:self.docId page:p]) {
                        [pBuf addObject:[ImageAnnotationInfo infoWithAnnotation:a]];
                    }
                    
                    [buf addObject:pBuf];
                }
            }
            
            self.overlay = buf;
        }
    });
}

- (BOOL)isCleanup {
    return self.cleanup.isIn;
}

- (BOOL)tap:(CGPoint)point {
    const int THREASHOLD = 4;
    
    int nDeleta = self.nPage;
    for (int delta = -nDeleta; delta <= nDeleta; delta++) {
        int p = self.page + delta;
        
        if (p >= 0 && p < self.pages) {
            for (ImageAnnotationInfo* i in AT(self.overlay, p)) {
                if (CGRectContainsPoint(i.frame, point)) {
                    [self runAnnotation:i];
                    return NO;
                }
            }
        }
    }
    
    if (point.y < self.surfaceSize.height / THREASHOLD || !(point.x < self.surfaceSize.width / THREASHOLD || point.x > self.surfaceSize.width - self.surfaceSize.width / THREASHOLD)) {
        return YES;
    }

    BOOL isFrameMode = fabs(self.matrix.scale - self.calcDoubleScale) < EPSILON;

    if (isFrameMode) {
        int w = self.surfaceSize.width / THREASHOLD;
        int sign  = self.direction == ImageDirectionL2R ? 1 : -1;
        
        if (point.x < w) {
            [self changeFrame:-1 * sign];
        } else if (point.x > self.surfaceSize.width - w) {
            [self changeFrame:1 * sign];
        }
    } else {
        float x = point.x - self.matrix.tx;
        float y = point.y - self.matrix.ty;
        int w = self.surfaceSize.width / THREASHOLD;
        int h = self.surfaceSize.height / THREASHOLD;
        
        int dx = x < w ? -1 : x > self.pageSize.width * self.matrix.scale * self.nPageToShow - w ? 1 : 0;
        int dy = y < h ? -1 : y > self.pageSize.height * self.matrix.scale - h ? 1 : 0;
        
        int delta = dx * [ImageDirectionMethod toXSign:self.direction] + dy * [ImageDirectionMethod toYSign:self.direction];
        
        if (delta > 0 && self.hasNextPage) {
            self.willGoNextPage = YES;
        } else if (delta < 0 && self.hasPrevPage) {
            self.willGoPrevPage = YES;
        }
    }
    
    return NO;
}

/**
 * Check cleanup, Check change page, etc...
 */
- (void)update {
    // obtain lock?
    if (!self.isInteracting) {
        if (!self.cleanup.isIn) {
            [self checkCleanup];
        }
        
        if (self.cleanup.isIn) {
            [self.cleanup update:self.matrix page:self.pageSize surface:self.surfaceSize nx:self.nPageToShow ny:1];
        }
    } else {
        self.cleanup.isIn = NO;
    }
}

- (void)zoom:(float)scale focus:(CGPoint)focus {
    // obtain lock?
    if (self.matrix.scale < self.minScale || self.matrix.scale > self.maxScale) {
        scale = pow(scale, 0.2);
    }
    
    CGSize beforePadding = self.padding;

    self.matrix.scale *= scale;
    
    CGSize afterPadding = self.padding;
    
    self.matrix.tx = scale * (self.matrix.tx - (focus.x - beforePadding.width)) + focus.x - afterPadding.width;
    self.matrix.ty = scale * (self.matrix.ty - (focus.y - beforePadding.height)) + focus.y - afterPadding.height;
    
    self.preventCheckChangePage = true;
}

- (int)nPage {
    return [OrientationUtil isSpreadMode] ? 2 : 1;
}

- (int)nPageToShow {
    return [self nPageToShow:self.page];
}

- (int)nPageToShow:(int)target {
    if ([OrientationUtil isSpreadMode]) {
        if (self.direction == ImageDirectionR2L && ![self.spreadFirstPages containsObject:NUM_I(target - 1)]) {
            return 1;
        }
        
        if (self.direction == ImageDirectionL2R && ![self.spreadFirstPages containsObject:NUM_I(target)]) {
            return 1;
        }
        
        return 2;
    } else {
        return 1;
    }
}

- (void)changeScaleToOrigin:(BOOL)toDouble {
    float toScale = toDouble ? self.calcDoubleScale : self.minScale;
    float tx = self.direction == ImageDirectionL2R ? 0 : (self.surfaceSize.width - self.pageSize.width * toScale * ([OrientationUtil isSpreadMode] ? 2 : 1));
    
    [self.cleanup calcScale:toScale tx:tx ty:0 matrix:self.matrix];
}

@end
