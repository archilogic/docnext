//
//  BookmarkInfo.h
//  docnext
//
//  Created by  on 11/10/20.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageListItemInfo : NSObject

@property(nonatomic, retain) UIImage* thumbnail;
@property(nonatomic) int page;
@property(nonatomic, retain) NSString* text;

+ (ImageListItemInfo *)infoWithParam:(UIImage *)thumbnail page:(int)page text:(NSString *)text;

@end
