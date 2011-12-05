//
//  OrientationUtil.h
//  docnext
//
//  Created by  on 11/11/30.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OrientationUtil : NSObject

+ (BOOL)isIPhone;
+ (BOOL)isLandscape;
+ (BOOL)isSpreadMode;

@end
