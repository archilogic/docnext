//
//  TextBookmarkViewController.h
//  docnext
//
//  Created by 野口 優 on 11/11/08.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PageView.h"

@interface BookmarkTextViewController : UIViewController

@property(nonatomic, retain) IBOutlet UITableView* tableView;
@property(nonatomic, retain) IBOutlet UIView* brightnessView;
@property(nonatomic, retain) NSString* docId;
@property(nonatomic, retain) NSString* drmKey;
@property(nonatomic) int page;
@property(nonatomic, assign) PageView* parent;

- (IBAction)backButtonClick;
- (IBAction)addButtonClick;

@end
