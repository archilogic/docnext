//
//  ImageAnnotationInfo.h
//  docnext
//
//  Created by  on 11/11/25.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnnotationInfo.h"

@interface ImageAnnotationInfo : NSObject

@property(nonatomic, retain) AnnotationInfo* annotation;
@property(nonatomic) CGRect frame;

+ (ImageAnnotationInfo *)infoWithAnnotation:(AnnotationInfo *)annotation;

@end
