//
//  ImageLevelUtil.h
//  docnext
//
//  Created by  on 11/09/28.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TEXTURE_SIZE 512

@interface ImageLevelUtil : NSObject

+ (int)maxLevel:(int)minLevel imageMaxLevel:(int)imageMaxLevel imageMaxNumberOfLevel:(int)imageMaxNumberOfLevel;
+ (int)minLevel:(int)imageMaxLevel;

@end
