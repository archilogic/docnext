//
//  RemotePathUtil.h
//  docnext
//
//  Created by  on 11/09/15.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RemotePathUtil : NSObject

+ (NSString *)imageAnnotationPath:(NSString *)endpoint page:(int)page;
+ (NSString *)imageInfoPath:(NSString *)endpoint;
+ (NSString *)imageRegionsPath:(NSString *)endpoint page:(int)page;
+ (NSString *)imageTextIndexPath:(NSString *)endpoint;
+ (NSString *)imageTextureConcatPath:(NSString *)endpoint page:(int)page level:(int)level;
+ (NSString *)imageTexturePath:(NSString *)endpoint page:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp;
+ (NSString *)imageTexturePerPagePath:(NSString *)endpoint page:(int)page texs:(NSArray *)texs isWebp:(BOOL)isWebp;
+ (NSString *)imageThumbnailPath:(NSString *)endpoint page:(int)page;
+ (NSString *)imageThumbnailBlockPath:(NSString *)endpoint pages:(NSArray *)pages;
+ (NSString *)infoPath:(NSString *)endpoint;

@end
