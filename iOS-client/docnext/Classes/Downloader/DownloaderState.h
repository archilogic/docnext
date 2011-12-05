//
//  DownloaderState.h
//  docnext
//
//  Created by  on 11/10/24.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloaderItem.h"

@interface DownloaderState : NSObject

@property(nonatomic, retain) DownloaderItem* item;

+ (DownloaderState *)stateWithItem:(DownloaderItem *)item lock:(NSLock *)lock;
- (void)invoke;
- (BOOL)didFinished;
- (void)stop;

@end
