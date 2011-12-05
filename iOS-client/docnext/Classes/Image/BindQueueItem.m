//
//  BindQueueItem.m
//  docnext
//
//  Created by  on 11/10/06.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "BindQueueItem.h"

@implementation BindQueueItem

@synthesize page;
@synthesize level;
@synthesize px;
@synthesize py;
@synthesize data;

- (id)initWithParam:(int)p_page level:(int)p_level px:(int)p_px py:(int)p_py data:(GLubyte *)p_data {
    self = [super init];

    if (self) {
        self.page = p_page;
        self.level = p_level;
        self.px = p_px;
        self.py = p_py;
        self.data = p_data;
    }
    
    return self;
}

#pragma mark public

+ (BindQueueItem *)itemWithParam:(int)page level:(int)level px:(int)px py:(int)py data:(GLubyte *)data {
    return [[[BindQueueItem alloc] initWithParam:page level:level px:px py:py data:data] autorelease];
}

@end
