//
//  UnbindQueueItem.h
//  docnext
//
//  Created by  on 11/10/06.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UnbindQueueItem : NSObject

@property(nonatomic) int page;
@property(nonatomic) int level;
@property(nonatomic) int px;
@property(nonatomic) int py;

+ (UnbindQueueItem *)itemWithParam:(int)page level:(int)level px:(int)px py:(int)py;

@end
