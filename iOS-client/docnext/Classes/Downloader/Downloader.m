//
//  Downloader.m
//  docnext
//
//  Created by  on 11/09/15.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "Downloader.h"
#import "ASIHTTPRequest.h"
#import "FileUtil.h"
#import "DownloaderItem.h"
#import "LocalPathUtil.h"
#import "RemotePathUtil.h"
#import "LocalProviderUtil.h"
#import "ImageLevelUtil.h"
#import "Utilities.h"
#import "DownloaderState.h"
#import "UIStringTagAlertView.h"

NSString* const DOWNLOADER_PROGRESS = @"downloader_progress";
NSString* const DOWNLOADER_COMPLETE = @"downloader_complete";
NSString* const DOWNLOADER_FAILED = @"downloader_failed";

NSString* const DOWNLOADER_IMAGE_INIT_DOWNLOADED = @"downloader_image_init_downloaded";
NSString* const DOWNLOADER_TEXTURE_PROGRESS = @"downloader_texture_progress";
NSString* const DOWNLOADER_ANNOTATION_PROGRESS = @"downloader_annotation_progress";

#define WORKING_SIZE 1

@interface Downloader ()

@property(nonatomic, retain) NSMutableArray* states;
@property(nonatomic) UIBackgroundTaskIdentifier bgTaskId;
@property(nonatomic) BOOL stopped;
@property(nonatomic, retain) NSLock* lock;

- (void)checkFurtherItem;

@end

@implementation Downloader

@synthesize states;
@synthesize bgTaskId;
@synthesize stopped;
@synthesize lock;

#pragma mark private

#pragma mark singleton

static Downloader* _instance = nil;

+ (id)allocWithZone:(NSZone*)zone {
    @synchronized(self) {
        if (!_instance) {
            _instance = [super allocWithZone:zone];
            return _instance;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone*)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;
}

- (oneway void)release {
}

- (id)autorelease {
    return self;
} 

#pragma mark -

- (id)init {
    self = [super init];
    
    if (self) {
        self.states = [NSMutableArray array];
        self.bgTaskId = UIBackgroundTaskInvalid;
        self.stopped = NO;
        self.lock = [[[NSLock alloc] init] autorelease];
    }
    
    return self;
}

- (void)dealloc {
    self.states = nil;
    self.lock = nil;
    
    [super dealloc];
}

- (DownloaderItem *)findItemByDocId:(NSArray *)array docId:(NSString *)docId {
    for (DownloaderItem* item in array) {
        if ([item.docId isEqualToString:docId]) {
            return item;
        }
    }
    
    return nil;
}

- (DownloaderState *)findStateByItem:(NSArray *)array item:(DownloaderItem *)item {
    for (DownloaderState* state in array) {
        if ([state.item isEqual:item]) {
            return state;
        }
    }
    
    return nil;
}

- (void)checkFurtherItem {
    if (self.stopped) {
        return;
    }
    
    [self.lock lock];
    
    NSMutableArray *queue = [LocalProviderUtil downloaderInfo];
    
    if (queue.count == 0) {
        [self.lock unlock];
        [self stop];
        return;
    }
    
    for (int index = 0; index < self.states.count; index++) {
        DownloaderState* state = [[AT(self.states, index) retain] autorelease];
        
        if (state.didFinished) {
            [self.states removeObjectAtIndex:index];
            [queue removeObject:[self findItemByDocId:queue docId:state.item.docId]];
            
            [LocalProviderUtil setDownloaderInfo:queue];
            
            index--;
            continue;
        }
        
        [state invoke];
    }
    
    [self.lock unlock];
    
    int qIndex = 0;
    while (self.states.count < WORKING_SIZE && qIndex < queue.count) {
        DownloaderItem* item = AT(queue, qIndex++);
        
        if ([self findStateByItem:self.states item:item]) {
            continue;
        }
        
        [self.states addObject:[DownloaderState stateWithItem:item lock:self.lock delegate:self]];
    }
}

- (BOOL)isRunning {
    return self.states.count > 0;
}

- (void)loop {
    while (true) {
        @autoreleasepool {
            [self checkFurtherItem];
            
            if (!self.isRunning) {
                break;
            }
        }
        
        [NSThread sleepForTimeInterval:0.1];
    }
}

- (void)dequeueItem:(NSString *)docId willDelete:(BOOL)willDelete {
    NSError* err = nil;
    
    [self.lock lock];
    
    NSMutableArray *queue = [LocalProviderUtil downloaderInfo];

    DownloaderItem* item = [self findItemByDocId:queue docId:docId];
    
    if (!item) {
        assert(0);
    }
    
    DownloaderState* state = [self findStateByItem:self.states item:item];
    
    if (state) {
        [state stop:willDelete];
        [self.states removeObject:state];
    } else {
        if (willDelete) {
            NSString* path = [LocalPathUtil docDir:item.docId];
            
            if ([FileUtil exists:path]) {
                [[NSFileManager defaultManager] removeItemAtPath:[FileUtil fullPath:path] error:&err];
                if (err) {
                    NSLog(@"Error: %@", err);
                    assert(0);
                }
            }
        }
    }
    
    [queue removeObject:item];
    
    [LocalProviderUtil setDownloaderInfo:queue];
    
    [self.lock unlock];
}

#pragma mark public

+ (Downloader *)instance {
    @synchronized(self) {
        if (!_instance) {
            _instance = [[[self alloc] init] retain];
        }
    }
    
    return _instance;
}

- (void)start {
    if (self.isRunning) {
        return;
    }
    
    self.stopped = NO;
    
    self.bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stop];
        });
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self loop];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stop];
        });
    });
}

- (void)stop {
    self.stopped = YES;

    for (DownloaderState* state in self.states) {
        [state stop:NO];
    }
    
    [self.states removeAllObjects];
    
    if (self.bgTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTaskId];
        self.bgTaskId = UIBackgroundTaskInvalid;
    }
}

- (void)addItem:(NSString *)docId permitType:(DownloaderPermitType)permitType saveLimit:(DownloaderSaveLimit)saveLimit endpoint:(NSString *)endpoint insertPosition:(DownloaderInsertPosition)insertPosition title:(NSString *)title {

    [self.lock lock];
    
    NSMutableArray *queue = [LocalProviderUtil downloaderInfo];
    
    if (!queue) {
        NSLog(@"create downloader info");
        queue = [NSMutableArray array];
    }
    
    for (DownloaderItem* item in queue) {
        if ([item.docId isEqual:docId]) {
            NSLog(@"requested docuemnt is already in queue");
            
            [self.lock unlock];
            [self start];

            return;
        }
    }
    
    DownloaderItem* item = [DownloaderItem itemWithParam:docId permitType:permitType saveLimit:saveLimit endpoint:endpoint insertPosition:insertPosition title:title];
    
    if (insertPosition == DownloaderInsertPositionHead) {
        [queue insertObject:item atIndex:0];
    } else {
        [queue addObject:item];
    }
    
    [LocalProviderUtil setDownloaderInfo:queue];
    
    [self.lock unlock];
    [self start];
}

- (void)removeItem:(NSString *)docId {
    [self dequeueItem:docId willDelete:YES];
}

- (void)suspendItem:(NSString *)docId {
    [self dequeueItem:docId willDelete:NO];
}

- (NSArray *)list {
    NSMutableArray *queue = [LocalProviderUtil downloaderInfo];
    
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:queue.count];
    
    for (DownloaderItem* item in queue) {
        [list addObject:item.docId];
    }
    
    return list;
}

- (void)sort:(NSArray *)docIds {
    [self.lock lock];
    
    NSMutableArray *queue = [LocalProviderUtil downloaderInfo];
    
    NSMutableArray *sorted = [NSMutableArray arrayWithCapacity:queue.count];

    for (NSString* docId in docIds) {
        DownloaderItem* item = [self findItemByDocId:queue docId:docId];

        [sorted addObject:item];
        [queue removeObject:item];
    }
    
    if (queue.count > 0) {
        @throw @"set is not equal";
    }
    
    [LocalProviderUtil setDownloaderInfo:sorted];
    
    [self.lock unlock];
    
    [self stop];
    [self start];
}

@end
