//
//  Downloader.h
//  docnext
//
//  Created by  on 11/09/15.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloaderTypes.h"

#define DOWNLOADER_PROGRESS @"docnext_downloader_progress"
#define DOWNLOADER_COMPLETE @"docnext_downloader_complete"
#define DOWNLOADER_FAILED @"docnext_downloader_failed"

#define DOWNLOADER_IMAGE_INIT_DOWNLOADED @"docnext_downloader_image_init_downloaded"
#define DOWNLOADER_TEXTURE_PROGRESS @"docnext_downloader_texture_progress"

@interface Downloader : NSObject

+ (Downloader *)instance;

- (void)start;
- (void)stop;
- (void)addItem:(NSString *)docId permitType:(DownloaderPermitType)permitType saveLimit:(DownloaderSaveLimit)saveLimit endpoint:(NSString *)endpoint insertPosition:(DownloaderInsertPosition)insertPosition;
- (void)removeItem:(NSString *)docId;
- (void)suspendItem:(NSString *)docId;
- (void)resumeItem:(NSString *)docId;
- (NSArray *)list;
- (void)sort:(NSArray *)docIds;

@end
