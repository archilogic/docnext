//
//  Downloader.h
//  docnext
//
//  Created by  on 11/09/15.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloaderTypes.h"

extern NSString* const DOWNLOADER_PROGRESS;
extern NSString* const DOWNLOADER_COMPLETE;
extern NSString* const DOWNLOADER_FAILED;

extern NSString* const DOWNLOADER_IMAGE_INIT_DOWNLOADED;
extern NSString* const DOWNLOADER_TEXTURE_PROGRESS;
extern NSString* const DOWNLOADER_ANNOTATION_PROGRESS;

@interface Downloader : NSObject

+ (Downloader *)instance;

- (void)start;
- (void)stop;
- (void)addItem:(NSString *)docId permitType:(DownloaderPermitType)permitType saveLimit:(DownloaderSaveLimit)saveLimit endpoint:(NSString *)endpoint insertPosition:(DownloaderInsertPosition)insertPosition title:(NSString *)title;
- (void)removeItem:(NSString *)docId;
- (void)suspendItem:(NSString *)docId;
- (NSArray *)list;
- (void)sort:(NSArray *)docIds;

@end
