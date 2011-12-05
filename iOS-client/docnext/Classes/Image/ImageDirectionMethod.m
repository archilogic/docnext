//
//  ImageDirectionMethod.m
//  docnext
//
//  Created by  on 11/10/05.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "ImageDirectionMethod.h"

#define PAGE_CHANGE_THREASHOLD 4

@implementation ImageDirectionMethod

+ (BOOL)canMoveHorizontal:(ImageDirection)dir {
    switch (dir) {
        case ImageDirectionL2R:
        case ImageDirectionR2L:
            return true;
        case ImageDirectionT2B:
        case ImageDirectionB2T:
            return false;
        default:
            assert(0);
    }
}

+ (BOOL)canMoveVertical:(ImageDirection)dir {
    return ![self canMoveHorizontal:dir];
}

+ (ImageCorner)getCorner:(ImageDirection)dir isNext:(BOOL)isNext {
    switch (dir) {
        case ImageDirectionL2R:
            return isNext ? ImageCornerTopLeft : ImageCornerBottomRight;
        case ImageDirectionR2L:
            return isNext ? ImageCornerTopRight : ImageCornerBottomLeft;
        case ImageDirectionT2B:
            return isNext ? ImageCornerTopLeft : ImageCornerBottomRight;
        case ImageDirectionB2T:
            return isNext ? ImageCornerTopRight : ImageCornerBottomLeft;
        default:
            assert(0);
    }
}

+ (BOOL)shouldChagneToNext:(ImageDirection)dir state:(ImageState *)state nPage:(int)nPage factor:(int)factor {
    switch (dir) {
        case ImageDirectionL2R:
            return state.matrix.tx < state.surfaceSize.width - state.surfaceSize.width / PAGE_CHANGE_THREASHOLD / factor - state.pageSize.width * state.matrix.scale * nPage - state.padding.width * 2;
        case ImageDirectionR2L:
            return state.matrix.tx > state.surfaceSize.width / PAGE_CHANGE_THREASHOLD / factor;
        case ImageDirectionT2B:
            return state.matrix.ty < state.surfaceSize.height - state.surfaceSize.height / PAGE_CHANGE_THREASHOLD / factor - state.pageSize.height * state.matrix.scale * nPage - state.padding.height * 2;
        case ImageDirectionB2T:
            return state.matrix.ty > state.surfaceSize.height / PAGE_CHANGE_THREASHOLD / factor;
        default:
            assert(0);
    }
}

+ (BOOL)shouldChangeToPrev:(ImageDirection)dir state:(ImageState *)state nPage:(int)nPage factor:(int)factor {
    switch (dir) {
        case ImageDirectionL2R:
            return state.matrix.tx > state.surfaceSize.width / PAGE_CHANGE_THREASHOLD / factor;
        case ImageDirectionR2L:
            return state.matrix.tx < state.surfaceSize.width - state.surfaceSize.width / PAGE_CHANGE_THREASHOLD / factor - state.pageSize.width * state.matrix.scale * nPage - state.padding.width * 2;
        case ImageDirectionT2B:
            return state.matrix.ty > state.surfaceSize.height / PAGE_CHANGE_THREASHOLD / factor;
        case ImageDirectionB2T:
            return state.matrix.ty < state.surfaceSize.height - state.surfaceSize.height / PAGE_CHANGE_THREASHOLD / factor - state.pageSize.height * state.matrix.scale * nPage - state.padding.height * 2;
        default:
            assert(0);
    }
}

+ (int)toXSign:(ImageDirection)dir {
    switch (dir) {
        case ImageDirectionL2R:
            return 1;
        case ImageDirectionR2L:
            return -1;
        case ImageDirectionT2B:
        case ImageDirectionB2T:
            return 0;
        default:
            assert(0);
    }
}

+ (int)toYSign:(ImageDirection)dir {
    switch (dir) {
        case ImageDirectionL2R:
        case ImageDirectionR2L:
            return 0;
        case ImageDirectionT2B:
            return 1;
        case ImageDirectionB2T:
            return -1;
        default:
            assert(0);
    }
}

+ (void)updateOffset:(ImageDirection)dir state:(ImageState *)state isNext:(BOOL)isNext nPage:(int)nPage {
    int sign = (dir == ImageDirectionL2R || dir == ImageDirectionT2B) ^ isNext ? -1 : 1;
    
    switch (dir) {
        case ImageDirectionL2R:
        case ImageDirectionR2L:
            state.matrix.tx += sign * state.pageSize.width * state.matrix.scale * nPage;
            break;
        case ImageDirectionT2B:
        case ImageDirectionB2T:
            state.matrix.ty += sign * state.pageSize.height * state.matrix.scale * nPage;
            break;
        default:
            assert(0);
    }
}

@end
