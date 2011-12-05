//
//  ImageCornerMethod.h
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageTypes.h"

@interface ImageCornerMethod : NSObject

+ (float)x:(ImageCorner)corner scale:(float)scale surface:(CGSize)surface page:(CGSize)page nPage:(int)nPage;
+ (float)y:(ImageCorner)corner scale:(float)scale surface:(CGSize)surface page:(CGSize)page nPage:(int)nPage;

@end
