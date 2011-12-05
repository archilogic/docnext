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

#define THUMBNAIL_BLOCK 16

@interface DownloaderState ()

@property(nonatomic, assign) NSLock* lock;
@property(nonatomic, retain) ASIHTTPRequest* req;
@property(nonatomic) BOOL running;
@property(atomic) BOOL shouldStop;
@property(atomic) BOOL working;

- (float)calcProgress;

@end

@implementation DownloaderState

@synthesize item;

@synthesize lock;
@synthesize req;
@synthesize running;
@synthesize shouldStop;
@synthesize working;

- (id)initWithItem:(DownloaderItem *)p_item lock:(NSLock *)p_lock {
    self = [super init];
    
    if (self) {
        self.item = p_item;
        self.lock = p_lock;
        self.req = nil;
        self.running = YES;
        self.shouldStop = NO;
        self.working = NO;
    }
    
    return self;
}

- (void)dealloc {
    self.item = nil;
    self.lock = nil;
    self.req = nil;
    
    [super dealloc];
}

- (void)findAndIncOrFail:(NSMutableArray *)queue {
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
    
    NSMutableArray *queue = [NSKeyedUnarchiver unarchiveObjectWithFile:[FileUtil fullPath:[LocalPathUtil downloaderInfoPath]]];
    [self findAndIncOrFail:queue];
    [NSKeyedArchiver archiveRootObject:queue toFile:[FileUtil fullPath:[LocalPathUtil downloaderInfoPath]]];
    
    [self.lock unlock];
    
    self.item.sequence++;
}

- (void)download:(NSString *)remotePath localPath:(NSString *)localPath complete:(void (^)(void))complete {
    NSURL *url = [NSURL URLWithString:remotePath];
    
    NSString* temp = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]]];
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    self.req = request;
    
    request.downloadDestinationPath = temp;

    request.failedBlock = ^{
        NSLog(@"Request Failed: url: %@, %@", remotePath, request.error.localizedDescription);
    };
    
    [request startSynchronous];
    
    NSString *dir = [localPath substringToIndex:[localPath rangeOfString:@"/" options:NSBackwardsSearch].location];
    [FileUtil ensureDir:dir];
    
    [[NSFileManager defaultManager] moveItemAtPath:temp toPath:[FileUtil fullPath:localPath] error:nil];
    
    complete();
    
    self.req = nil;
}

- (void)downloadConcat:(NSString *)remotePath localPaths:(NSArray *)localPaths progress:(void (^)(int))progress complete:(void (^)(void))complete {
    NSURL *url = [NSURL URLWithString:remotePath];
    
    NSString* temp = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"temp%f", [NSDate timeIntervalSinceReferenceDate]]];
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    self.req = request;
    
    request.downloadDestinationPath = temp;
    
    request.failedBlock = ^{
        NSLog(@"Request Failed: url: %@, %@", remotePath, request.error.localizedDescription);
    };
    
    
    [request startSynchronous];
    
    // TODO very simple implementation. need to modify (to use ASIHTTPRequest#didDataReceived or something like) if performance problem occurs.

    int offset = 0;
    NSData* data = [NSData dataWithContentsOfFile:temp];
    
    for (int index = 0; index < localPaths.count; index++) {
        NSString* localPath = AT(localPaths, index);
        
        int length = OSReadBigInt64(data.bytes, offset);
        offset += 8;
        
        NSString* part = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"part%f", [NSDate timeIntervalSinceReferenceDate]]];
        
        [[data subdataWithRange:NSMakeRange(offset, length)] writeToFile:part atomically:YES];
        offset += length;

        NSString *dir = [localPath substringToIndex:[localPath rangeOfString:@"/" options:NSBackwardsSearch].location];
        [FileUtil ensureDir:dir];

        [[NSFileManager defaultManager] moveItemAtPath:part toPath:[FileUtil fullPath:localPath] error:nil];
        
        progress(index);
    }
    
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
            [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
            
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
    
    NSMutableString *remotePath = [NSMutableString stringWithFormat:@"%@?names=", [RemotePathUtil imageDir:self.item.endpoint]];
    NSMutableArray *localPaths = [NSMutableArray array];
    
    BOOL first = YES;
    
    for (NSNumber *pos in required) {
        if (first) {
            first = NO;
        } else {
            [remotePath appendString:@","];
        }

        [remotePath appendString:[LocalPathUtil imageThumbnailName:pos.intValue]];
        [localPaths addObject:[LocalPathUtil imageThumbnailPath:self.item.docId page:pos.intValue]];
    }
    
    [self downloadConcat:remotePath localPaths:localPaths progress:^(int index){
        if (self.shouldStop) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        
        [self proceedSequence];
    } complete:^{
    }];
}

- (void)ensureImageThumbnailEach:(int)page {
    if ([FileUtil exists:[LocalPathUtil imageThumbnailPath:self.item.docId page:page]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        
        [self proceedSequence];
        return;
    }
    
    [self download:[RemotePathUtil imageThumbnailPath:self.item.endpoint page:page] localPath:[LocalPathUtil imageThumbnailPath:self.item.docId page:page] complete:^{
        if (self.shouldStop) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        
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
                [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
                
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
    
    NSMutableString *remotePath = [NSMutableString stringWithFormat:@"%@?names=", [RemotePathUtil imageDir:self.item.endpoint]];
    NSMutableArray *localPaths = [NSMutableArray array];
    
    BOOL first = YES;
    
    for (TexturePosition *pos in required) {
        if (first) {
            first = NO;
        } else {
            [remotePath appendString:@","];
        }
        
        [remotePath appendString:[LocalPathUtil imageTextureName:page level:pos.level px:pos.px py:pos.py isWebp:image.isWebp]];
        [localPaths addObject:[LocalPathUtil imageTexturePath:self.item.docId page:page level:pos.level px:pos.px py:pos.py isWebp:image.isWebp]];
    }
    
    [self downloadConcat:remotePath localPaths:localPaths progress:^(int index){
        if (self.shouldStop) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        
        TexturePosition* tp = AT(required, index);
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_TEXTURE_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_I(page), @"page", NUM_I(tp.level), @"level", NUM_I(tp.px), @"px", NUM_I(tp.py), @"py", nil]];
        
        [self proceedSequence];
    } complete:^{
    }];
}

- (void)ensureImageTexturePerTexture:(int)page level:(int)level px:(int)px py:(int)py {
    if ([FileUtil exists:[LocalPathUtil imageTexturePath:self.item.docId page:page level:level px:px py:py isWebp:NO]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        
        [self proceedSequence];
        return;
    }
    
    [self download:[RemotePathUtil imageTexturePath:self.item.endpoint page:page level:level px:px py:py isWebp:NO] localPath:[LocalPathUtil imageTexturePath:self.item.docId page:page level:level px:px py:py isWebp:NO] complete:^{
              if (self.shouldStop) {
                  return;
              }
              
              [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
              [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_TEXTURE_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_I(page), @"page", NUM_I(level), @"level", NUM_I(px), @"px", NUM_I(py), @"py", nil]];
              
              [self proceedSequence];
          }
     ];
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

- (void)ensureImageInfo {
    if ([FileUtil exists:[LocalPathUtil imageInfoPath:self.item.docId]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        
        [self proceedSequence];
        return;
    }
    
    [self download:[RemotePathUtil imageInfoPath:self.item.endpoint] localPath:[LocalPathUtil imageInfoPath:self.item.docId] complete:^{
        if (self.shouldStop) {
            return;
        }
        
        [LocalProviderUtil setImageInitDownloaded:self.item.docId];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_IMAGE_INIT_DOWNLOADED object:self.item.docId];
        
        [self proceedSequence];
    }];
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
    
    if ([FileUtil exists:[LocalPathUtil infoPath:self.item.docId]]){
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        
        [self checkInfo];
        return;
    }
    
    [self download:[RemotePathUtil infoPath:self.item.endpoint] localPath:[LocalPathUtil infoPath:self.item.docId] complete:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DOWNLOADER_PROGRESS object:self.item.docId userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NUM_F(self.calcProgress), @"progress", nil]];
        
        [self checkInfo];
    }];
}

- (NSInvocation *)cleanupInvocation {
    SEL sel = @selector(cleanup);
    
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:sel]];
    [inv setTarget:self];
    [inv setSelector:sel];
    
    return inv;
}

- (NSInvocation *)ensureImageThumbnailInvocation:(int)page {
    SEL sel = @selector(ensureImageThumbnail:);
    
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:sel]];
    [inv setTarget:self];
    [inv setSelector:sel];
    [inv setArgument:&page atIndex:2];
    
    return inv;
}

- (NSInvocation *)ensureImageTextureInvocation:(int)page level:(int)level px:(int)px py:(int)py {
    SEL sel = @selector(ensureImageTexture:level:px:py:);
    
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:sel]];
    [inv setTarget:self];
    [inv setSelector:sel];
    [inv setArgument:&page atIndex:2];
    [inv setArgument:&level atIndex:3];
    [inv setArgument:&px atIndex:4];
    [inv setArgument:&py atIndex:5];
    
    return inv;
}

- (NSInvocation *)ensureInfoInvocation {
    SEL sel = @selector(ensureInfo);
    
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:sel]];
    [inv setTarget:self];
    [inv setSelector:sel];
    
    return inv;
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
        
        return 1.0 * value / (perPage * doc.pages + doc.pages);
    }
    
    assert(0);
}

- (NSInvocation *)toImageInvocation:(int)value doc:(DocInfo *)doc {
    ImageInfo* image = [LocalProviderUtil imageInfo:self.item.docId];
    
    int minLevel = [ImageLevelUtil minLevel:image.maxLevel];
    int maxLevel = [ImageLevelUtil maxLevel:minLevel imageMaxLevel:image.maxLevel imageMaxNumberOfLevel:image.maxNumberOfLevel];
    
    int perPage = [self calcPerPage:image minLevel:minLevel maxLevel:maxLevel];
    
    if (value < doc.pages * perPage) {
        int page = value / perPage;
        value %= perPage;
        
        for (int level = minLevel; level <= maxLevel; level++) {
            int nx;
            int ny;
            
            [self calcNxNy:image level:level minLevel:minLevel nxRef:&nx nyRef:&ny];
            
            if (value < nx * ny) {
                int px = value / ny;
                int py = value % ny;
                
                return [self ensureImageTextureInvocation:page level:level px:px py:py];
            }
            
            value -= nx * ny;
        }
    }
    
    value -= doc.pages * perPage;
    
    if (value < doc.pages) {
        return [self ensureImageThumbnailInvocation:value];
    }
    
    value -= doc.pages;
    
    if (value < 1) {
        NSLog(@"invoke cleanup");
        return [self cleanupInvocation];
    }
    
    NSLog(@"assert: docId: %@, value: %d", self.item.docId, value);
    assert(0);
}

- (NSInvocation *)toInvocation {
    int value = self.item.sequence;
    
    if (value < 1) {
        return [self ensureInfoInvocation];
    }
    
    value -= 1;
    
    DocInfo *doc = [LocalProviderUtil info:self.item.docId];
    
    if (AT_AS(doc.types, 0, NSNumber).intValue == ProviderDocumentTypeImage) {
        return [self toImageInvocation:value doc:doc];
    }
    
    assert(0);
}

- (void)doInvocation {
    self.working = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.shouldStop) {
            self.working = NO;
            return;
        }
        
        // REFACTOR no need to use NSInvocation now
        [self.toInvocation invoke];
        self.working = NO;
    });
}

#pragma mark public

+ (DownloaderState *)stateWithItem:(DownloaderItem *)item lock:(NSLock *)lock {
    return [[[DownloaderState alloc] initWithItem:item lock:lock] autorelease];
}

- (void)invoke {
    if (!self.working) {
        [self doInvocation];
    }
}

- (BOOL)didFinished {
    return !self.running;
}

- (void)stop {
    NSLog(@"stop");
    self.shouldStop = YES;
    [self.req clearDelegatesAndCancel];
}
    
@end
