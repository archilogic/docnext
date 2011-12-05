//
//  TextBookmarkViewController.m
//  docnext
//
//  Created by 野口 優 on 11/11/08.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BookmarkTextViewController.h"
#import "LocalProviderUtil.h"
#import "PageTextNumberInfo.h"
#import "Utilities.h"
#import "PageTextNumberCell.h"
#import "ConfigProvider.h"
#import "BookmarkTextUtil.h"

@interface BookmarkTextViewController ()

@property(nonatomic, retain) NSMutableArray *bookmarks;

@end

@implementation BookmarkTextViewController

@synthesize tableView;
@synthesize brightnessView;
@synthesize docId;
@synthesize drmKey;
@synthesize page;
@synthesize parent;

@synthesize bookmarks;

#pragma mark private

- (void)loadBookmarks {
    self.bookmarks = [NSMutableArray arrayWithCapacity:0];
    
    for (NSNumber* pos in [LocalProviderUtil bookmark:self.docId]) {
        //NSString* text = [LocalProviderUtil tocText:docId page:page_.intValue drmKey:self.drmKey];
        [self.bookmarks addObject:[PageTextNumberInfo infoWithParam:[LocalProviderUtil resolvePositionToPage:[pos intValue]] text:@""]];
    }
}

- (void)applyBrightness {
    self.brightnessView.alpha = 1 - [ConfigProvider brightness];
}

- (void)onConfigChanged:(NSNotification *)notification {
    [self applyBrightness];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self applyBrightness];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConfigChanged:) name:CONFIG_CHANGED object:nil];
    
    self.tableView.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
    
    [self loadBookmarks];
    
    [self.tableView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CONFIG_CHANGED object:nil];
    
    self.tableView = nil;
    self.brightnessView = nil;
    self.docId = nil;
    self.drmKey = nil;
    self.parent = nil;
    
    self.bookmarks = nil;
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [ConfigProvider shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark public

- (IBAction)backButtonClick {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)addButtonClick {
    NSArray* old = [LocalProviderUtil bookmark:self.docId];
    NSNumber* pageObj = NUM_I([LocalProviderUtil resolvePageToPosition:self.page]);
    
    if ([old containsObject:pageObj]) {
        [[[[UIAlertView alloc] initWithTitle:@"This page is already bookmarked" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
        return;
    }
    
    NSMutableArray* newBookmarks = [NSMutableArray arrayWithArray:old];
    
    // bellow code for use [tableView insertRowsAtIndexPaths::]
    
    for (int index = 0; index < newBookmarks.count; index++) {
        if ([AT(newBookmarks, index) compare:pageObj] == NSOrderedDescending) {
            [newBookmarks insertObject:pageObj atIndex:index];
            [LocalProviderUtil setBookmark:self.docId bookmark:newBookmarks];
            
            [self loadBookmarks];
            
            NSIndexPath* ip = [NSIndexPath indexPathForRow:index inSection:0];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:YES];
            
            [self.parent bindMenuInfo];
            
            return;
        }
    }
    
    [newBookmarks addObject:pageObj];
    [LocalProviderUtil setBookmark:self.docId bookmark:newBookmarks];
    
    [self loadBookmarks];
    NSIndexPath* ip = [NSIndexPath indexPathForRow:self.bookmarks.count - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:YES];
    
    [self.parent bindMenuInfo];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bookmarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    PageTextNumberCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = (PageTextNumberCell *)[[[UIViewController alloc] initWithNibName:@"PageTextNumberCell" bundle:nil] autorelease].view;
    }
    
    PageTextNumberInfo* info = AT(self.bookmarks, indexPath.row);
    cell.textLabel.text = info.text;
    cell.pageLabel.text = [NSString stringWithFormat:@"%d", info.page + 1];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray* newBookmarks = [NSMutableArray arrayWithArray:[LocalProviderUtil bookmark:self.docId]];
        
        [newBookmarks removeObjectAtIndex:indexPath.row];
        
        [LocalProviderUtil setBookmark:self.docId bookmark:newBookmarks];
        
        [self loadBookmarks];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
        [self.parent bindMenuInfo];
    }   
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PageTextNumberInfo* info = AT(self.bookmarks, indexPath.row);
    [self.parent gotoPage:info.page animated:FALSE];
    [self dismissModalViewControllerAnimated:YES];
}

@end
