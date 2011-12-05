//
//  LocalProviderUtil.m
//  docnext
//
//  Created by  on 11/09/28.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "LocalProviderUtil.h"
#import "FileUtil.h"
#import "LocalPathUtil.h"
#import "SBJson.h"
#import "ImageLevelUtil.h"
#import "Utilities.h"
#import "BookmarkInfo.h"

@implementation LocalProviderUtil

+ (id)jsonInfo:(NSString *)path {
    return [[NSString stringWithContentsOfFile:[FileUtil fullPath:path] encoding:NSUTF8StringEncoding error:nil] JSONValue];
}

#pragma mark public

+ (DocInfo *)info:(NSString *)docId {
    return [DocInfo infoWithDictionary:[self jsonInfo:[LocalPathUtil infoPath:docId]]];
}

+ (ImageInfo *)imageInfo:(NSString *)docId {
    return [ImageInfo infoWithDictionary:[self jsonInfo:[LocalPathUtil imageInfoPath:docId]]];
}

+ (NSString *)tocText:(NSString *)docId page:(int)page {
    NSString* ret = @"NO TITLE";

    for (NSDictionary* toc in [[self info:docId] toc:[self imageInfo:docId]]) {
        int tocPage = FOR_I(toc, @"page");
        NSString* tocText = FOR(toc, @"text");
        
        if (tocPage > page) {
            return ret;
        }
        
        if (tocPage <= page) {
            ret = tocText;
        }
    }
    
    return ret;
}

+ (NSArray *)bookmark:(NSString *)docId {
    NSMutableArray* list = [NSMutableArray array];
    
    for (NSDictionary* dict in [self jsonInfo:[LocalPathUtil bookmarkInfoPath:docId]]) {
        [list addObject:[BookmarkInfo infoWithDictionary:dict]];
    }
    
    return list;
}

+ (void)setBookmark:(NSString *)docId bookmark:(NSArray *)bookmark {
    NSMutableArray* list = [NSMutableArray array];
    
    for (BookmarkInfo* b in bookmark) {
        [list addObject:[b toDictionary]];
    }
    
    [list.JSONRepresentation writeToFile:[FileUtil fullPath:[LocalPathUtil bookmarkInfoPath:docId]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (BOOL)isCompleted:(NSString *)docId {
    return [FileUtil exists:[LocalPathUtil completedPath:docId]];
}

+ (void)setCompleted:(NSString *)docId {
    [FileUtil touch:[LocalPathUtil completedPath:docId]];
}

+ (BOOL)isImageInitDownloaded:(NSString *)docId {
    return [FileUtil exists:[LocalPathUtil imageInitDownloadedPath:docId]];
}

+ (void)setImageInitDownloaded:(NSString *)docId {
    [FileUtil touch:[LocalPathUtil imageInitDownloadedPath:docId]];
}

+ (BOOL)isAllTopImageExists:(NSString *)docId page:(int)page {
    ImageInfo* image = [self imageInfo:docId];
    
    int minLevel = [ImageLevelUtil minLevel:image.maxLevel];
    
    int width = minLevel != image.maxLevel || !image.isUseActualSize ? TEXTURE_SIZE * pow(2, minLevel) : image.width;
    int height = image.height * width / image.width;
    
    int nx = (width - 1) / TEXTURE_SIZE + 1;
    int ny = (height - 1) / TEXTURE_SIZE + 1;
    
    for (int py = 0; py < ny; py++) {
        for (int px = 0; px < nx; px++) {
            if (![FileUtil exists:[LocalPathUtil imageTexturePath:docId page:page level:minLevel px:px py:py isWebp:image.isWebp]]) {
                return NO;
            }
        }
    }
    
    return YES;
}

+ (int)lastOpenedPage:(NSString *)docId {
    NSString* path = [LocalPathUtil lastOpenedPagePath:docId];
    
    if (![FileUtil exists:path]) {
        return -1;
    }
    
    return [[NSString stringWithContentsOfFile:[FileUtil fullPath:path] encoding:NSUTF8StringEncoding error:nil] intValue];
}

+ (void)setLastOpenedPage:(NSString *)docId page:(int)page {
    [[NSString stringWithFormat:@"%d", page] writeToFile:[FileUtil fullPath:[LocalPathUtil lastOpenedPagePath:docId]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
