//
//  RootViewController.h
//  docnext
//
//  Created by  on 11/09/14.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, retain) IBOutlet UITableView* tableView;

- (IBAction)clearButtonClick:(id)sender;

@end
