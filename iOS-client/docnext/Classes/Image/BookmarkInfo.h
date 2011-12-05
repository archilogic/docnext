//
//  BookmarkInfo.h
//  docnext
//
//  Created by  on 11/11/16.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BookmarkInfo : NSObject

@property(nonatomic) int page;
@property(nonatomic, retain) NSString* comment;

+ (BookmarkInfo *)info:(int)page comment:(NSString *)comment;
+ (BookmarkInfo *)infoWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)toDictionary;

@end
