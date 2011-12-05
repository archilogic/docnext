//
//  OrientationUtil.m
//  docnext
//
//  Created by  on 11/11/30.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "OrientationUtil.h"

@implementation OrientationUtil

+ (BOOL)isIPhone {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

+ (BOOL)isLandscape {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
}

+ (BOOL)isSpreadMode {
    return !self.isIPhone && self.isLandscape;
}

@end
