//
//  BookmarkInfo.m
//  docnext
//
//  Created by  on 11/10/20.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "ImageListItemInfo.h"

@implementation ImageListItemInfo

@synthesize thumbnail;
@synthesize page;
@synthesize text;

- (id)initWithParam:(UIImage *)p_thumbnail page:(int)p_page text:(NSString *)p_text {
    self = [super init];
    
    if (self) {
        self.thumbnail = p_thumbnail;
        self.page = p_page;
        self.text = p_text;
    }
    
    return self;
}

- (void)dealloc {
    self.thumbnail = nil;
    self.text = nil;
    
    [super dealloc];
}

#pragma mark public

+ (ImageListItemInfo *)infoWithParam:(UIImage *)thumbnail page:(int)page text:(NSString *)text {
    return [[[ImageListItemInfo alloc] initWithParam:thumbnail page:page text:text] autorelease];
}

@end
