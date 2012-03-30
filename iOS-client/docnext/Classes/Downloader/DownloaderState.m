//
//  DownloaderState.m
//  docnext
//
//  Created by  on 11/10/24.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "DownloaderState.h"
#import "ASIHTTPRequest.h"
#import "FileUtil.h"
#import "LocalProviderUtil.h"
#import "Downloader.h"
#import "LocalPathUtil.h"
#import "RemotePathUtil.h"
#import "ImageLevelUtil.h"
#import "Utilities.h"
#import "TexturePosition.h"
#import "Reachability.h"
#import "UIStringTagAlertView.h"
#import "DebugLog.h"
#import "ImageViewController.h"

#define THUMBNAIL_BLOCK 16

@interface DownloaderState ()

@property(nonatomic, assign) NSLock* lock;
@property(nonatomic, retain) ASIHTTPRequest* req;
@property(atomic) BOOL running;
@property(atomic) BOOL shouldStop;
@property(atomic) BOOL working;
@property(nonatomic, assign) Downloader* delegate;

- (float)calcProgress;

@end

@implementation DownloaderState

@synthesize item;

@synthesize lock;
@synthesize req;
@synthesize running;
@synthesize shouldStop;
@synthesize willDelete;
@synthesize working;
@synthesize delegate;

- (id)initWithItem:(DownloaderItem *)p_item lock:(NSLock *)p_lock delegate:(Downloader *)p_delegate {
    self = [super init];
    
    if (self) {
        self.item = p_item;
        self.lock = p_lock;
        self.req = nil;
        self.running = YES;
        self.shouldStop = NO;
        self.willDelete = NO;
        self.working = NO;
        self.delegate = p_delegate;
    }
    
    return self;
}

- (void)dealloc {
    self.item = nil;
    self.lock = nil;
    self.req = nil;
    self.delegate = nil;
    
    [super dealloc];
}

- (void)findAndIncOrFail:(NSMutableArray *)queue {
    if (self.shouldStop) {
        return;
    }
    
    for (DownloaderItem* i in queue) {
        if ([i isEqual:self.item]) {
            i.sequence++;
            return;
        }
    }
    
    NSLog(@"assert: docId: %@", self.item.docId);
    assert(0);
}

- (void)proceedSequence {
    [self.lock lock];
    
    NSMutableArray *queue = [LocalProviderUtil downloaderInfo];
    [self findAndIncOrFail:queue];
    [LocalProviderUtil setDownloaderInfo:queue];
    
    [self.lock unlock];
    
    self.item.sequence++;
}

- (unsigned long long)availableStorage {
    NSError *err = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&err];
    if (err) {
        NSLog(@"Error: %@", err);
        assert(0);
    }
    
    if (dictionary) {
        return [[dictionary objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
    } else {
        NSLog(@"Error Obtaining System Memory Info");
        return 0;
    }
}

- (unsigned long long)fileSize:(NSString *)path {
    NSError* err = nil;
    
    NSDictionary* dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&err];
    if (err) {
        NSLog(@"Error: %@", err);
        assert(0);
    }
    
    return [[dict objectForKey:NSFileSize] unsignedLongLongValue];
}

- (void)error:(NSString *)messageFormat {
    [NSThread sleepForTimeInterval:3];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", nil) message:[NSString stringWithFormat:messageFormat, self.item.title] delegate:self.delegate cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] autorelease] show];
    });
    
    self.running = NO;
}

- (NSString *)genTempPath {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"temp%f%d", [NSDate timeIntervalSinceReferenceDate], arc4random()]];
}

- (void)downloadInternal:(NSString *)remotePath urlRef:(NSURL **)urlRef tempRef:(NSString **)tempRef {
    if (![Reachability reachabilityForInternetConnection].isReachable) {
        [self error:NSLocalizedString(@"message_confirm_retry_network_problem_with_title", nil)];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:remotePath];
    
    NSString* temp = [self genTempPath];

#ifdef DebugLogLevelVerbose
    NSLog(@"temp: %@", temp);
    NSLog(@"remotePath: %@, url: %@", remotePath, url);
#endif
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    self.req = request;
    
    request.timeOutSeconds = 20;
    request.downloadDestinationPath = temp;
    
    request.failedBlock = ^{
        NSLog(@"Request Failed: url: %@, %@", remotePath, request.error.localizedDescription);
    };
    
    [request startSynchronous];

    int sc = request.responseStatusCode;
    if (sc != 200 || request.error) {
        if (request.error && request.error.code == ASIRequestCancelledErrorType) {
            return;
        }
        
        NSLog(@"statusCode: %d, statusMessage: %@, error: %@, url: %@", sc, request.responseStatusMessage, request.error, remotePath);
        NSLog(@"body: %@", request.responseString);
        
        [self error:NSLocalizedString(@"message_confirm_retry_server_error_with_title", nil)];
        
        return;
    }
    
#ifdef DebugLogLevelVerbose
    NSError* err = nil;
    NSLog(@"downloaded string: %@", [NSString stringWithContentsOfFile:temp encoding:NSUTF8StringEncoding error:&err]);
    if (err) {
        NSLog(@"Seems to be binary file. Error: %@", err);
        err = nil;
    }
    NSData *data = [NSData dataWithContentsOfFile:temp options:0 error:&err];
    NSLog(@"downloaded data: %@", [data subdataWithRange:NSMakeRange(0, MIN([data length], 128))]);
    if (err) {
        NSLog(@"Error: %@", err);
        NSLog(@"statusCode: %d", sc);
        err = nil;
    }
#endif
    
    if (self.shouldStop) {
        return;
    }

    *urlRef = url;
    *tempRef = temp;
}

- (void)download:(NSString *)remotePath localPath:(NSString *)localPath complete:(void (^)(void))complete {
    NSURL *url = nil;
    NSString *temp = nil;
    
    [self downloadInternal:remotePath urlRef:&url tempRef:&temp];
    
    if (!url) {
        return;
    }
    
    if ([self fileSize:temp] > [self availableStorage]) {
        [self error:NSLocalizedString(@"message_error_no_storage_space_with_title", nil)];
        return;
    }
    
    [FileUtil ensureDir:[localPath stringByDeletingLastPathComponent]];

    [[NSFileManager defaultManager] moveItemAtPath:temp toPath:[FileUtil fullPath:localPath] error:nil];
    
    complete();
    
    self.req = nil;
}

- (void)downloadConcat:(NSString *)remotePath localPaths:(NSArray *)localPaths progress:(void (^)(int))progress complete:(void (^)(void))complete {
    NSError* err = nil;

    NSURL *url = nil;
    NSString *temp = nil;
    
    [self downloadInternal:remotePath urlRef:&url tempRef:&temp];
    
    if (!url) {
        return;
    }

    // TODO very simple implementation. need to modify (to use ASIHTTPRequest#didDataReceived or something like) if real-time decoding is required.

    NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:temp];
    
    for (int index = 0; index < localPaths.count; index++) {
        @autoreleasepool {
            NSString* localPath = AT(localPaths, index);
            
            int length = OSReadBigInt64([fh readDataOfLength:8].bytes, 0);
            
            if (length > [self availableStorage]) {
                [self error:NSLocalizedString(@"message_error_no_storage_space_with_title", nil)];
                return;
            }
            
            NSString* part = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"part%f", [NSDate timeIntervalSinceReferenceDate]]];
            
            NSData* sub = [fh readDataOfLength:length];
            
            if (length != sub.length) {
                NSLog(@"length != sub.length (%d != %d)", length, sub.length);
                [self error:NSLocalizedString(@"message_error_broken_item_with_title", nil)];
                return;
            }
            
            // condition for already downloaded files
            if (![[NSFileManager defaultManager] fileExistsAtPath:[FileUtil fullPath:localPath]]) {
                [sub writeToFile:part options:NSDataWritingAtomic error:&err];
                if (err) {
                    NSLog(@"Error: %@", err);
                    assert(0);
                }
                
                [FileUtil ensureDir:[localPath stringByDeletingLastPathComponent]];
                
                [[NSFileManager defaultManager] moveItemAtPath:part toPath:[FileUtil fullPath:localPath] error:nil];
            }
            
            progress(index);
        }
    }
    
    if ([fh readDataToEndOfFile].length > 0) {
        NSLog(@"Incomplete data");
        [self error:NSLocalizedString(@"message_error_broken_item_with_title", nil)];
        return;
    }
    
    [fh closeFile];
    
    complete();
    
    self.req = nil;
}

- (void)cleanup {
    if (self.shouldStop) {
        return;
    }
    
    [LocalProviderUtil setCompleted:self.item.docId];
    [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_COMPLETE object:self.item.docId userInfo:nil];
    
    self.running = NO;
}

- (NSArray *)requiredThumbnailsFrom:(int)from {
    NSMutableArray* ret = [NSMutableArray array];
    
    DocInfo* doc = [LocalProviderUtil info:self.item.docId];
    
    for (int page = from; page < doc.pages; page++) {
        if (![FileUtil exists:[LocalPathUtil imageThumbnailPath:self.item.docId page:page]]) {
            [ret addObject:NUM_I(page)];
            
            if (ret.count >= THUMBNAIL_BLOCK) {
                break;
            }
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
            
            [self proceedSequence];
        }
    }
    
    return ret;
}

- (void)ensureImageThumbnailBlock:(int)page {
    NSArray *required = [self requiredThumbnailsFrom:page];
    
    if (required.count == 0) {
        // already
        return;
    }
    
    NSMutableArray *localPaths = [NSMutableArray array];
    
    for (NSNumber *pos in required) {
        [localPaths addObject:[LocalPathUtil imageThumbnailPath:self.item.docId page:pos.intValue]];
    }
    
    NSString* remotePath = [RemotePathUtil imageThumbnailBlockPath:self.item.endpoint pages:required];
    
    [self downloadConcat:remotePath localPaths:localPaths progress:^(int index){
        if (self.shouldStop) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        
        [self proceedSequence];
    } complete:^{
    }];
}

- (void)ensureImageThumbnailEach:(int)page {
    if ([FileUtil exists:[LocalPathUtil imageThumbnailPath:self.item.docId page:page]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        
        [self proceedSequence];
        return;
    }
    
    [self download:[RemotePathUtil imageThumbnailPath:self.item.endpoint page:page] localPath:[LocalPathUtil imageThumbnailPath:self.item.docId page:page] complete:^{
        if (self.shouldStop) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        
        [self proceedSequence];
    }];
}

- (void)ensureImageThumbnail:(int)page {
    if (self.shouldStop) {
        return;
    }
    
    NSURL* url = [NSURL URLWithString:self.item.endpoint];
    
    if ([url.pathComponents containsObject:@"docnext_p"] || [url.pathComponents containsObject:@"docnext_p_c"]) {
        [self ensureImageThumbnailBlock:page];
    } else {
        [self ensureImageThumbnailEach:page];
    }
}

- (void)calcNxNy:(ImageInfo *)image level:(int)level minLevel:(int)minLevel nxRef:(int *)nxRef nyRef:(int *)nyRef {
    if (level != image.maxLevel || !image.isUseActualSize) {
        int width = (int) (TEXTURE_SIZE * pow(2, minLevel));
        int height = image.height * width / image.width;
        
        int factor = (int) pow(2, level - minLevel);
        
        *nxRef = ( width * factor - 1 ) / TEXTURE_SIZE + 1;
        *nyRef = ( height * factor - 1 ) / TEXTURE_SIZE + 1;
    } else {
        *nxRef = ( image.width - 1 ) / TEXTURE_SIZE + 1;
        *nyRef = ( image.height - 1 ) / TEXTURE_SIZE + 1;
    }
}

- (int)calcPerPage:(ImageInfo *)image minLevel:(int)minLevel maxLevel:(int)maxLevel {
    int sum = 0;
    
    for (int level = minLevel; level <= maxLevel; level++) {
        int nx;
        int ny;
        
        [self calcNxNy:image level:level minLevel:minLevel nxRef:&nx nyRef:&ny];
        
        sum += nx * ny;
    }
    
    return sum;
}

- (NSArray *)requiredTexturesByLevel:(ImageInfo *)image page:(int)page level:(int)level minLevel:(int)minLevel {
    NSMutableArray* ret = [NSMutableArray array];

    int nx;
    int ny;
    
    [self calcNxNy:image level:level minLevel:minLevel nxRef:&nx nyRef:&ny];
    
    for (int py = 0; py < ny; py++) {
        for (int px = 0; px < nx; px++) {
            if (![FileUtil exists:[LocalPathUtil imageTexturePath:self.item.docId page:page level:level px:px py:py isWebp:NO]]) {
                [ret addObject:[TexturePosition positionWithParmas:level px:px py:py]];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
                
                [self proceedSequence];
            }
        }
    }
    
    return ret;
}

- (NSArray *)requiredTexturesByPage:(ImageInfo *)image page:(int)page minLevel:(int)minLevel maxLevel:(int)maxLevel {
    NSMutableArray* ret = [NSMutableArray array];
    
    for (int level = minLevel; level <= maxLevel; level++) {
        [ret addObjectsFromArray:[self requiredTexturesByLevel:image page:page level:level minLevel:minLevel]];
    }
    
    return ret;
}

- (void)ensureImageTexturePerPage:(int)page image:(ImageInfo *)image {
    int minLevel = [ImageLevelUtil minLevel:image.maxLevel];
    int maxLevel = [ImageLevelUtil maxLevel:minLevel imageMaxLevel:image.maxLevel imageMaxNumberOfLevel:image.maxNumberOfLevel];
    
    NSArray *required = [self requiredTexturesByPage:image page:page minLevel:minLevel maxLevel:maxLevel];
    
    if (required.count == 0) {
        // already
        return;
    }
    
    NSMutableArray *localPaths = [NSMutableArray arrayWithCapacity:required.count];
    
    for (TexturePosition *pos in required) {
        [localPaths addObject:[LocalPathUtil imageTexturePath:self.item.docId page:page level:pos.level px:pos.px py:pos.py isWebp:image.isWebp]];
    }
    
    NSString* remotePath = [RemotePathUtil imageTexturePerPagePath:self.item.endpoint page:page texs:required isWebp:image.isWebp];
    
    [self downloadConcat:remotePath localPaths:localPaths progress:^(int index){
        if (self.shouldStop) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        
        TexturePosition* tp = AT(required, index);
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_TEXTURE_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_I(page), @"page", NUM_I(tp.level), @"level", NUM_I(tp.px), @"px", NUM_I(tp.py), @"py", nil]];
        
        [self proceedSequence];
    } complete:^{
    }];
}

- (void)ensureImageTexturePerLevel:(int)page level:(int)level image:(ImageInfo *)image {
    int minLevel = [ImageLevelUtil minLevel:image.maxLevel];
    
    NSArray *required = [self requiredTexturesByLevel:image page:page level:level minLevel:minLevel];
    
    if (required.count == 0) {
        // already
        return;
    }
    
    NSMutableArray *localPaths = [NSMutableArray array];
    
    for (TexturePosition *pos in required) {
        [localPaths addObject:[LocalPathUtil imageTexturePath:self.item.docId page:page level:pos.level px:pos.px py:pos.py isWebp:image.isWebp]];
    }
    
    [self downloadConcat:[RemotePathUtil imageTextureConcatPath:self.item.endpoint page:page level:level] localPaths:localPaths progress:^(int index){
        if (self.shouldStop) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        
        TexturePosition* tp = AT(required, index);
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_TEXTURE_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_I(page), @"page", NUM_I(tp.level), @"level", NUM_I(tp.px), @"px", NUM_I(tp.py), @"py", nil]];
        
        [self proceedSequence];
    } complete:^{
    }];
}

- (void)ensureImageTexturePerTexture:(int)page level:(int)level px:(int)px py:(int)py {
    if ([FileUtil exists:[LocalPathUtil imageTexturePath:self.item.docId page:page level:level px:px py:py isWebp:NO]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        
        [self proceedSequence];
        return;
    }
    
    [self download:[RemotePathUtil imageTexturePath:self.item.endpoint page:page level:level px:px py:py isWebp:NO] localPath:[LocalPathUtil imageTexturePath:self.item.docId page:page level:level px:px py:py isWebp:NO] complete:^{
        if (self.shouldStop) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_TEXTURE_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_I(page), @"page", NUM_I(level), @"level", NUM_I(px), @"px", NUM_I(py), @"py", nil]];
        
        [self proceedSequence];
    }];
}

- (void)ensureImageTexture:(int)page level:(int)level px:(int)px py:(int)py {
    if (self.shouldStop) {
        return;
    }
    
    ImageInfo* image = [LocalProviderUtil imageInfo:self.item.docId];
    
    NSURL* url = [NSURL URLWithString:self.item.endpoint];
    
    if ([url.pathComponents containsObject:@"docnext_p"] || [url.pathComponents containsObject:@"docnext_p_c"]) {
        [self ensureImageTexturePerPage:page image:image];
    } else {
        if(image.hasConcatFile) {
            [self ensureImageTexturePerLevel:page level:level image:image];
        } else {
            [self ensureImageTexturePerTexture:page level:level px:px py:py];
        }
    }
}

- (void)ensureImageAnnotation:(int)page {
    NSError* err = nil;
    
    if (self.shouldStop) {
        return;
    }
    
    void (^complete)(void) = ^{
        if (self.shouldStop) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_ANNOTATION_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_I(page), @"page", nil]];
        
        [self proceedSequence];
    };
    
    ImageInfo* image = [LocalProviderUtil imageInfo:self.item.docId];
    
    if (!image.hasAnnotation) {
        [[@"[]" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:[FileUtil fullPath:[LocalPathUtil imageAnnotationPath:self.item.docId page:page]] options:NSDataWritingAtomic error:&err];
        if (err) {
            NSLog(@"Error: %@", err);
            assert(0);
        }
        
        complete();
        return;
    }
    
    if ([FileUtil exists:[LocalPathUtil imageAnnotationPath:self.item.docId page:page]]){
        complete();
        return;
    }
    
    [self download:[RemotePathUtil imageAnnotationPath:self.item.endpoint page:page] localPath:[LocalPathUtil imageAnnotationPath:self.item.docId page:page] complete:complete];
}

- (void)ensureImageInfo {
    if (self.shouldStop) {
        return;
    }
    
    void (^complete)(void) = ^{
        if (self.shouldStop) {
            return;
        }
        
        [LocalProviderUtil setImageInitDownloaded:self.item.docId];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_IMAGE_INIT_DOWNLOADED object:self.item.docId];
        
        [self proceedSequence];
    };
    
    if ([FileUtil exists:[LocalPathUtil imageInfoPath:self.item.docId]]){
        complete();
        return;
    }
    
    [self download:[RemotePathUtil imageInfoPath:self.item.endpoint] localPath:[LocalPathUtil imageInfoPath:self.item.docId] complete:complete];
}
- (void)checkInfo {
    DocInfo* info = [LocalProviderUtil info:self.item.docId];
    
    if (info.types.count == 0) {
        NSLog(@"%@", info.types);
        assert(0);
    }
    
    if (AT_AS(info.types, 0, NSNumber).intValue == ProviderDocumentTypeImage) {
        [self ensureImageInfo];
    } else {
        assert(0);
    }
}

- (void)ensureInfo {
    if (self.shouldStop) {
        return;
    }
    
    void (^complete)(void) = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", self, @"state", nil]];
        
        [self checkInfo];
    };
    
    if ([FileUtil exists:[LocalPathUtil infoPath:self.item.docId]]){
        complete();
        return;
    }
    
    [self download:[RemotePathUtil infoPath:self.item.endpoint] localPath:[LocalPathUtil infoPath:self.item.docId] complete:complete];
}

- (float)calcProgress {
    int value = self.item.sequence;
    
    if (value < 1) {
        return 0.0001; // temporal value
    }

    DocInfo *doc = [LocalProviderUtil info:self.item.docId];
    
    if (AT_AS(doc.types, 0, NSNumber).intValue == ProviderDocumentTypeImage) {
        ImageInfo* image = [LocalProviderUtil imageInfo:self.item.docId];
        
        int minLevel = [ImageLevelUtil minLevel:image.maxLevel];
        int maxLevel = [ImageLevelUtil maxLevel:minLevel imageMaxLevel:image.maxLevel imageMaxNumberOfLevel:image.maxNumberOfLevel];
        
        int perPage = [self calcPerPage:image minLevel:minLevel maxLevel:maxLevel];
        
        return 1.0 * value / (perPage * doc.pages + doc.pages + doc.pages);
    }
    
    assert(0);
}

- (void)imageInvokeSingle:(int)value doc:(DocInfo *)doc {
    ImageInfo* image = [LocalProviderUtil imageInfo:self.item.docId];
    
    int minLevel = [ImageLevelUtil minLevel:image.maxLevel];
    int maxLevel = [ImageLevelUtil maxLevel:minLevel imageMaxLevel:image.maxLevel imageMaxNumberOfLevel:image.maxNumberOfLevel];
    
    // 1 for annotation
    int perPage = 1 + [self calcPerPage:image minLevel:minLevel maxLevel:maxLevel];
    
    if (value < doc.pages * perPage) {
        int page = value / perPage;
        value %= perPage;
        
        if (value < 1) {
            [self ensureImageAnnotation:page];
            return;
        }
        
        value--;
        
        for (int level = minLevel; level <= maxLevel; level++) {
            int nx;
            int ny;
            
            [self calcNxNy:image level:level minLevel:minLevel nxRef:&nx nyRef:&ny];
            
            if (value < nx * ny) {
                int px = value / ny;
                int py = value % ny;
                
                [self ensureImageTexture:page level:level px:px py:py];
                return;
            }
            
            value -= nx * ny;
        }
    }
    
    value -= doc.pages * perPage;
    
    if (value < doc.pages) {
        [self ensureImageThumbnail:value];
        return;
    }
    
    value -= doc.pages;
    
    if (value < 1) {
        [self cleanup];
        return;
    }
    
    NSLog(@"assert: docId: %@, value: %d", self.item.docId, value);
    assert(0);
}

- (void)invokeSingle {
    int value = self.item.sequence;
    
    if (value < 1) {
        [self ensureInfo];
        return;
    }
    
    value -= 1;
    
    DocInfo *doc = [LocalProviderUtil info:self.item.docId];
    
    if (AT_AS(doc.types, 0, NSNumber).intValue == ProviderDocumentTypeImage) {
        [self imageInvokeSingle:value doc:doc];
        return;
    }
    
    assert(0);
}

- (void)doInvocation {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSError* err = nil;
            
            if (self.shouldStop) {
                if (self.willDelete) {
                    NSString* path = [LocalPathUtil docDir:self.item.docId];
                    
                    if ([FileUtil exists:path]) {
                        [[NSFileManager defaultManager] removeItemAtPath:[FileUtil fullPath:path] error:&err];
                        if (err) {
                            NSLog(@"Error: %@", err);
                            assert(0);
                        }
                    }
                }
                
                self.working = NO;
                
                return;
            }
            
            [self invokeSingle];
            
            if (self.willDelete) {
                NSString* path = [LocalPathUtil docDir:self.item.docId];
                
                if ([FileUtil exists:path]) {
                    [[NSFileManager defaultManager] removeItemAtPath:[FileUtil fullPath:path] error:&err];
                    if (err) {
                        NSLog(@"Error: %@", err);
                        assert(0);
                    }
                }
            }
            
            self.working = NO;
        }
    });
}

#pragma mark public

+ (DownloaderState *)stateWithItem:(DownloaderItem *)item lock:(NSLock *)lock delegate:(id)delegate {
    return [[[DownloaderState alloc] initWithItem:item lock:lock delegate:delegate] autorelease];
}

- (void)invoke {
#ifdef DebugLogLevelDebug
    NSLog(@"DownloaderState#invoke");
#endif
    
    BOOL isWorking;
    @synchronized(self) {
        isWorking = self.working;
        if (!isWorking) {
            self.working = YES;
        }
    }
    
    if (!isWorking) {
        [self doInvocation];
    }
}

- (BOOL)didFinished {
    return !self.running;
}

- (void)stop:(BOOL)aWillDelete {
    NSError* err = nil;
    
    self.shouldStop = YES;
    self.willDelete = aWillDelete;
    
    if (!self.working && self.willDelete) {
        NSString* path = [LocalPathUtil docDir:self.item.docId];
        
        if ([FileUtil exists:path]) {
            [[NSFileManager defaultManager] removeItemAtPath:[FileUtil fullPath:path] error:&err];
            if (err) {
                NSLog(@"Error: %@", err);
                assert(0);
            }
        }
    }
    
    [self.req clearDelegatesAndCancel];
}
    
@end
