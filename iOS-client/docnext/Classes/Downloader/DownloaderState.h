//
//  DownloaderState.h
//  docnext
//
//  Created by  on 11/10/24.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloaderItem.h"

@class Downloader;

@interface DownloaderState : NSObject

@property(nonatomic, retain) DownloaderItem* item;

+ (DownloaderState *)stateWithItem:(DownloaderItem *)item lock:(NSLock *)lock delegate:(Downloader *)delegate;
- (void)invoke;
- (BOOL)didFinished;
- (void)stop:(BOOL)willDelete;

@property(atomic) BOOL willDelete;

@end
