//
//  GestureDetectorView.h
//  docnext
//
//  Created by  on 11/10/04.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GestureRecognizerDelegate

- (void)onSingleTap:(CGPoint)point;
- (void)onDoubleTap:(CGPoint)point;
- (void)onLongPress;
- (void)onScale:(float)scale focus:(CGPoint)focus;
- (void)onScroll:(CGPoint)distance;
- (void)onFling:(CGPoint)velocity;
- (void)onTouchBegin;
- (void)onTouchEnd;

@end

@interface GestureRecognizerView : UIView

@property(nonatomic, assign) id<GestureRecognizerDelegate> delegate;

@end
