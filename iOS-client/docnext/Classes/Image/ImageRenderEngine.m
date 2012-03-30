//
//  ImageRenderEngine.m
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "ImageRenderEngine.h"
#import "TextureInfo.h"
#import "ImageMatrix.h"
#import "PageInfo.h"
#import "ImageDirectionMethod.h"
#import "ImageLevelUtil.h"
#import "Utilities.h"
#import "ImageAnnotationInfo.h"
#import "OrientationUtil.h"

#define PAGE_SPACE 30
#define MOVIE_ANNOTATION_BLINK_DURATION 0.5

@interface ImageRenderEngine ()

@property(nonatomic, retain) TextureInfo* background;
@property(nonatomic, retain) TextureInfo* blank;
@property(nonatomic, retain) TextureInfo* red;
@property(nonatomic, retain) TextureInfo* darkBlack;
@property(nonatomic, retain) TextureInfo* lightBlack;
@property(nonatomic, retain) NSArray* pages;
@property(nonatomic) int nPage;
@property(nonatomic, retain) ImageMatrix* immutableMatrix;
@property(nonatomic) CGSize immutablePadding;
@property(nonatomic, retain) NSArray* toPortraitPage;

@end

@implementation ImageRenderEngine

@synthesize mod;
@synthesize suspend;

@synthesize background;
@synthesize blank;
@synthesize red;
@synthesize darkBlack;
@synthesize lightBlack;
@synthesize pages;
@synthesize nPage;
@synthesize immutableMatrix;
@synthesize immutablePadding;
@synthesize toPortraitPage;

#pragma mark private

- (id)init {
    self = [super init];

    if (self) {
        self.immutableMatrix = [[[ImageMatrix alloc] init] autorelease];
        self.suspend = NO;
    }
    
    return self;
}

- (void)dealloc {
    self.background = nil;
    self.blank = nil;
    self.red = nil;
    self.darkBlack = nil;
    self.lightBlack = nil;
    self.pages = nil;
    self.immutableMatrix = nil;
    self.toPortraitPage = nil;
    
    [super dealloc];
}

- (void)drawSingleImage:(GLuint)texId x:(int)x y:(int)y w:(int)w h:(int)h {
    glBindTexture(GL_TEXTURE_2D, texId);
    glDrawTexiOES(x, y, 0, w, h);
}

- (void)checkAndDrawSingleImage:(BOOL)isFirst textures:(NSArray *)textures statuses:(NSArray *)statuses py:(int)py px:(int)px x:(int)x y:(int)y w:(int)w h:(int)h surface:(CGSize)surface {
    BOOL isVisible = x + w >= 0 && x < surface.width && y + h >= 0 && y < surface.height;
    
    if (isVisible) {
        if (AT2_AS(statuses, py, px, NSNumber).boolValue) {
            [self drawSingleImage:AT2_AS(textures, py, px, TextureInfo).texId x:x y:y w:w h:h];
        } else if (isFirst) {
            [self drawSingleImage:self.blank.texId x:x y:y w:w h:h];
        }
    }
}

- (void)drawBackground {
    [self drawSingleImage:self.background.texId x:0 y:0 w:self.background.size.width h:self.background.size.height];
}

- (void)drawBigBackground {
    if (self.background.size.width > self.background.size.height) {
        [self drawSingleImage:self.background.texId x:0 y:0 w:self.background.size.width h:self.background.size.height];
        [self drawSingleImage:self.background.texId x:0 y:self.background.size.height w:self.background.size.width h:self.background.size.height];
    } else {
        [self drawSingleImage:self.background.texId x:0 y:0 w:self.background.size.width h:self.background.size.height];
        [self drawSingleImage:self.background.texId x:self.background.size.width y:0 w:self.background.size.width h:self.background.size.height];
    }
}

- (CGSize)pageSpacing:(ImageMatrix *)matrix state:(ImageState *)state page:(int)page delta:(int)delta {
    if ([OrientationUtil isSpreadMode]) {
        int xSign = [ImageDirectionMethod toXSign:state.direction];
        
        float width = 0;
        
        float margin = state.horizontalMargin;
        
        for (int i = -1; i >= delta; i--) {
            if (![state.spreadFirstPages containsObject:NUM_I(page + i - delta)]) {
                width -= margin * xSign;
            }
        }
        
        for (int i = 1; i <= delta; i++) {
            if (![state.spreadFirstPages containsObject:NUM_I(page + i - delta - 1)]) {
                width += margin * xSign;
            }
        }
        
        return CGSizeMake(width, 0);
    } else {
        int xSign = [ImageDirectionMethod toXSign:state.direction];
        int ySign = [ImageDirectionMethod toYSign:state.direction];
        
        float top = 0;
        float bottom = 0;
        float left = 0;
        float right = 0;
        
        if ([state.spreadFirstPages containsObject:NUM_I(page)]) {
            top = right = PAGE_SPACE;
        } else if (page - 1 >= 0 && [state.spreadFirstPages containsObject:NUM_I(page - 1)]) {
            bottom = left = PAGE_SPACE;
        } else {
            top = bottom = left = right = PAGE_SPACE;
        }
        
        float width = delta != 0 ? (delta == 1 ? [matrix length:right] : [matrix length:left]) * xSign * delta : 0;
        float height = delta != 0 ? (delta == 1 ? [matrix length:top] : [matrix length:bottom]) * ySign * delta * -1 : 0;
        
        
        return CGSizeMake(width, height);
    }
}

- (void)drawImage:(ImageMatrix *)matrix padding:(CGSize)padding state:(ImageState *)state {
    int xSign = [ImageDirectionMethod toXSign:state.direction];
    int ySign = [ImageDirectionMethod toYSign:state.direction];
    
    for (int level = state.minLevel; level <= state.maxLevel; level++) {
        if (level > state.minLevel && (matrix.scale < pow(2, level - state.minLevel - 1))) {
            break;
        }
        
        float factor;
        
        if (level != state.image.maxLevel || !state.image.isUseActualSize) {
            factor = pow(2, level - state.minLevel);
        } else {
            factor = level != state.minLevel ? state.image.width / (TEXTURE_SIZE * pow(2, state.minLevel)) : 1;
        }
        
        int nDeleta = state.nPage;
        for (int delta = -nDeleta; delta <= nDeleta; delta++) {
            int page = state.page + delta;
            
            if (page >= 0 && page < self.nPage) {
                CGSize pageSpacing = [self pageSpacing:matrix state:state page:page delta:delta];

                if (AT(self.toPortraitPage, page) == [NSNull null]) {
                    int x = rint([matrix x:0] + padding.width + [matrix length:state.pageSize.width - 1] * delta * xSign) + pageSpacing.width;
                    int y = rint(state.surfaceSize.height - ([matrix y:0] + padding.height + [matrix length:state.pageSize.height - 1] * delta * ySign)) + pageSpacing.height;
                    int w = rint([matrix length:state.pageSize.width]);
                    int h = rint([matrix length:state.pageSize.height]);
                    
                    y -= h;
                    
                    BOOL isVisible = x + w >= 0 && x < state.surfaceSize.width && y + h >= 0 && y < state.surfaceSize.height;
                    
                    if (isVisible) {
                        [self drawSingleImage:self.blank.texId x:x y:y w:w h:h];
                    }
                } else {
                    NSArray* textures = AT(AT_AS(self.pages, page % self.mod, PageInfo).textures, level - state.minLevel);
                    NSArray* statuses = AT(AT_AS(self.pages, page % self.mod, PageInfo).statuses, level - state.minLevel);
                    
                    // -1 for rounding error
                    int y = rint(state.surfaceSize.height - ([matrix y:0] + padding.height + [matrix length:state.pageSize.height - 1] * delta * ySign));
                    
                    y += pageSpacing.height;
                    
                    for (int py = 0; py < textures.count; py++) {
                        NSArray* ytex = AT(textures, py);
                        
                        int height = rint([matrix length:AT_AS(ytex, 0, TextureInfo).size.height] / factor);
                        
                        y -= height;
                        
                        // -1 for rounding error
                        int x = rint([matrix x:0] + padding.width + [matrix length:state.pageSize.width - 1] * delta * xSign);
                        
                        x += pageSpacing.width;
                        
                        for (int px = 0; px < ytex.count; px++) {
                            int width = rint([matrix length:AT_AS(ytex, px, TextureInfo).size.width] / factor);
                            
                            // avoid glDrawTexiOES limitation (except max level)
                            if ((width > TEXTURE_SIZE * 2 || height > TEXTURE_SIZE * 2) && level < state.maxLevel) {
                                continue;
                            }
                            
                            [self checkAndDrawSingleImage:level == state.minLevel textures:textures statuses:statuses py:py px:px x:x y:y w:width h:height surface:state.surfaceSize];
                            
                            x += width;
                        }
                    }
                }
            }
        }
    }
}

- (void)drawOverlay:(ImageMatrix *)matrix padding:(CGSize)padding state:(ImageState *)state {
    int xSign = [ImageDirectionMethod toXSign:state.direction];
    int ySign = [ImageDirectionMethod toYSign:state.direction];
    
    int nDeleta = state.nPage;
    for (int delta = -nDeleta; delta <= nDeleta; delta++) {
        int page = state.page + delta;

        if (page >= 0 && page < self.nPage) {
            id pageObj = AT(self.toPortraitPage, page);
            if (pageObj == [NSNull null]) {
                continue;
            }
            
            CGSize pageSpacing = [self pageSpacing:matrix state:state page:page delta:delta];
            
            float x = [matrix x:0] + padding.width + pageSpacing.width + [matrix length:state.pageSize.width - 1] * delta * xSign;
            float width = [matrix length:state.pageSize.width];
            float y = [matrix y:0] + padding.height - pageSpacing.height - [matrix length:state.pageSize.height - 1] * delta * ySign;
            float height = [matrix length:state.pageSize.height];
            
            for (ImageAnnotationInfo* i in AT(state.overlay, [pageObj intValue])) {
                CGRect r = i.annotation.region;
                i.frame = CGRectMake(rint(x + r.origin.x * width), rint(y + r.origin.y * height), rint(r.size.width * width), rint(r.size.height * height));
                
                GLuint texId;
                
                if ([i.annotation isKindOfClass:[URILinkAnnotationInfo class]] || [i.annotation isKindOfClass:[PageLinkAnnotationInfo class]]) {
                    texId = self.red.texId;
                } else if ([i.annotation isKindOfClass:[MovieAnnotationInfo class]]) {
                    int iTime = CFAbsoluteTimeGetCurrent() / MOVIE_ANNOTATION_BLINK_DURATION;
                    
                    texId = iTime % 2 ? self.darkBlack.texId : self.lightBlack.texId;
                } else {
                    assert(0);
                }
                
                [self drawSingleImage:texId x:i.frame.origin.x y:state.surfaceSize.height - i.frame.origin.y - i.frame.size.height w:i.frame.size.width h:i.frame.size.height];
            }
        }
    }
}

#pragma mark public

- (void)bindPageImage:(BindQueueItem *)item minLevel:(int)minLevel {
    TextureInfo* texture = AT3(AT_AS(self.pages, item.page % self.mod, PageInfo).textures, item.level - minLevel, item.py, item.px);
    
    [texture resetTexture];
    
    [texture bindTexture:item.data imageSize:CGSizeMake(TEXTURE_SIZE, TEXTURE_SIZE) use565:YES];
    free(item.data);
    item.data = nil;
    
    [AT2(AT_AS(self.pages, item.page % self.mod, PageInfo).statuses, item.level - minLevel, item.py) replaceObjectAtIndex:item.px withObject:NUM_B(YES)];
}

- (void)cleanup {
    NSMutableArray* buf = [NSMutableArray array];
    
    [buf addObject:NUM_I(self.background.texId)];
    [buf addObject:NUM_I(self.blank.texId)];
    [buf addObject:NUM_I(self.red.texId)];
    
    for (PageInfo* page in self.pages) {
        for (NSArray* textures in page.textures) {
            for (NSArray* row in textures) {
                for (TextureInfo* elem in row) {
                    [buf addObject:NUM_I(elem.texId)];
                }
            }
        }
    }
    
    GLuint targets[buf.count];
    for (int index = 0; index < buf.count; index++) {
        targets[index] = AT_AS(buf, index, NSNumber).intValue;
    }
    glDeleteTextures(buf.count, targets);
}

// return [level][npx,npy]
- (NSArray *)textureDimension:(int)page {
    NSArray* info = AT_AS(self.pages, page % self.mod, PageInfo).textures;
    
    NSMutableArray* ret = [NSMutableArray array];
    
    for (int level = 0; level < info.count; level++) {
        NSArray *texs = AT(info, level);
        
        NSArray* pair = [NSMutableArray arrayWithObjects:NUM_I(AT_AS(texs, 0, NSArray).count), NUM_I(texs.count), nil];
        
        [ret addObject:pair];
    }
    
    return ret;
}

- (void)prepare:(int)p_nPage minLevel:(int)minLevel maxLevel:(int)maxLevel pageSize:(CGSize)pageSize surfaceSize:(CGSize)surfaceSize image:(ImageInfo *)image doc:(DocInfo *)doc {
    self.nPage = p_nPage;
    
    self.background = [TextureInfo infoWithTiledImage:[UIImage imageNamed:@"image_background.png"] size:surfaceSize];
    self.blank = [TextureInfo infoWithColor:1 g:1 b:1 alpha:1];
    self.red = [TextureInfo infoWithColor:1 g:0.8 b:0.6 alpha:0.4];
    self.darkBlack = [TextureInfo infoWithColor:0 g:0.6 b:0 alpha:0.5];
    self.lightBlack = [TextureInfo infoWithColor:0 g:0.6 b:0 alpha:0.2];
    
    NSMutableArray* arr = [NSMutableArray array];
    for (int page = 0; page < self.mod ; page++) {
        [arr addObject:[PageInfo infoWithParam:minLevel maxLevel:maxLevel page:pageSize image:image]];
    }
    self.pages = arr;
    
    self.toPortraitPage = [image toPortraitPage:doc];
}

- (void)render:(ImageState *)state {
    // copy for thread consistency
    [self.immutableMatrix set:state.matrix];
    self.immutablePadding = state.padding;
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (!suspend) {
        [self drawBackground];
        
        [self drawImage:self.immutableMatrix padding:self.immutablePadding state:state];
        
        [self drawOverlay:self.immutableMatrix padding:self.immutablePadding state:state];
    } else {
        [self drawBigBackground];
    }
}

- (void)unbindPageImage:(UnbindQueueItem *)item minLevel:(int)minLevel {
    [AT2(AT_AS(self.pages, item.page % self.mod, PageInfo).statuses, item.level - minLevel, item.py) replaceObjectAtIndex:item.px withObject:NUM_B(NO)];

    TextureInfo* texture = AT3(AT_AS(self.pages, item.page % self.mod, PageInfo).textures, item.level - minLevel, item.py, item.px);
    
    [texture resetTexture];
}

@end
