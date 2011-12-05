//
//  UnbindQueueItem.m
//  docnext
//
//  Created by  on 11/10/06.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "UnbindQueueItem.h"

@implementation UnbindQueueItem

@synthesize page;
@synthesize level;
@synthesize px;
@synthesize py;

- (id)initWithParam:(int)p_page level:(int)p_level px:(int)p_px py:(int)p_py {
    self = [super init];
    
    if (self) {
        self.page = p_page;
        self.level = p_level;
        self.px = p_px;
        self.py = p_py;
    }
    
    return self;
}

#pragma mark public

+ (UnbindQueueItem *)itemWithParam:(int)page level:(int)level px:(int)px py:(int)py {
    return [[[UnbindQueueItem alloc] initWithParam:page level:level px:px py:py] autorelease];
}

@end
