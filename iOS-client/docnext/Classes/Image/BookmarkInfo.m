//
//  BookmarkInfo.m
//  docnext
//
//  Created by  on 11/11/16.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "BookmarkInfo.h"
#import "Utilities.h"

@implementation BookmarkInfo

@synthesize page;
@synthesize comment;

- (void)dealloc {
    self.comment = nil;
    
    [super dealloc];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    BookmarkInfo *other = object;
    
    return self.page == other.page;
}

+ (BookmarkInfo *)info:(int)page comment:(NSString *)comment {
    BookmarkInfo* ret = [[[BookmarkInfo alloc] init] autorelease];
    
    ret.page = page;
    ret.comment = comment;
    
    return ret;
}

+ (BookmarkInfo *)infoWithDictionary:(NSDictionary *)dict {
    return [self info:FOR_I(dict, @"page") comment:FOR(dict, @"comment")];
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    [dict setObject:[NSNumber numberWithInt:self.page] forKey:@"page"];
    [dict setObject:self.comment forKey:@"comment"];
    
    return dict;
}

@end
