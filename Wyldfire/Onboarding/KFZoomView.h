//
//  KFZoomView.h
//  PhotoManager
//
//  Created by Danny on 5/3/13.
//  Copyright (c) 2013 Augmented Reality Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KFImageZoomView : UIScrollView <UIScrollViewDelegate> 

@property (nonatomic, retain)   UIImageView     *imageView;

- (id)initWithImage:(UIImage*)image andFrame:(CGRect)frame;

@end
