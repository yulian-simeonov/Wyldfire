//
//  WFZoomView.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/31/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFZoomView : UIView

@property (nonatomic, retain)   UIImageView     *imageView;

- (id)initWithImage:(UIImage*)image andFrame:(CGRect)frame;

@end
