//
//  LoaderViewController.m
//  docnext
//
//  Created by  on 11/11/07.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "LoaderViewController.h"
#import "FileUtil.h"
#import "LocalPathUtil.h"
#import "DocInfo.h"
#import "LocalProviderUtil.h"
#import "Utilities.h"
#import "Downloader.h"
#import "ConfigProvider.h"
#import "ImageViewController.h"
#import "DebugLog.h"

@interface LoaderViewController ()

@property(nonatomic) BOOL initialized;

@end

@implementation LoaderViewController

@synthesize docId;
@synthesize permitType;
@synthesize saveLimit;
@synthesize endpoint;
@synthesize insertPosition;

@synthesize initialized;

- (void)showImage {
#ifdef DebugLogLevelDebug
    NSLog(@"showImage begin");
#endif
    ImageViewController* vc = [[[ImageViewController alloc] init] autorelease];
    [vc setParams:self.docId permitType:self.permitType];
    
    UINavigationController* nav = self.navigationController;
    [nav popViewControllerAnimated:NO];
    [nav pushViewController:vc animated:NO];
#ifdef DebugLogLevelDebug
    NSLog(@"showImage end");
#endif
}

- (void)checkDocInfo {
    DocInfo* info = [LocalProviderUtil info:self.docId];
    
    if (AT_AS(info.types, 0, NSNumber).intValue == ProviderDocumentTypeImage) {
        if ([LocalProviderUtil isImageInitDownloaded:self.docId]) {
            [self showImage];
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDownloaderImageInitDownloaded:) name:DOWNLOADER_IMAGE_INIT_DOWNLOADED object:nil];
        }
    } else {
        assert(0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.initialized = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.initialized) {
        self.initialized = YES;
        
        NSArray* downloading = [[Downloader instance] list];
        
        if ([downloading containsObject:self.docId] && ![[downloading objectAtIndex:0] isEqualToString:self.docId]) {
            NSMutableArray* modified = [NSMutableArray arrayWithArray:downloading];
            [modified removeObject:self.docId];
            [modified insertObject:self.docId atIndex:0];
            
            [[Downloader instance] sort:modified];
        }
        
        if([FileUtil exists:[LocalPathUtil infoPath:self.docId]]){
            [self checkDocInfo];
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDownloaderProgress:) name:DOWNLOADER_PROGRESS object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDownloaderFailed:) name:DOWNLOADER_FAILED object:nil];
        }
    }
}

- (void)dealloc {
    self.docId = nil;
    self.endpoint = nil;
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [ConfigProvider shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (IBAction)backClick {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Downloader Notification

- (void)onDownloaderProgress:(NSNotification *)notification {
    if ([self.docId compare:notification.object] != NSOrderedSame) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_FAILED object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkDocInfo];
    });
}

- (void)onDownloaderFailed:(NSNotification *)notification {
    if ([self.docId compare:notification.object] != NSOrderedSame) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_FAILED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_PROGRESS object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController* nav = self.navigationController;
        [nav popViewControllerAnimated:YES];
    });
}

- (void)onDownloaderComplete:(NSNotification *)notification {
    if ([self.docId compare:notification.object] != NSOrderedSame) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_COMPLETE object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkDocInfo];
    });
}

- (void)onDownloaderImageInitDownloaded:(NSNotification *)notification {
    if ([self.docId compare:notification.object] != NSOrderedSame) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_IMAGE_INIT_DOWNLOADED object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showImage];
    });
}

@end
