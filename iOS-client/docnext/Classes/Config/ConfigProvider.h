//
//  ConfigProvider.h
//  docnext
//
//  Created by  on 11/11/04.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigProviderTypes.h"

#define CONFIG_CHANGED @"docnext_config_changed"

@interface ConfigProvider : NSObject

+ (float)brightness;
+ (void)setBrightness:(float)value;
+ (ConfigProviderOrientation)orientation;
+ (void)setOrientation:(ConfigProviderOrientation)value;
+ (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
+ (void)setOrientationByUIInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
+ (void)setOrientationAsFree;
+ (ConfigProviderReadingDirection)readingDirection;
+ (void)setReadingDirection:(ConfigProviderReadingDirection)value;

@end
