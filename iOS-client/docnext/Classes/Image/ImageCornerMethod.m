//
//  ImageCornerMethod.m
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "ImageCornerMethod.h"

@implementation ImageCornerMethod

+ (float)x:(ImageCorner)corner scale:(float)scale surface:(CGSize)surface page:(CGSize)page nPage:(int)nPage {
    switch (corner) {
        case ImageCornerTopLeft:
        case ImageCornerBottomLeft:
            return 0;
        case ImageCornerTopRight:
        case ImageCornerBottomRight:
            return surface.width - page.width * scale * nPage;
        default:
            assert(0);
    }
}

+ (float)y:(ImageCorner)corner scale:(float)scale surface:(CGSize)surface page:(CGSize)page nPage:(int)nPage {
    switch (corner) {
        case ImageCornerTopLeft:
        case ImageCornerTopRight:
            return 0;
        case ImageCornerBottomLeft:
        case ImageCornerBottomRight:
            return surface.height - page.height * scale * nPage;
        default:
            assert(0);
    }
}

@end
