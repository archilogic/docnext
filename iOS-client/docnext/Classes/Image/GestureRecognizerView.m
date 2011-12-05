//
//  GestureDetectorView.m
//  docnext
//
//  Created by  on 11/10/04.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "GestureRecognizerView.h"

@interface GestureRecognizerView ()

@property(nonatomic) CGPoint dragPrevPoint0;
@property(nonatomic) CGPoint dragPrevPoint1;
@property(nonatomic) double dragPrevTime0;
@property(nonatomic) double dragPrevTime1;

@end

@implementation GestureRecognizerView

@synthesize delegate;

@synthesize dragPrevPoint0;
@synthesize dragPrevPoint1;
@synthesize dragPrevTime0;
@synthesize dragPrevTime1;

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    
    if (self) {
        UITapGestureRecognizer* doubleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)] autorelease];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        
        UITapGestureRecognizer* singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)] autorelease];
        [singleTap requireGestureRecognizerToFail:doubleTap];
        [self addGestureRecognizer:singleTap];

        [self addGestureRecognizer:[[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)] autorelease]];
        [self addGestureRecognizer:[[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)] autorelease]];
        [self addGestureRecognizer:[[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease]];
    }
    
    return self;
}

- (void)dealloc {
    self.delegate = nil;
    
    [super dealloc];
}

- (void)checkIsBegan:(UIGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self.delegate onTouchBegin];
    }
}

- (void)checkIsEnded:(UIGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self.delegate onTouchEnd];
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self checkIsBegan:sender];
    
    [self.delegate onSingleTap:[sender locationInView:self]];
    
    [self checkIsEnded:sender];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)sender {
    [self checkIsBegan:sender];
    
    [self.delegate onDoubleTap:[sender locationInView:self]];
    
    [self checkIsEnded:sender];
}

- (void)handlePinch:(UIPinchGestureRecognizer *)sender {
    [self checkIsBegan:sender];
    
    if (sender.numberOfTouches < 2) {
        [self checkIsEnded:sender];
        return;
    }
    
    CGPoint p0 = [sender locationOfTouch:0 inView:self];
    CGPoint p1 = [sender locationOfTouch:1 inView:self];
    
    [self.delegate onScale:sender.scale focus:CGPointMake((p0.x + p1.x) / 2, (p0.y + p1.y) / 2)];

    sender.scale = 1;
    
    [self checkIsEnded:sender];
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    [self checkIsBegan:sender];
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        [self.delegate onScroll:[sender translationInView:self]];
    
        [sender setTranslation:CGPointZero inView:self];
        
        self.dragPrevPoint1 = self.dragPrevPoint0;
        self.dragPrevPoint0 = [sender locationInView:self];
        self.dragPrevTime1 = self.dragPrevTime0;
        self.dragPrevTime0 = CFAbsoluteTimeGetCurrent();
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        double diff = CFAbsoluteTimeGetCurrent() - self.dragPrevTime1;
        CGPoint velocity = CGPointMake((self.dragPrevPoint0.x - self.dragPrevPoint1.x) / diff, (self.dragPrevPoint0.y - self.dragPrevPoint1.y) / diff);
        
        [self.delegate onFling:velocity];
    }
    
    [self checkIsEnded:sender];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    [self checkIsBegan:sender];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self.delegate onLongPress];
    }
    
    [self checkIsEnded:sender];
}

@end
