//
//  PageInfo.h
//  docnext
//
//  Created by  on 11/10/03.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageInfo.h"

@interface PageInfo : NSObject

@property(nonatomic, retain) NSArray* textures;
@property(nonatomic, retain) NSArray* statuses;

+ (PageInfo *)infoWithParam:(int)minLevel maxLevel:(int)maxLevel page:(CGSize)page image:(ImageInfo *)image;

@end
