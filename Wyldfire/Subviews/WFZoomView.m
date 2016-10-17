//
//  WFZoomView.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/31/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "WFZoomView.h"

@interface WFZoomView () <UIGestureRecognizerDelegate>

@end

@implementation WFZoomView

- (id)initWithImage:(UIImage*)image andFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addImageView:image];
        [self addRecognizers];
    }
    return self;
}

- (void)addImageView:(UIImage*)image
{
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:self.bounds];
    
    imgView.image = image;
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self addSubview:imgView];
    self.imageView = imgView;
    
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor blackColor];
}

- (void)addRecognizers
{
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    UIPinchGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    
    pan.delegate = self;
    pinch.delegate = self;
    
    [self addGestureRecognizer:pan];
    [self addGestureRecognizer:pinch];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)handlePan:(UIPanGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded
        || recognizer.state == UIGestureRecognizerStateChanged) {
        
        CGPoint currentTranslation = self.imageView.origin;
        
        CGPoint deltaTranslation = [recognizer translationInView:self];
        
        
        CGFloat newXtranslation = currentTranslation.x + deltaTranslation.x;
        CGFloat newYtranslation = currentTranslation.y + deltaTranslation.y;
        
        
        if (ABS(newXtranslation) > self.imageView.width) {
            newXtranslation = currentTranslation.x;
        }
        
        if (ABS(newYtranslation) > self.imageView.height) {
            newYtranslation = currentTranslation.y;
        }
        
        self.imageView.x = newXtranslation;
        self.imageView.y = newYtranslation;
        
        [recognizer setTranslation:CGPointMake(0.0, 0.0) inView:self];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded
        || gesture.state == UIGestureRecognizerStateChanged) {
        NSLog(@"gesture.scale = %f", gesture.scale);
        
        CGFloat currentScale = self.frame.size.width / self.bounds.size.width;
        CGFloat newScale = currentScale * gesture.scale;
        
        if (newScale < 0.1) {
            newScale = 0.1;
        }
        if (newScale > 10.0) {
            newScale = 10.0;
        }
        
        CGAffineTransform transform = CGAffineTransformScale(self.imageView.transform, newScale, newScale);
        self.imageView.transform = transform;
        gesture.scale = 1;
    }
}


- (void)dealloc
{
    for (UIGestureRecognizer* recognizer in self.gestureRecognizers)
    {
        recognizer.enabled = NO;
        [self removeGestureRecognizer:recognizer];
    }
}

@end
