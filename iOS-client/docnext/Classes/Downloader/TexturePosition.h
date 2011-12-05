//
//  TexturePosition.h
//  docnext
//
//  Created by  on 11/10/28.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TexturePosition : NSObject

@property(nonatomic) int level;
@property(nonatomic) int px;
@property(nonatomic) int py;

+ (TexturePosition *)positionWithParmas:(int)level px:(int)px py:(int)py;

@end
