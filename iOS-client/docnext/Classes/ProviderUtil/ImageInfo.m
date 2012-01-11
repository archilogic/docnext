//
//  ImageInfo.m
//  docnext
//
//  Created by  on 11/09/28.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "ImageInfo.h"
#import "Utilities.h"
#import "OrientationUtil.h"
#import "DocInfo.h"

@implementation ImageInfo

@synthesize width;
@synthesize height;
@synthesize maxLevel;
@synthesize isUseActualSize;
@synthesize maxNumberOfLevel;
@synthesize isWebp;
@synthesize hasConcatFile;
@synthesize spreadOnlyPages;
@synthesize hasAnnotation;

//@return list.get( portrait-page ) == spread-page
- (NSArray *)portraitPageToSpreadPage:(DocInfo *)doc {
    NSMutableArray* ret = [NSMutableArray arrayWithCapacity:doc.pages];
    
    for (int sPage = 0; sPage < doc.pages + self.spreadOnlyPages.count; sPage++) {
        if ( ![spreadOnlyPages containsObject:NUM_I(sPage)] ) {
            [ret addObject:NUM_I(sPage)];
        }
    }
    
    return ret;
}

- (NSArray *)simple:(int)pages {
    NSMutableArray* ret = [NSMutableArray arrayWithCapacity:pages];
    
    for (int page = 0; page < pages; page++) {
        [ret addObject:NUM_I(page)];
    }
    
    return ret;
}

// @return list.get( spread-page ) == portrait-page (null if not exists)
- (NSArray *)spreadPageToPortraitPage:(DocInfo *)doc {
    NSMutableArray* ret = [NSMutableArray arrayWithCapacity:doc.pages + self.spreadOnlyPages.count];
    
    for (int sPage = 0, pPage = 0; sPage < doc.pages + spreadOnlyPages.count; sPage++) {
        [ret addObject:[spreadOnlyPages containsObject:NUM_I(sPage)] ? [NSNull null] : NUM_I(pPage++)];
    }
    
    return ret;
}

// @return list.get( spread-page ) == portrait-page (or smaller neighbor)
- (NSArray *)spreadPageToPortraitPageNullSafe:(DocInfo *)doc {
    NSMutableArray* ret = [NSMutableArray arrayWithArray:[self spreadPageToPortraitPage:doc]];
    
    NSNumber* prev = NUM_I(-1);
    for (int index = 0; index < ret.count; index++) {
        if (AT(ret, index) != [NSNull null]) {
            prev = AT(ret, index);
        } else {
            [ret replaceObjectAtIndex:index withObject:prev];
        }
    }
    
    return ret;
}

#pragma mark public

+ (ImageInfo *)infoWithDictionary:(NSDictionary *)dict {
    ImageInfo* ret = [[[ImageInfo alloc] init] autorelease];
    
    ret.width = FOR_I(dict, @"width");
    ret.height = FOR_I(dict, @"height");
    ret.maxLevel = FOR_I(dict, @"maxLevel");
    ret.isUseActualSize = FOR_B(dict, @"isUseActualSize");
    ret.maxNumberOfLevel = FOR_I(dict, @"maxNumberOfLevel");
    ret.isWebp = FOR_B(dict, @"isWebp");
    ret.hasConcatFile = FOR_B(dict, @"hasConcatFile");
    ret.spreadOnlyPages = FOR(dict, @"spreadOnlyPages");
    
    if (!ret.spreadOnlyPages) {
        ret.spreadOnlyPages = [NSArray array];
    }
    
    ret.hasAnnotation = FOR_B(dict, @"hasAnnotation");
    
    return ret;
}

- (NSArray *)fromSpreadPage:(DocInfo *)doc {
    return [OrientationUtil isSpreadMode] ? [self simple:doc.pages + self.spreadOnlyPages.count] : [self spreadPageToPortraitPageNullSafe:doc];
}

- (NSArray *)toPortraitPage:(DocInfo *)doc {
    return [OrientationUtil isSpreadMode] ? [self spreadPageToPortraitPage:doc] : [self simple:doc.pages];
}

- (NSArray *)toSpreadPage:(DocInfo *)doc {
    return [OrientationUtil isSpreadMode] ? [self simple:doc.pages + self.spreadOnlyPages.count] : [self portraitPageToSpreadPage:doc];
}

@end
