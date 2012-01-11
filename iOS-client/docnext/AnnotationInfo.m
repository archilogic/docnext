//
//  AnnotationInfo.m
//  docnext
//
//  Created by  on 11/11/24.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AnnotationInfo.h"
#import "Utilities.h"

@implementation AnnotationInfo

@synthesize region;

+ (AnnotationInfo *)infoWithDictionary:(NSDictionary *)dict {
    NSDictionary* action = FOR(dict, @"action");
    
    AnnotationInfo* ret;
    
    if ([FOR(action, @"action") isEqualToString:@"URI"]) {
        URILinkAnnotationInfo* info = [[[URILinkAnnotationInfo alloc] init] autorelease];
        
        info.uri = FOR(action, @"uri");
        
        ret = info;
    } else if ([FOR(action, @"action") isEqualToString:@"GoToPage"]) {
        PageLinkAnnotationInfo* info = [[[PageLinkAnnotationInfo alloc] init] autorelease];
        
        info.page = FOR_I(action, @"page");
        
        ret = info;
    } else if ([FOR(action, @"action") isEqualToString:@"Movie"]) {
        MovieAnnotationInfo* info = [[[MovieAnnotationInfo alloc] init] autorelease];
        
        info.provider = FOR(action, @"provider");
        info.target = FOR(action, @"target");
        info.protocol = FOR(action, @"protocol");
        info.useDRM = FOR_B(action, @"useDRM");
        
        ret = info;
    } else {
        assert(0);
    }
    
    NSDictionary* region = FOR(dict, @"region");
    
    ret.region = CGRectMake(FOR_F(region, @"x"), FOR_F(region, @"y"), FOR_F(region, @"width"), FOR_F(region, @"height"));

    return ret;
}

@end

@implementation URILinkAnnotationInfo

@synthesize uri;

- (void)dealloc {
    self.uri = nil;
    
    [super dealloc];
}

@end

@implementation PageLinkAnnotationInfo

@synthesize page;

@end

@implementation MovieAnnotationInfo

@synthesize provider;
@synthesize target;
@synthesize protocol;
@synthesize useDRM;

- (void)dealloc {
    self.protocol = nil;
    self.target = nil;
    self.protocol = nil;
    
    [super dealloc];
}

@end
