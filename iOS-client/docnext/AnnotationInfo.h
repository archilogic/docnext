//
//  AnnotationInfo.h
//  docnext
//
//  Created by  on 11/11/24.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnnotationInfo : NSObject

@property(nonatomic) CGRect region;

+ (AnnotationInfo *)infoWithDictionary:(NSDictionary *)dict;

@end

@interface URILinkAnnotationInfo : AnnotationInfo

@property(nonatomic, retain) NSString* uri;

@end

@interface PageLinkAnnotationInfo : AnnotationInfo

@property(nonatomic) int page;

@end

@interface MovieAnnotationInfo : AnnotationInfo

@property(nonatomic, retain) NSString* provider; // TODO enum
@property(nonatomic, retain) NSString* target;
@property(nonatomic, retain) NSString* protocol; // TODO enum
@property(nonatomic) BOOL useDRM;

@end