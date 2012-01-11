//
//  LocalProviderUtil.h
//  docnext
//
//  Created by  on 11/09/28.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DocInfo.h"
#import "ImageInfo.h"

@interface LocalProviderUtil : NSObject

+ (DocInfo *)info:(NSString *)docId;
+ (ImageInfo *)imageInfo:(NSString *)docId;
+ (NSString *)tocText:(NSString *)docId page:(int)page;
+ (NSArray *)bookmark:(NSString *)docId;
+ (void)setBookmark:(NSString *)docId bookmark:(NSArray *)bookmark;
+ (BOOL)isCompleted:(NSString *)docId;
+ (void)setCompleted:(NSString *)docId;
+ (BOOL)isImageInitDownloaded:(NSString *)docId;
+ (void)setImageInitDownloaded:(NSString *)docId;
+ (BOOL)isAllTopImageExists:(NSString *)docId page:(int)page;
+ (int)lastOpenedPage:(NSString *)docId;
+ (void)setLastOpenedPage:(NSString *)docId page:(int)page;
+ (NSArray *)annotation:(NSString *)docId page:(int)page;

@end
