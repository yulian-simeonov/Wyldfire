//
//  UIView+util.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface UIView (util)

- (UIImage *) imageOfView;
- (void)maskTopRightTriangle:(CGFloat)width;
- (BOOL)locationServicesEnabled;

@end
