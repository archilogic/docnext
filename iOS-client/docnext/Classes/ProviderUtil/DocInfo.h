//
//  DocInfo.h
//  docnext
//
//  Created by  on 11/09/28.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProviderTypes.h"

@class ImageInfo;

@interface DocInfo : NSObject

@property(nonatomic, retain) NSString* docId;
@property(nonatomic, retain) NSArray* types;
@property(nonatomic) int pages;
@property(nonatomic, retain) NSArray* singlePages;
@property(nonatomic, retain) NSArray* toc;
@property(nonatomic, retain) NSString* title;
@property(nonatomic, retain) NSString* publisher;
@property(nonatomic) ProviderBindingType binding;
@property(nonatomic) ProviderFlowDirectionType flow;

+ (DocInfo *)infoWithDictionary:(NSDictionary *)dict;

- (NSSet *)firstPages:(ImageInfo *)image;
- (int)pages:(ImageInfo *)image;
- (NSArray *)singlePages:(ImageInfo *)image;
- (NSArray *)toc:(ImageInfo *)image;

@end
