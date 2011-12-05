//
//  DocInfo.m
//  docnext
//
//  Created by  on 11/09/28.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "DocInfo.h"
#import "Utilities.h"
#import "OrientationUtil.h"
#import "ImageInfo.h"

@implementation DocInfo

@synthesize docId;
@synthesize types;
@synthesize pages;
@synthesize singlePages;
@synthesize toc;
@synthesize title;
@synthesize publisher;
@synthesize binding;
@synthesize flow;

#pragma mark private

- (void)dealloc {
    self.docId = nil;
    self.types = nil;
    self.singlePages = nil;
    self.toc = nil;
    self.title = nil;
    self.publisher = nil;
    
    [super dealloc];
}

+ (NSArray *)convertTypes:(NSArray *)types {
    NSMutableArray* ret = [NSMutableArray array];
    
    for (NSNumber *val in types) {
        if (val.intValue == 0) {
            [ret addObject:NUM_I(ProviderDocumentTypeImage)];
        } else {
            assert(0);
        }
    }
    
    return ret;
}

+ (ProviderBindingType)parseBinding:(NSObject *)binding {
    if (binding == nil || binding == [NSNull null]){
        // use default value
        return ProviderBindingTypeRight;
    } else if ([binding isKindOfClass:[NSString class]]) {
        NSString* sBinding = (NSString *)binding;
        
        if ([sBinding compare:@"left" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return ProviderBindingTypeLeft;
        } else if ([sBinding compare:@"right" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return ProviderBindingTypeRight;
        } else {
            assert(0);
        }
    } else if ([binding isKindOfClass:[NSNumber class]]) {
        NSNumber* nBinding = (NSNumber *)binding;
        
        return nBinding.intValue;
    } else {
        assert(0);
    }
}

+ (ProviderFlowDirectionType)parseFlow:(NSObject *)flow {
    if (flow == nil || flow == [NSNull null]){
        // use default value
        return ProviderFlowDirectionTypeToLeft;
    } else if ([flow isKindOfClass:[NSString class]]) {
        NSString* sFlow = (NSString *)flow;
        
        if ([sFlow compare:@"right" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return ProviderFlowDirectionTypeToRight;
        } else if ([sFlow compare:@"left" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return ProviderFlowDirectionTypeToLeft;
        } else {
            assert(0);
        }
    } else if ([flow isKindOfClass:[NSNumber class]]) {
        NSNumber* nFlow = (NSNumber *)flow;
        
        return nFlow.intValue;
    } else {
        assert(0);
    }
}

- (NSArray *)singlePagesForPortrait:(NSArray *)spreadOnlyPages {
    NSMutableArray* heads = [NSMutableArray array];
    
    for (int page = 0; page < pages + spreadOnlyPages.count;) {
        [heads addObject:NUM_I(page)];

        if ([singlePages containsObject:NUM_I(page)] || [singlePages containsObject:NUM_I(page)]) {
            page++;
        } else {
            page += 2;
        }
    }
    
    for (NSNumber* p in [spreadOnlyPages reverseObjectEnumerator]) {
        int index = [heads indexOfObject:p];
        
        int greaterIndex = heads.count;
        
        for (int i = 0; i < heads.count; i++) {
            if ( AT_AS(heads, i, NSNumber).intValue > p.intValue ) {
                greaterIndex = i;
                break;
            }
        }
        
        for (int after = greaterIndex; after < heads.count; after++) {
            [heads replaceObjectAtIndex:after withObject:NUM_I(AT_AS(heads, after, NSNumber).intValue - 1)];
        }
        
        if (index != -1) {
            if (index + 1 < heads.count && AT_AS(heads, index + 1, NSNumber).intValue - AT_AS(heads, index, NSNumber).intValue == 1) {
                [heads removeObjectAtIndex:index];
            }
        }
    }
    
    NSMutableArray* ret = [NSMutableArray array];
    
    for (int index = 0; index < heads.count - 1; index++) {
        if (AT_AS(heads, index + 1, NSNumber).intValue - AT_AS(heads, index, NSNumber).intValue == 1) {
            [ret addObject:AT(heads, index)];
        }
    }
    
    return ret;
}

- (NSArray *)tocForPortrait:(NSArray *)spreadOnlyPages {
    NSMutableArray* ret = [NSMutableArray array];
    
    for (NSDictionary* elem in self.toc) {
        [ret addObject:[NSMutableDictionary dictionaryWithDictionary:elem]];
    }

    for (NSNumber* p in [spreadOnlyPages reverseObjectEnumerator]) {
        int greaterIndex = ret.count;
        
        for (int i = 0; i < ret.count; i++) {
            if (FOR_I(AT_AS(ret, i, NSDictionary), @"page") > p.intValue) {
                greaterIndex = i;
                break;
            }
        }
        
        for (int after = greaterIndex; after < ret.count; after++) {
            [AT_AS(ret, after, NSMutableDictionary) setObject:NUM_I(FOR_I(AT_AS(ret, after, NSDictionary), @"page") - 1) forKey:@"page"];
        }
    }
    
    return ret;
}

#pragma mark public

+ (DocInfo *)infoWithDictionary:(NSDictionary *)dict {
    DocInfo* ret = [[[DocInfo alloc] init] autorelease];

    ret.docId = FOR(dict, @"id");

    ret.types = [self convertTypes:FOR(dict, @"types")];
    
    ret.pages = FOR_I(dict, @"pages");
    ret.singlePages = FOR(dict, @"singlePages");
    ret.toc = FOR(dict, @"toc");
    ret.title = FOR(dict, @"title");
    ret.publisher = FOR(dict, @"publisher");
    
    ret.binding = [self parseBinding:FOR(dict, @"binding")];
    ret.flow = [self parseFlow:FOR(dict, @"flow")];
    
    return ret;
}

- (NSSet *)firstPages:(ImageInfo *)image {
    NSMutableSet* set = [NSMutableSet set];
    
    NSArray* sps = [self singlePages:image];
    int ps = [self pages:image];
    for (int page = 0; page < ps; page++) {
        if (![sps containsObject:NUM_I(page)] && (page == 0 || ![set containsObject:NUM_I(page - 1)]) && page != ps -1) {
            [set addObject:NUM_I(page)];
        }
    }
    
    return set;
}

- (int)pages:(ImageInfo *)image {
    return self.pages + ([OrientationUtil isSpreadMode] ? image.spreadOnlyPages.count : 0);
}

- (NSArray *)singlePages:(ImageInfo *)image {
    return [OrientationUtil isSpreadMode] ? self.singlePages : [self singlePagesForPortrait:image.spreadOnlyPages];
}

- (NSArray *)toc:(ImageInfo*)image {
    return [OrientationUtil isSpreadMode] ? self.toc : [self tocForPortrait:image.spreadOnlyPages];
}

@end
