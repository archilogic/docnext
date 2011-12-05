//
//  LoadImageTask.m
//  docnext
//
//  Created by  on 11/10/06.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "LoadImageTask.h"
#import "LocalPathUtil.h"
#import "FileUtil.h"
#import "ImageLevelUtil.h"
#import "BitmapConverter.h"
#import "Utilities.h"
#import "LocalProviderUtil.h"

#import "WebP/decode.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface LoadImageTask ()

@property(nonatomic, retain) NSString* docId;
@property(nonatomic) int px;
@property(nonatomic) int py;
@property(nonatomic) BOOL isWebp;
@property(nonatomic, assign) id<PageHolder> pageHolder;
@property(nonatomic, assign) id<TextureBinder> binder;
@property(nonatomic) int threshold;

@end

@implementation LoadImageTask

@synthesize page;
@synthesize level;
@synthesize abort;

@synthesize docId;
@synthesize px;
@synthesize py;
@synthesize isWebp;
@synthesize pageHolder;
@synthesize binder;
@synthesize threshold;

- (id)initWithParam:(NSString *)p_docId page:(int)p_page level:(int)p_level px:(int)p_px py:(int)p_py isWebp:(BOOL)p_isWebp pageHolder:(id<PageHolder>)p_pageHolder binder:(id<TextureBinder>)p_binder threshold:(int)p_threshold {
    self = [super init];
    
    if (self) {
        self.docId = p_docId;
        self.page = p_page;
        self.level = p_level;
        self.px = p_px;
        self.py = p_py;
        self.isWebp = p_isWebp;
        self.pageHolder = p_pageHolder;
        self.binder = p_binder;
        self.threshold = p_threshold;
        
        self.abort = NO;
    }
    
    return self;
}

- (void)dealloc {
    self.docId = nil;
    self.pageHolder = nil;
    self.binder = nil;
    
    [super dealloc];
}

- (GLubyte *)loadJpeg {
    NSNumber* p = AT([[LocalProviderUtil imageInfo:self.docId] toPortraitPage:[LocalProviderUtil info:self.docId]], self.page);
    NSString* path = [FileUtil fullPath:[LocalPathUtil imageTexturePath:self.docId page:p.intValue level:self.level px:self.px py:self.py isWebp:self.isWebp]];
    
    UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfFile:path]];
    
    GLubyte* data = (GLubyte *)malloc(TEXTURE_SIZE * TEXTURE_SIZE * 4);
    
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(data, TEXTURE_SIZE, TEXTURE_SIZE, 8, TEXTURE_SIZE * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(ctx, CGRectMake(0, 0, TEXTURE_SIZE, TEXTURE_SIZE), imageRef);
    CGContextRelease(ctx);
    
#ifdef USE565
    GLubyte* rgb = malloc(TEXTURE_SIZE * TEXTURE_SIZE * 2);
    
    [BitmapConverter fromRGBA8888toRGB656:data to:rgb size:TEXTURE_SIZE * TEXTURE_SIZE];
    free(data);
    
    return rgb;
#else
    return data;
#endif
}

- (GLubyte *)loadWebp {
    NSNumber* p = AT([[LocalProviderUtil imageInfo:self.docId] toPortraitPage:[LocalProviderUtil info:self.docId]], self.page);
    NSString* path = [FileUtil fullPath:[LocalPathUtil imageTexturePath:self.docId page:p.intValue level:self.level px:self.px py:self.py isWebp:self.isWebp]];
    
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        assert(0);
    }

    // MODE_RGB_565 seems not to work currently
    config.output.colorspace = MODE_RGB_565;
    config.options.use_threads = 1;
    config.options.bypass_filtering = 1;
    //config.options.no_fancy_upsampling = 1; // low quality
    config.options.no_enhancement = 1;

    if (WebPDecode(data.bytes, data.length, &config) != VP8_STATUS_OK) {
        assert(0);
    }
    
#ifdef USE565
    GLubyte* rgb = malloc(TEXTURE_SIZE * TEXTURE_SIZE * 2);
    
    [BitmapConverter changeShortEndian:config.output.u.RGBA.rgba to:rgb size:TEXTURE_SIZE * TEXTURE_SIZE];
    
    WebPFreeDecBuffer(&config.output);
    
    return rgb;
#else
    return config.output.u.RGBA.rgba;
#endif
}

- (void)main {
    if (self.abort) {
        return;
    }
    
    NSNumber* p = AT([[LocalProviderUtil imageInfo:self.docId] toPortraitPage:[LocalProviderUtil info:self.docId]], self.page);
    
    if ((NSNull *)p == [NSNull null]) {
        return;
    }
    
    NSString* path = [LocalPathUtil imageTexturePath:self.docId page:p.intValue level:self.level px:self.px py:self.py isWebp:self.isWebp];
    
    if (![FileUtil exists:path]){
        return;
    }
    
    if (self.page < self.pageHolder.page - self.threshold || page > self.pageHolder.page + self.threshold) {
        return;
    }
    
    if (self.abort) {
        return;
    }

    GLubyte* data = self.isWebp ? self.loadWebp : self.loadJpeg;
    
    if (self.abort || self.page < self.pageHolder.page - self.threshold || page > self.pageHolder.page + self.threshold) {
        free(data);
        return;
    }
    
    [self.binder bind:[BindQueueItem itemWithParam:self.page level:self.level px:self.px py:self.py data:data]];
}

#pragma mark public

+ (LoadImageTask *)taskWithParam:(NSString *)docId page:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp pageHolder:(id<PageHolder>)pageHolder binder:(id<TextureBinder>)binder threshold:(int)threshold {
    return [[[LoadImageTask alloc] initWithParam:docId page:page level:level px:px py:py isWebp:isWebp pageHolder:pageHolder binder:binder threshold:threshold] autorelease];
}

@end
