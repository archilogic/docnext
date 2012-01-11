//
//  UIStringTagAlertView.m
//  docnext
//
//  Created by  on 11/12/21.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIStringTagAlertView.h"

@implementation UIStringTagAlertView

@synthesize stringTag;

- (void)dealloc {
    self.stringTag = nil;
    
    [super dealloc];
}

@end
