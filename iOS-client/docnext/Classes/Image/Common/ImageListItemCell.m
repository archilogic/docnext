//
//  BookmarkCell.m
//  docnext
//
//  Created by  on 11/10/20.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "ImageListItemCell.h"

@implementation ImageListItemCell

@synthesize thumbnailImageView;
@synthesize textView;
@synthesize pageLabel;

- (void)dealloc {
    self.thumbnailImageView = nil;
    self.textView = nil;
    self.pageLabel = nil;
    
    [super dealloc];
}

@end
