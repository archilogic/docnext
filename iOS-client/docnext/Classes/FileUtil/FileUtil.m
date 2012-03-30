//
//  FileUtil.m
//  docnext
//
//  Created by  on 11/09/14.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "FileUtil.h"

@implementation FileUtil

#pragma mark private

#pragma mark public

+ (NSString *)fullPath:(NSString *)path {
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    if (!dir) {
        [NSException raise:FileUtilExceptionNotFound format:@"DocumentDirectory not found"];
        return nil;
    }
    
    return [dir stringByAppendingPathComponent:path];
}

+ (NSString *)tempPath:(NSString *)path {
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    if (!dir) {
        [NSException raise:FileUtilExceptionNotFound format:@"CachesDirectory not found"];
        return nil;
    }
    
    return [dir stringByAppendingPathComponent:path];
}

+ (void)ensureDir:(NSString *)path {
    NSError* err = nil;
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[self fullPath:path] withIntermediateDirectories:YES attributes:nil error:&err];
    if (err) {
        NSLog(@"Error: %@", err);
        assert(0);
    }
}

+ (BOOL)exists:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self fullPath:path]];
}

+ (void)touch:(NSString *)path {
    [[NSFileManager defaultManager] createFileAtPath:[self fullPath:path] contents:nil attributes:nil];
}

@end
