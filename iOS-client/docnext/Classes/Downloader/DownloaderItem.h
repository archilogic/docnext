//
//  DownloaderItem.h
//  docnext
//
//  Created by  on 11/09/15.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloaderTypes.h"

@interface DownloaderItem : NSObject <NSCoding> 

@property(nonatomic, retain) NSString *docId;
@property(nonatomic) DownloaderPermitType permitType;
@property(nonatomic) DownloaderSaveLimit saveLimit;
@property(nonatomic, retain) NSString* endpoint;
@property(nonatomic) DownloaderInsertPosition insertPosition;

@property(nonatomic) BOOL suspend;
@property(nonatomic) int sequence;

+ (DownloaderItem *)itemWithParam:(NSString *)docId permitType:(DownloaderPermitType)permitType saveLimit:(DownloaderSaveLimit)saveLimit endpoint:(NSString *)endpoint insertPosition:(DownloaderInsertPosition)insertPosition;

@end
