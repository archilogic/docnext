//
//  RootViewController.m
//  docnext
//
//  Created by  on 11/09/14.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "RootViewController.h"

#import "FileUtil.h"
#import "Downloader.h"
#import "LocalPathUtil.h"
#import "LoaderViewController.h"
#import "LocalProviderUtil.h"
#import "Utilities.h"
#import "NSObject+SBJson.h"

@interface RootViewController ()

@property(nonatomic, retain) NSArray* demos;

@end

@implementation RootViewController

@synthesize tableView;

@synthesize demos;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.demos = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"demo" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] JSONValue];
    
    [self.tableView reloadData];
}

- (void)dealloc {
    self.tableView = nil;
    self.demos = nil;
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)launch:(NSString *)docId endpiont:(NSString *)endpoint permitType:(DownloaderPermitType)permitType saveLimit:(DownloaderSaveLimit)saveLimit title:(NSString *)title {
    if (![LocalProviderUtil isCompleted:docId] && ![[[Downloader instance] list] containsObject:docId] && ![LocalProviderUtil isImageInitDownloaded:docId]) {
        [[Downloader instance] addItem:docId
                            permitType:permitType
                             saveLimit:saveLimit
                              endpoint:endpoint
                        insertPosition:DownloaderInsertPositionTail
                                 title:title];
    }

    LoaderViewController* vc = [[[LoaderViewController alloc] init] autorelease];
    
    vc.docId = docId;
    vc.endpoint = endpoint;
    vc.permitType = permitType;
    vc.saveLimit = saveLimit;
    vc.insertPosition = DownloaderInsertPositionTail;
    
    // setStatusBarHidden in ImageViewController seems not to work correctly...
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController pushViewController:vc animated:NO];
}

- (IBAction)clearButtonClick:(id)sender {
    [[NSFileManager defaultManager] removeItemAtPath:[FileUtil fullPath:@"/docs"] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[FileUtil fullPath:[LocalPathUtil downloaderInfoPath]] error:nil];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return demos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary* demo = [self.demos objectAtIndex:indexPath.row];
    cell.textLabel.text = [demo objectForKey:@"name"];
    
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* demo = [self.demos objectAtIndex:indexPath.row];

    NSString* docId = [demo objectForKey:@"permitId"];
    NSString* endpoint = [demo objectForKey:@"endpoint"];
    DownloaderPermitType permitType = [[demo objectForKey:@"permitType"] isEqualToString:@"1"] ? DownloaderPermitTypeFull : DownloaderPermitTypeSample;
    DownloaderSaveLimit saveLimit = [[demo objectForKey:@"saveLimit"] isEqualToString:@"1"] ? DownloaderSaveLimitCanSave : DownloaderSaveLimitCannotSave;
    NSString *title = [demo objectForKey:@"name"];
    
    [self launch:docId endpiont:endpoint permitType:permitType saveLimit:saveLimit title:title];
}

@end
