//
//  KFZoomView.m
//  PhotoManager
//
//  Created by Danny on 5/3/13.
//  Copyright (c) 2013 Augmented Reality Studios. All rights reserved.
//

#import "KFZoomView.h"

@interface KFImageZoomView ()
    @property (nonatomic, strong) UIView* holderView;
@end

@implementation KFImageZoomView

#pragma mark - Initialisation

- (id)initWithImage:(UIImage*)image andFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        // Assign the delegate
        self.delegate = self;
        
        // Create our image view using the passed in image name
        UIImageView* imgView = [[UIImageView alloc] initWithImage:image];
        UIView* holder = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                  0,
                                                                  image.size.width + 300,
                                                                  image.size.height + 300)];
        [holder addSubview:imgView];
        imgView.center = holder.center;
        self.imageView = imgView;
        self.holderView = holder;
        
        // Update the ImageZoom frame to match the dimensions of passed in image
//        float width = holder.width;
//        float height = holder.height;
        //self.frame = CGRectMake(width/2, height/2, width, height);
        //self.contentSize = CGSizeMake(width, height);
        self.contentSize = holder.bounds.size;
        
        // Set a default minimum and maximum zoom scale
        CGRect scrollViewFrame = frame;
        CGFloat scaleWidth = scrollViewFrame.size.width / image.size.width;
        CGFloat scaleHeight = scrollViewFrame.size.height / image.size.height;
        CGFloat minScale = MIN(scaleWidth, scaleHeight);
        CGFloat maxScale = 5.0f;
        
        self.minimumZoomScale = minScale / 2.0f;
        self.maximumZoomScale = maxScale * 2.0f;
        //self.zoomScale = MIN(minScale, maxScale);
        //[self scrollRectToVisible:self.imageView.frame animated:NO];
        [self zoomToRect:self.imageView.frame animated:NO];
        //self.zoomScale = MAX(scaleWidth, scaleHeight);
        //self.contentInset = UIEdgeInsetsMake(300, 300, 0, 0);
        ///zoomToRect will take care of this
        
        // Add image view as a subview
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
        [self addSubview:self.holderView];
        
    }
    
    return self;
}


#pragma mark - UIScrollViewDelegates

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    NSLog(@"Scale: %f", scale);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.holderView;
}

@end