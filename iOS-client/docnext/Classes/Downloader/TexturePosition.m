//
//  TexturePosition.m
//  docnext
//
//  Created by  on 11/10/28.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "TexturePosition.h"

@implementation TexturePosition

@synthesize level;
@synthesize px;
@synthesize py;

+ (TexturePosition *)positionWithParmas:(int)level px:(int)px py:(int)py {
    TexturePosition* ret = [[[TexturePosition alloc] init] autorelease];
    
    ret.level = level;
    ret.px = px;
    ret.py = py;
    
    return ret;
}

@end
