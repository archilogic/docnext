//
//  LoaderViewController.h
//  docnext
//
//  Created by  on 11/11/07.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloaderTypes.h"

@interface LoaderViewController : UIViewController

@property(nonatomic, retain) NSString* docId;
@property(nonatomic) DownloaderPermitType permitType;
@property(nonatomic) DownloaderSaveLimit saveLimit;
@property(nonatomic, retain) NSString* endpoint;
@property(nonatomic) DownloaderInsertPosition insertPosition;

- (IBAction)backClick;

@end
