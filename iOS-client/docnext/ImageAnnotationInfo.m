//
//  ImageAnnotationInfo.m
//  docnext
//
//  Created by  on 11/11/25.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageAnnotationInfo.h"

@implementation ImageAnnotationInfo

@synthesize annotation;
@synthesize frame;

- (void)dealloc {
    self.annotation = nil;
    
    [super dealloc];
}

+ (ImageAnnotationInfo *)infoWithAnnotation:(AnnotationInfo *)annotation {
    ImageAnnotationInfo* ret = [[[ImageAnnotationInfo alloc] init] autorelease];
    
    ret.annotation = annotation;
    
    return ret;
}

@end
