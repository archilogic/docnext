//
//  TextureInfo.m
//  docnext
//
//  Created by  on 11/10/03.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "TextureInfo.h"
#import "Utilities.h"
#import "BitmapConverter.h"

@implementation TextureInfo

@synthesize texId;
@synthesize size;

#pragma mark private

+ (int)textureSize:(CGSize)size {
    int value = MAX(size.width, size.height);
    
    for (int size = 1; ; size <<= 1) {
        if (size >= value) {
            return size;
        }
    }
}

- (void)genTexture {
    GLuint texture;
    
    glGenTextures(1, &texture);
    
    self.texId = texture;
}

- (void)delTexture {
    GLuint texture = self.texId;
    
    glDeleteTextures(1, &texture);
    
    self.texId = 0;
}

- (id)initWithSize:(CGSize)p_size {
    self = [super init];
    
    if (self) {
        self.size = p_size;
        [self genTexture];
    }
    
    return self;
}

- (id)initWithData:(CGSize)p_size data:(GLubyte *)data imageSize:(CGSize)imageSize {
    self = [self initWithSize:p_size];
    
    if (self) {
        [self bindTexture:data imageSize:imageSize];
    }
    
    return self;
}

#pragma mark public

+ (TextureInfo *)infoWithSize:(CGSize)size {
    return [[[TextureInfo alloc] initWithSize:size] autorelease];
}

+ (TextureInfo *)infoWithColor:(float)r g:(float)g b:(float)b alpha:(float)alpha {
    CGSize size = CGSizeMake(1, 1);
    
    GLubyte* data = (GLubyte *)malloc(size.width * size.height * 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(data, size.width, size.height, 8, size.width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);

    CGContextSetRGBFillColor(ctx, r, g, b, alpha);
    CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));

    CGContextRelease(ctx);
    
    TextureInfo* info = [[[TextureInfo alloc] initWithData:size data:data imageSize:size] autorelease];
    
    free(data);
    
    return info;
}

+ (TextureInfo *)infoWithTiledImage:(UIImage *)image size:(CGSize)size {
    int len = [self textureSize:size];
    
    CGSize imageSize = CGSizeMake(len, len);
    
    GLubyte* data = (GLubyte *)malloc(imageSize.width * imageSize.height * 4);
    bzero(data, imageSize.width * imageSize.height * 4);
    
    CGImageRef imageRef = image.CGImage;

    CGContextRef ctx = CGBitmapContextCreate(data, imageSize.width, imageSize.height, 8, imageSize.width * 4, CGImageGetColorSpace(imageRef), kCGImageAlphaPremultipliedLast);
    
    for (int y = 0; y * image.size.height < imageSize.height; y++) {
        for (int x = 0; x * image.size.width < imageSize.width; x++) {
            CGContextDrawImage(ctx, CGRectMake(x * image.size.width, y * image.size.height, image.size.width, image.size.height), imageRef);
        }
    }
    
    CGContextRelease(ctx);

#ifdef USE565
    GLubyte* rgb = malloc(imageSize.width * imageSize.height * 2);
    bzero(rgb, imageSize.width * imageSize.height * 2);
    
    [BitmapConverter fromRGBA8888toRGB656:data to:rgb size:imageSize.width * imageSize.height];
    
    free(data);
    
    TextureInfo* info = [[[TextureInfo alloc] initWithData:size data:rgb imageSize:imageSize] autorelease];
    
    free(rgb);
#else
    TextureInfo* info = [[[TextureInfo alloc] initWithData:size data:data imageSize:imageSize lock:lock] autorelease];
    
    free(data);
#endif
    
    return info;
}

// Crop is keeping left and top edge
- (void)bindTexture:(GLubyte *)data imageSize:(CGSize)imageSize {
	glBindTexture(GL_TEXTURE_2D, self.texId);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
#ifdef USE565
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, imageSize.width, imageSize.height, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, data);
#else
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageSize.width, imageSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
#endif
    
    GLint rect[] = {0, self.size.height, self.size.width, -self.size.height};
    glTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_CROP_RECT_OES, rect);
}

- (void)resetTexture {
    [self delTexture];
    [self genTexture];
}

@end
