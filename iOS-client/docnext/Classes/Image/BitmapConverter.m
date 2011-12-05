//
//  BitmapConverter.m
//  docnext
//
//  Created by  on 11/11/11.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "BitmapConverter.h"

@implementation BitmapConverter

+ (void)fromRGBA8888toRGB656:(GLubyte *)from to:(GLubyte *)to size:(int)size {
    unsigned int* fp = (unsigned int*)from;
    unsigned short* tp = (unsigned short*)to;
    
    for (int i = 0; i < size; i++) {
        *tp++ = ((((*fp >> 0) & 0xFF) >> 3) << 11) | ((((*fp >> 8) & 0xFF) >> 2) << 5) | ((((*fp >> 16) & 0xFF) >> 3) << 0);
        fp++;
    }
}

+ (void)changeShortEndian:(GLubyte *)from to:(GLubyte *)to size:(int)size {
    uint8_t* fp = (uint8_t*)from;
    uint8_t* tp = (uint8_t*)to;
    
    for (int i = 0; i < size; i++) {
        uint8_t val = *fp++;
        *tp++ = *fp++;
        *tp++ = val;
    }
}

@end
