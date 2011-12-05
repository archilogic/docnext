//
//  PageInfo.m
//  docnext
//
//  Created by  on 11/10/03.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "PageInfo.h"
#import "ImageLevelUtil.h"
#import "TextureInfo.h"
#import "Utilities.h"

@implementation PageInfo

@synthesize textures;
@synthesize statuses;

- (id)initWithParam:(int)minLevel maxLevel:(int)maxLevel page:(CGSize)page image:(ImageInfo *)image {
    self = [super init];
    
    if (self) {
        NSMutableArray* texs = [NSMutableArray arrayWithCapacity:maxLevel - minLevel + 1];
        NSMutableArray* stas = [NSMutableArray arrayWithCapacity:maxLevel - minLevel + 1];
        
        for (int level = minLevel; level <= maxLevel - ( maxLevel == image.maxLevel && image.isUseActualSize ? 1 : 0 ); level++) {
            int factor = pow(2, level - minLevel);
            int nx = (page.width * factor - 1) / TEXTURE_SIZE + 1;
            int ny = (page.height * factor - 1) / TEXTURE_SIZE + 1;

            NSMutableArray* ltexs = [NSMutableArray arrayWithCapacity:ny];
            NSMutableArray* lstas = [NSMutableArray arrayWithCapacity:ny];
            
            for (int py = 0; py < ny; py++) {
                NSMutableArray* ytexs = [NSMutableArray arrayWithCapacity:nx];
                NSMutableArray* ystas = [NSMutableArray arrayWithCapacity:nx];
                
                for (int px = 0; px < nx; px++) {
                    int x = px * TEXTURE_SIZE;
                    int y = py * TEXTURE_SIZE;
                    
                    [ytexs addObject:[TextureInfo infoWithSize:CGSizeMake(MIN(page.width * factor - x, TEXTURE_SIZE), MIN(page.height * factor - y, TEXTURE_SIZE))]];
                    [ystas addObject:NUM_B(NO)];
                }
                
                [ltexs addObject:ytexs];
                [lstas addObject:ystas];
            }
            
            [texs addObject:ltexs];
            [stas addObject:lstas];
        }
        
        if (maxLevel == image.maxLevel && image.isUseActualSize) {
            int nx = (image.width - 1) / TEXTURE_SIZE + 1;
            int ny = (image.height - 1) / TEXTURE_SIZE + 1;
            
            NSMutableArray* ltexs = [NSMutableArray arrayWithCapacity:ny];
            NSMutableArray* lstas = [NSMutableArray arrayWithCapacity:ny];
            
            for (int py = 0; py < ny; py++) {
                NSMutableArray* ytexs = [NSMutableArray arrayWithCapacity:nx];
                NSMutableArray* ystas = [NSMutableArray arrayWithCapacity:nx];
                
                for ( int px = 0; px < nx; px++) {
                    int x = px * TEXTURE_SIZE;
                    int y = py * TEXTURE_SIZE;
                    
                    [ytexs addObject:[TextureInfo infoWithSize:CGSizeMake(MIN(image.width - x, TEXTURE_SIZE), MIN(image.height - y, TEXTURE_SIZE))]];
                    [ystas addObject:NUM_B(NO)];
                }
                
                [ltexs addObject:ytexs];
                [lstas addObject:ystas];
            }
            
            [texs addObject:ltexs];
            [stas addObject:lstas];
        }
        
        self.textures = texs;
        self.statuses = stas;
    }
    
    return self;
}

+ (PageInfo *)infoWithParam:(int)minLevel maxLevel:(int)maxLevel page:(CGSize)page image:(ImageInfo *)image {
    return [[[PageInfo alloc] initWithParam:minLevel maxLevel:maxLevel page:page image:image] autorelease];
}

@end
