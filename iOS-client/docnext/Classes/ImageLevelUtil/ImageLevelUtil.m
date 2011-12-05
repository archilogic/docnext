//
//  ImageLevelUtil.m
//  docnext
//
//  Created by  on 11/09/28.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "ImageLevelUtil.h"

@implementation ImageLevelUtil

#pragma mark private

+ (int)numberOfLevel:(int)minLevel imageMaxLevel:(int)imageMaxLevel imageMaxNumberOfLevel:(int)imageMaxNumberOfLevel {
    int limit = imageMaxNumberOfLevel > 0 ? imageMaxNumberOfLevel : 3;
    
    return MIN(imageMaxLevel - minLevel + 1, limit);
}

+ (int)shortSide {
    UIScreen* sc = [UIScreen mainScreen];
    CGSize sz = sc.applicationFrame.size;
    float f = sc.scale;
    
    return MIN(sz.width * f, sz.height * f);
}

#pragma mark public

+ (int)maxLevel:(int)minLevel imageMaxLevel:(int)imageMaxLevel imageMaxNumberOfLevel:(int)imageMaxNumberOfLevel {
    return minLevel + [self numberOfLevel:minLevel imageMaxLevel:imageMaxLevel imageMaxNumberOfLevel:imageMaxNumberOfLevel] - 1;
}

+ (int)minLevel:(int)imageMaxLevel {
    return MIN((int)ceil(log2(1.0 * self.shortSide / TEXTURE_SIZE)), imageMaxLevel);
}

@end
