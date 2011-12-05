//
//  BookmarkTextUtil.m
//  docnext
//
//  Created by 野口 優 on 11/11/08.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BookmarkTextUtil.h"
#import "LocalProviderUtil.h"

@implementation BookmarkTextUtil

+ (BOOL)containsTextBookmark:(NSArray*)array page:(int)page {
    
    for (NSNumber *pos in array) {
        if ([LocalProviderUtil resolvePositionToPage:[pos intValue]] == page) {
            return TRUE;
        }
    }
    return FALSE;
}

+ (BOOL)containsTextBookmark:(NSArray*)array pos:(int)pos {
    return [BookmarkTextUtil containsTextBookmark:array page:[LocalProviderUtil resolvePositionToPage:pos]];
}

@end
