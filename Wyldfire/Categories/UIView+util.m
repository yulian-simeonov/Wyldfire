//
//  UIView+util.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "UIView+util.h"

@implementation UIView (util)

- (UIImage *) imageOfView
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (void)maskTopRightTriangle:(CGFloat)width
{
    //Create a path for the view with a triangle cut out of the top right
    CGPoint triangleTop = CGPointMake(CARD_WIDTH - width, 0);
    CGPoint triangleBottom = CGPointMake(CARD_WIDTH, width);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, triangleTop.x, triangleTop.y);
    CGPathAddLineToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, 0, CARD_HEIGHT);
    CGPathAddLineToPoint(path, NULL, CARD_WIDTH, CARD_HEIGHT);
    CGPathAddLineToPoint(path, NULL, triangleBottom.x, triangleBottom.y);
    CGPathAddLineToPoint(path, NULL, triangleTop.x, triangleTop.y);
    
    //Mask the view with that path
    CAShapeLayer* mask = [CAShapeLayer layer];
    mask.frame = self.bounds;
    mask.path = path;
    self.layer.mask = mask;
    self.layer.masksToBounds = YES;
    CGPathRelease(path);
}

- (BOOL)locationServicesEnabled
{
    return [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied;
}

@end
