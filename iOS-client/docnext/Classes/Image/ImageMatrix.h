//
//  ImageMatrix.h
//  docnext
//
//  Created by  on 11/10/04.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageMatrix : NSObject

@property(nonatomic) float scale;
@property(nonatomic) float tx;
@property(nonatomic) float ty;

- (ImageMatrix *)adjust:(CGSize)surface page:(CGSize)page nx:(int)nx ny:(int)ny;
- (ImageMatrix *)interpolate:(float)value src:(ImageMatrix *)src dst:(ImageMatrix *)dst;
- (BOOL)isInPage:(CGSize)surface page:(CGSize)page nx:(int)nx ny:(int)ny;
- (float)length:(float)length;
- (float)x:(float)x;
- (float)y:(float)y;
- (ImageMatrix *)set:(ImageMatrix *)that;
- (ImageMatrix *)set:(float)p_scale tx:(float)p_tx ty:(float)p_ty;

@end
