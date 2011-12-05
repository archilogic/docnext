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
@synthesize suspend;
@synthesize sequence;

- (id)initWithParam:(NSString *)p_docId permitType:(DownloaderPermitType)p_permitType saveLimit:(DownloaderSaveLimit)p_saveLimit endpoint:(NSString *)p_endpoint insertPosition:(DownloaderInsertPosition)p_insertPosition {
    self = [super init];
    
    if (self) {
        self.docId = p_docId;
        self.permitType = p_permitType;
        self.saveLimit = p_saveLimit;
        self.endpoint = p_endpoint;
        self.insertPosition = p_insertPosition;
        self.suspend = NO;
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
        self.suspend = [decoder decodeBoolForKey:@"suspend"];
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
    [encoder encodeBool:self.suspend forKey:@"suspend"];
    [encoder encodeInt:self.sequence forKey:@"sequence"];
}

- (void)dealloc {
    self.docId = nil;
    self.endpoint = nil;
    
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

#pragma mark public

+ (DownloaderItem *)itemWithParam:(NSString *)docId permitType:(DownloaderPermitType)permitType saveLimit:(DownloaderSaveLimit)saveLimit endpoint:(NSString *)endpoint insertPosition:(DownloaderInsertPosition)insertPosition {
    return [[[DownloaderItem alloc] initWithParam:docId permitType:permitType saveLimit:saveLimit endpoint:endpoint insertPosition:insertPosition] autorelease];
}

@end
