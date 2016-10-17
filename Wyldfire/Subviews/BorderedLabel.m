//
//  BorderedLabel.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "BorderedLabel.h"

@interface BorderedLabel ()
@property (nonatomic, strong) UIColor* outlineColor;
@property (nonatomic) CGFloat outlineWidth;
@property (nonatomic) CGFloat verticalAlignment;
@property (nonatomic) CGFloat shadeBlur;
@property (nonatomic, strong) UIColor*  diffuseShadowColor;
@property (nonatomic) CGFloat diffuseShadowOffset;
@end

@implementation BorderedLabel

- (void)drawTextInRect:(CGRect)rect {
    
    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor = self.textColor;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, 0.5);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = [UIColor whiteColor];
    [super drawTextInRect:rect];
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:rect];
    
    self.shadowOffset = shadowOffset;
}

@end
