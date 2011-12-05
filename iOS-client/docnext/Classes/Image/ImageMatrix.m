//
//  ImageMatrix.m
//  docnext
//
//  Created by  on 11/10/04.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "ImageMatrix.h"

@implementation ImageMatrix

@synthesize scale;
@synthesize tx;
@synthesize ty;

#pragma mark private

- (float)i:(float)value src:(float)src dst:(float)dst {
    return src + (dst - src) * value;
}

#pragma mark public

- (ImageMatrix *)adjust:(CGSize)surface page:(CGSize)page nx:(int)nx ny:(int)ny {
    self.tx = MIN(MAX(self.tx, surface.width - page.width * scale * nx), 0);
    self.ty = MIN(MAX(self.ty, surface.height - page.height * scale * ny), 0);
    
    return self;
}

- (ImageMatrix *)interpolate:(float)value src:(ImageMatrix *)src dst:(ImageMatrix *)dst {
    self.scale = [self i:value src:src.scale dst:dst.scale];
    self.tx = [self i:value src:src.tx dst:dst.tx];
    self.ty = [self i:value src:src.ty dst:dst.ty];
    
    return self;
}

- (BOOL)isInPage:(CGSize)surface page:(CGSize)page nx:(int)nx ny:(int)ny {
    const int EPS = surface.width / 20;
    
    return self.tx <= EPS && self.tx + EPS >= surface.width - page.width * self.scale * nx && self.ty <= EPS && self.ty + EPS >= surface.height - page.height * self.scale * ny;
}

- (float)length:(float)length {
    return length * self.scale;
}

- (float)x:(float)x {
    return x * self.scale + self.tx;
}

- (float)y:(float)y {
    return y * self.scale + self.ty;
}

- (ImageMatrix *)set:(ImageMatrix *)that {
    self.scale = that.scale;
    self.tx = that.tx;
    self.ty = that.ty;
    
    return self;
}

- (ImageMatrix *)set:(float)p_scale tx:(float)p_tx ty:(float)p_ty {
    self.scale = p_scale;
    self.tx = p_tx;
    self.ty = p_ty;
    
    return self;
}

@end
