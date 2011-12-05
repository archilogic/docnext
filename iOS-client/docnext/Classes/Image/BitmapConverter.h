//
//  BitmapConverter.h
//  docnext
//
//  Created by  on 11/11/11.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BitmapConverter : NSObject

+ (void)fromRGBA8888toRGB656:(GLubyte *)from to:(GLubyte *)to size:(int)size;
+ (void)changeShortEndian:(GLubyte *)from to:(GLubyte *)to size:(int)size;

@end
