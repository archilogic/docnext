//
//  RemotePathUtil.m
//  docnext
//
//  Created by  on 11/09/15.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "RemotePathUtil.h"

@implementation RemotePathUtil

#pragma mark public

+ (NSString *)imageAnnotationPath:(NSString *)endpoint page:(int)page {
    return [NSString stringWithFormat:@"%@%d.anno.json", [RemotePathUtil imageDir:endpoint], page];
}

+ (NSString *)imageDir:(NSString *)endpoint {
    return [NSString stringWithFormat:@"%@image/", endpoint];
}

+ (NSString *)imageInfoPath:(NSString *)endpoint {
    return [NSString stringWithFormat:@"%@image.json", [RemotePathUtil imageDir:endpoint]];
}

+ (NSString *)imageRegionsPath:(NSString *)endpoint page:(int)page {
    return [NSString stringWithFormat:@"%@%d.regions", [RemotePathUtil imageDir:endpoint], page];
}

+ (NSString *)imageTextIndexPath:(NSString *)endpoint {
    return [NSString stringWithFormat:@"%@text.index.zip", [RemotePathUtil imageDir:endpoint]];
}

+ (NSString *)imageTextureConcatPath:(NSString *)endpoint page:(int)page level:(int)level {
    return [NSString stringWithFormat:@"%@texture-%d-%d.concat", [RemotePathUtil imageDir:endpoint], page, level];
}

+ (NSString *)imageTexturePath:(NSString *)endpoint page:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp {
    return [NSString stringWithFormat:@"%@texture-%d-%d-%d-%d.%@",
            [RemotePathUtil imageDir:endpoint], page, level, px, py, isWebp ? @"webp" : @"jpg"];
}

+ (NSString *)imageThumbnailPath:(NSString *)endpoint page:(int)page {
    return [NSString stringWithFormat:@"%@thumbnail-%d.jpg", [RemotePathUtil imageDir:endpoint], page];
}

+ (NSString *)infoPath:(NSString *)endpoint {
    return [NSString stringWithFormat:@"%@info.json", endpoint];
}

@end
