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

+ (void)ensureDocDir:(NSString *)docId {
    [FileUtil ensureDir:[self docDir:docId]];
}

+ (void)ensureImageDir:(NSString *)docId {
    [FileUtil ensureDir:[self imageDir:docId]];
}

+ (NSString *)completedPath:(NSString *)docId {
    return [NSString stringWithFormat:@"%@completed", [self docDir:docId]];
}

+ (NSString *)docDir:(NSString *)docId {
    return [NSString stringWithFormat:@"/docs/%@/", docId];
}

+ (NSString *)imageAnnotationPath:(NSString *)docId page:(int)page {
    return [NSString stringWithFormat:@"%@%d.anno.json", [self imageDir:docId], page];
}

+ (NSString *)imageDir:(NSString *)docId {
    return [NSString stringWithFormat:@"%@image/", [self docDir:docId]];
}

+ (NSString *)imageInfoPath:(NSString *)docId {
    return [NSString stringWithFormat:@"%@image.json", [self imageDir:docId]];
}

+ (NSString *)imageInitDownloadedPath:(NSString *)docId {
    return [NSString stringWithFormat:@"%@image_init_downloaded", [self docDir:docId]];
}

+ (NSString *)imageRegionsName:(int)page {
    return [NSString stringWithFormat:@"%d.regions", page];
}

+ (NSString *)imageRegionsPath:(NSString *)docId page:(int)page {
    return [NSString stringWithFormat:@"%@%@", [self imageDir:docId], [self imageRegionsName:page]];
}

+ (NSString *)imageTextureName:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp {
    return [NSString stringWithFormat:@"texture-%d-%d-%d-%d.%@", page, level, px, py, isWebp ? @"webp" : @"jpg"];
}

+ (NSString *)imageTexturePath:(NSString *)docId page:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp {
    return [NSString stringWithFormat:
            @"%@%@", [self imageDir:docId], [self imageTextureName:page level:level px:px py:py isWebp:isWebp]];
}

+ (NSString *)imageThumbnailName:(int)page {
    return [NSString stringWithFormat:@"thumbnail-%d.jpg", page];
}

+ (NSString *)imageThumbnailPath:(NSString *)docId page:(int)page {
    return [NSString stringWithFormat:@"%@%@", [self imageDir:docId], [self imageThumbnailName:page]];
}

+ (NSString *)infoPath:(NSString *)docId {
    return [NSString stringWithFormat:@"%@info.json", [self docDir:docId]];
}

+ (NSString *)bookmarkInfoPath:(NSString *)docId {
    return [NSString stringWithFormat:@"%@bookmark.json", [self docDir:docId]];
}

+ (NSString *)lastOpenedPagePath:(NSString *)docId {
    return [NSString stringWithFormat:@"%@lastOpenedPage.dat", [self docDir:docId]];
}

+ (NSString *)downloaderInfoPath {
    return @"/data_downloader.dat";
}

@end
