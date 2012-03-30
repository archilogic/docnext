//
//  DownloaderItem.m
//  docnext
//
//  Created by  on 11/09/15.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "DownloaderItem.h"

@implementation DownloaderItem

@synthesize docId;
@synthesize permitType;
@synthesize saveLimit;
@synthesize endpoint;
@synthesize insertPosition;
@synthesize sequence;
@synthesize title;

- (id)initWithParam:(NSString *)aDocId permitType:(DownloaderPermitType)aPermitType saveLimit:(DownloaderSaveLimit)aSaveLimit endpoint:(NSString *)aEndpoint insertPosition:(DownloaderInsertPosition)aInsertPosition title:(NSString *)aTitle {
    self = [super init];
    
    if (self) {
        self.docId = aDocId;
        self.permitType = aPermitType;
        self.saveLimit = aSaveLimit;
        self.endpoint = aEndpoint;
        self.insertPosition = aInsertPosition;
        self.title = aTitle;
        self.sequence = 0;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    
    if (self) {
        self.docId = [decoder decodeObjectForKey:@"docId"];
        self.permitType = [decoder decodeIntForKey:@"permitType"];
        self.saveLimit = [decoder decodeIntForKey:@"saveLimit"];
        self.endpoint = [decoder decodeObjectForKey:@"endpoint"];
        self.insertPosition = [decoder decodeIntForKey:@"insertPosition"];
        self.title = [decoder decodeObjectForKey:@"title"];
        self.sequence = [decoder decodeIntForKey:@"sequence"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.docId forKey:@"docId"];
    [encoder encodeInt:self.permitType forKey:@"permitType"];
    [encoder encodeInt:self.saveLimit forKey:@"saveLimit"];
    [encoder encodeObject:self.endpoint forKey:@"endpoint"];
    [encoder encodeInt:self.insertPosition forKey:@"insertPosition"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeInt:self.sequence forKey:@"sequence"];
}

- (void)dealloc {
    self.docId = nil;
    self.endpoint = nil;
    self.title = nil;
    
    [super dealloc];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    DownloaderItem *other = object;
    
    return [self.docId isEqualToString:other.docId];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<DownloaderItem: docId: %@>", self.docId];
}

#pragma mark public

+ (DownloaderItem *)itemWithParam:(NSString *)docId permitType:(DownloaderPermitType)permitType saveLimit:(DownloaderSaveLimit)saveLimit endpoint:(NSString *)endpoint insertPosition:(DownloaderInsertPosition)insertPosition title:(NSString *)title {
    return [[[DownloaderItem alloc] initWithParam:docId permitType:permitType saveLimit:saveLimit endpoint:endpoint insertPosition:insertPosition title:title] autorelease];
}

@end
