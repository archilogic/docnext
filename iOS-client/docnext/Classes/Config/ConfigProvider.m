//
//  ConfigProvider.m
//  docnext
//
//  Created by  on 11/11/04.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import "ConfigProvider.h"
#import "Utilities.h"

#define KEY_BRIGHTNESS @"brightness"
#define KEY_ORIENTATION @"orientation"
#define KEY_READING_DIRECTION @"reading_direction"

@implementation ConfigProvider

+ (float)floatValue:(NSString *)key defaultValue:(float)defaultValue {
    NSNumber* val = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if (val == nil) {
        return defaultValue;
    }
    
    return val.floatValue;
}

+ (int)intValue:(NSString *)key defaultValue:(int)defaultValue {
    NSNumber* val = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if (val == nil) {
        return defaultValue;
    }
    
    return val.intValue;
}

+ (float)boolValue:(NSString *)key defaultValue:(BOOL)defaultValue {
    NSNumber* val = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if (val == nil) {
        return defaultValue;
    }
    
    return val.boolValue;
}

#pragma mark public

+ (float)brightness {
    return [self floatValue:KEY_BRIGHTNESS defaultValue:1.0];
}

+ (void)setBrightness:(float)value {
    [[NSUserDefaults standardUserDefaults] setObject:NUM_F(value) forKey:KEY_BRIGHTNESS];
}

+ (ConfigProviderOrientation)orientation {
    return [self intValue:KEY_ORIENTATION defaultValue:ConfigProviderOrientationFree];
}

+ (void)setOrientation:(ConfigProviderOrientation)value {
    [[NSUserDefaults standardUserDefaults] setObject:NUM_I(value) forKey:KEY_ORIENTATION];
}

+ (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    ConfigProviderOrientation o = [self orientation];
    
    if (o == ConfigProviderOrientationFree) {
        return YES;
    } else {
        if (interfaceOrientation == UIInterfaceOrientationPortrait) {
            return o == ConfigProviderOrientationPortrait;
        }
        if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            return o == ConfigProviderOrientationPortraitUpsideDown;
        }
        if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            return o == ConfigProviderOrientationLandscapeLeft;
        }
        if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            return o == ConfigProviderOrientationLandscapeRight;
        }
        
        assert(0);
    }
}

+ (void)setOrientationByUIInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        [self setOrientation:ConfigProviderOrientationPortrait];
    }
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [self setOrientation:ConfigProviderOrientationPortraitUpsideDown];
    }
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        [self setOrientation:ConfigProviderOrientationLandscapeLeft];
    }
    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        [self setOrientation:ConfigProviderOrientationLandscapeRight];
    }
}

+ (void)setOrientationAsFree {
    [self setOrientation:ConfigProviderOrientationFree];
}

+ (ConfigProviderReadingDirection)readingDirection {
    return [self intValue:KEY_READING_DIRECTION defaultValue:ConfigProviderReadingDirectionHorizontal];
}

+ (void)setReadingDirection:(ConfigProviderReadingDirection)value {
    [[NSUserDefaults standardUserDefaults] setObject:NUM_I(value) forKey:KEY_READING_DIRECTION];
}

@end
