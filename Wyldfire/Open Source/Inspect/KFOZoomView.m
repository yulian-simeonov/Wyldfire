//
//  KFZoomView.m
//  PhotoManager
//
//  Created by Danny on 5/3/13.
//  Copyright (c) 2013 Augmented Reality Studios. All rights reserved.
//

#import "KFOZoomView.h"

@interface KFOImageZoomView ()
@property (nonatomic, strong) UIGestureRecognizer* recognizer;
@end

@implementation KFOImageZoomView

#pragma mark - Initialisation

- (id)initWithImage:(UIImage*)image andFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        // Assign the delegate
        self.delegate = self;
        
        // Create our image view using the passed in image name
        self.imageView = [[UIImageView alloc] initWithImage:image];
        
        // Update the ImageZoom frame to match the dimensions of passed in image
        float width = frame.size.width;
        float height = frame.size.height;
        self.frame = CGRectMake(width/2, height/2, width, height);
        //self.contentSize = CGSizeMake(width, height);
        self.contentSize = image.size;
        
        // Set a default minimum and maximum zoom scale
        CGRect scrollViewFrame = self.frame;
        CGFloat scaleWidth = scrollViewFrame.size.width / self.contentSize.width;
        CGFloat scaleHeight = scrollViewFrame.size.height / self.contentSize.height;
        CGFloat minScale = MIN(scaleWidth, scaleHeight);
        CGFloat maxScale = 5.0f;
        
        self.minimumZoomScale = minScale;
        self.maximumZoomScale = maxScale;
        self.zoomScale = MIN(minScale, maxScale);
        
        // Add image view as a subview
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
        [self addSubview:self.imageView];
        
        [self addGestureRecognizers];
    }
    
    return self;
}


#pragma mark - Gesture Recognizers

- (void)addGestureRecognizers
{
    UITapGestureRecognizer* rec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    rec.numberOfTapsRequired = 2;
    [self addGestureRecognizer:rec];
    
    self.recognizer = rec;
}

- (void)handleDoubleTap:(UITapGestureRecognizer*)recognizer
{
    //CGPoint tapLocation = [recognizer locationInView:self];
    /*[UIView animateWithDuration:0.25
                     animations:^{
                         if (self.zoomScale == self.minimumZoomScale) {
                             self.zoomScale = self.maximumZoomScale;
                         } else {
                             self.zoomScale = self.minimumZoomScale;
                         }
                     }];*/
    
    CGPoint pointInView = [recognizer locationInView:self.imageView];
    
    // 2
    CGFloat newZoomScale = self.zoomScale * 2.0f;
    newZoomScale = MIN(newZoomScale, self.maximumZoomScale);
    
    // 3
    CGSize scrollViewSize = self.bounds.size;
    
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = pointInView.x - (w / 2.0f);
    CGFloat y = pointInView.y - (h / 2.0f);
    
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    
    // 4
    if (self.zoomScale < self.maximumZoomScale) {
        [self zoomToRect:rectToZoomTo animated:YES];
    } else {
        [UIView animateWithDuration:0.25
                         animations:^{
                                self.zoomScale = self.minimumZoomScale;
                         }];
    }
}

- (void)centerScrollViewContents {
    CGSize boundsSize = self.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    
    self.imageView.frame = contentsFrame;
}

#pragma mark - UIScrollViewDelegates


- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    
    }

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

-(void)dealloc
{
    [self removeGestureRecognizer:self.recognizer];
    self.recognizer = nil;
}

@end