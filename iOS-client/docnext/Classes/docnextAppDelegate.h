//
//  docnextAppDelegate.h
//  docnext
//
//  Created by  on 11/09/14.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface docnextAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property(nonatomic, retain) IBOutlet UINavigationController* navController;

@end
