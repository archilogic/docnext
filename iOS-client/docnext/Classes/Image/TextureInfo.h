//
//  TextureInfo.h
//  docnext
//
//  Created by  on 11/10/03.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface TextureInfo : NSObject

@property(nonatomic) GLuint texId;
@property(nonatomic) CGSize size;

+ (TextureInfo *)infoWithSize:(CGSize)size;
+ (TextureInfo *)infoWithColor:(float)r g:(float)g b:(float)b alpha:(float)alpha;
+ (TextureInfo *)infoWithTiledImage:(UIImage *)image size:(CGSize)size;
- (void)bindTexture:(GLubyte *)data imageSize:(CGSize)imageSize use565:(BOOL)use565;
- (void)resetTexture;

@end
