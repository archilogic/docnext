//
//  FileUtil.h
//  docnext
//
//  Created by  on 11/09/14.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FileUtilExceptionNotFound @"NotFound"

@interface FileUtil : NSObject

+ (NSString *)fullPath:(NSString *)path;
+ (NSString *)tempPath:(NSString *)path;
+ (void)ensureDir:(NSString *)path;
+ (BOOL)exists:(NSString *)path;
+ (void)touch:(NSString *)path;

@end
