//
//  LocalPathUtil.m
//  docnext
//
//  Created by  on 11/09/15.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "LocalPathUtil.h"
#import "FileUtil.h"

@implementation LocalPathUtil

#pragma mark public

+ (NSString *)completedPath:(NSString *)docId {
    return [[self docDir:docId] stringByAppendingPathComponent:@"completed"];
}

+ (NSString *)docDir:(NSString *)docId {
    return [@"/docs" stringByAppendingFormat:docId];
}

+ (NSString *)imageAnnotationPath:(NSString *)docId page:(int)page {
    return [[self imageDir:docId] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.anno.json", page]];
}

+ (NSString *)imageDir:(NSString *)docId {
    return [[self docDir:docId] stringByAppendingPathComponent:@"image"];
}

+ (NSString *)imageInfoPath:(NSString *)docId {
    return [[self imageDir:docId] stringByAppendingPathComponent:@"image.json"];
}

+ (NSString *)imageInitDownloadedPath:(NSString *)docId {
    return [[self docDir:docId] stringByAppendingPathComponent:@"image_init_downloaded"];
}

+ (NSString *)imageRegionsName:(int)page {
    return [NSString stringWithFormat:@"%d.regions", page];
}

+ (NSString *)imageRegionsPath:(NSString *)docId page:(int)page {
    return [[self imageDir:docId] stringByAppendingPathComponent:[self imageRegionsName:page]];
}

+ (NSString *)imageTextureName:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp {
    return [NSString stringWithFormat:@"texture-%d-%d-%d-%d.%@", page, level, px, py, isWebp ? @"webp" : @"jpg"];
}

+ (NSString *)imageTexturePath:(NSString *)docId page:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp {
    return [[self imageDir:docId] stringByAppendingPathComponent:[self imageTextureName:page level:level px:px py:py isWebp:isWebp]];
}

+ (NSString *)imageThumbnailName:(int)page {
    return [NSString stringWithFormat:@"thumbnail-%d.jpg", page];
}

+ (NSString *)imageThumbnailPath:(NSString *)docId page:(int)page {
    return [[self imageDir:docId] stringByAppendingPathComponent:[self imageThumbnailName:page]];
}

+ (NSString *)infoPath:(NSString *)docId {
    return [[self docDir:docId] stringByAppendingPathComponent:@"info.json"];
}

+ (NSString *)bookmarkInfoPath:(NSString *)docId {
    return [[self docDir:docId] stringByAppendingPathComponent:@"bookmark.json"];
}

+ (NSString *)lastOpenedPagePath:(NSString *)docId {
    return [[self docDir:docId] stringByAppendingPathComponent:@"lastOpenedPage.dat"];
}

+ (NSString *)downloaderInfoPath {
    return @"/data_downloader.dat";
}

@end
