//
//  ImageInfo.h
//  docnext
//
//  Created by  on 11/09/28.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DocInfo;

@interface ImageInfo : NSObject

@property(nonatomic) int width;
@property(nonatomic) int height;
@property(nonatomic) int maxLevel;
@property(nonatomic) BOOL isUseActualSize;
@property(nonatomic) int maxNumberOfLevel;
@property(nonatomic) BOOL isWebp;
@property(nonatomic) BOOL hasConcatFile;
@property(nonatomic, retain) NSArray* spreadOnlyPages;

+ (ImageInfo *)infoWithDictionary:(NSDictionary *)dict;

- (NSArray *)fromSpreadPage:(DocInfo *)doc;
- (NSArray *)toPortraitPage:(DocInfo *)doc;
- (NSArray *)toSpreadPage:(DocInfo *)doc;

@end
