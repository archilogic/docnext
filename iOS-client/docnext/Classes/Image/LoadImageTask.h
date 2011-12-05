//
//  LoadImageTask.h
//  docnext
//
//  Created by  on 11/10/06.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageState.h"
#import "ImageViewController.h"

@interface LoadImageTask : NSOperation

@property(nonatomic) int page;
@property(nonatomic) int level;
@property(atomic) BOOL abort;

+ (LoadImageTask *)taskWithParam:(NSString *)docId page:(int)page level:(int)level px:(int)px py:(int)py isWebp:(BOOL)isWebp pageHolder:(id<PageHolder>)pageHolder binder:(id<TextureBinder>)binder threshold:(int)threshold;

@end
