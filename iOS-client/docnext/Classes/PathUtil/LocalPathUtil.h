//
//  LocalPathUtil.h
//  docnext
//
//  Created by  on 11/09/15.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalPathUtil : NSObject

// document path
+ (void)ensureDocDir:(NSString *)docId;
+ (void)ensureImageDir:(NSString *)docId;
+ (NSString *)completedPath:(NSString *)docId;
+ (NSString *)docDir:(NSString *)docId;
+ (NSString *)imageDir:(NSString *)docId;
+ (NSString *)imageInfoPath:(NSString *)docId;
+ (NSString *)imageInitDownloadedPath:(NSString *)docId;
+ (NSString *)imageRegionsName:(int)page;
+ (NSString *)imageRegionsPath:(NSString *)docId page:(int)page;
+ (NSString *)imageTextureName:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp;
+ (NSString *)imageTexturePath:(NSString *)docId page:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp;
+ (NSString *)imageThumbnailName:(int)page;
+ (NSString *)imageThumbnailPath:(NSString *)docId page:(int)page;
+ (NSString *)infoPath:(NSString *)docId;
+ (NSString *)bookmarkInfoPath:(NSString *)docId;
+ (NSString *)lastOpenedPagePath:(NSString *)docId;

// app state path
+ (NSString *)downloaderInfoPath;

@end
