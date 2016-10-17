//
//  ImageViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/21/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController ()

@end

@implementation ImageViewController

- (void)addObscurants
{
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    [self addObscurantWithFrame:CGRectMake(0,
                                           0,
                                           width, 20)];
    
    [self addObscurantWithFrame:CGRectMake(0,
                                           930 / 2,
                                           width, height - 930 / 2)];
}

- (void)addObscurantWithFrame:(CGRect)frame
{
    UIView* obscurant = [[UIView alloc] initWithFrame:frame];
    obscurant.backgroundColor = GRAY_1;
    [self.view addSubview:obscurant];
}

- (UIImageView*)imageView
{
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.clipsToBounds = YES;
    
    return imgView;
}

- (CGRect)bottomButtonRect
{
    CGFloat buttonHeight = 45;
    CGFloat pad = 8;
    CGRect buttonRect = CGRectMake(pad,
                                   CGRectGetHeight(self.view.frame) - buttonHeight - pad,
                                   CGRectGetWidth(self.view.frame) - pad * 2,
                                   buttonHeight);
    return buttonRect;
}

- (UIButton*)addButtonWithTitle:(NSString*)title backgroundColor:(UIColor*)bgColor frame:(CGRect)frame selectorString:(NSString*)selectorString
{
    UIButton* button = [[UIButton alloc] initWithFrame:frame];
    button.backgroundColor = bgColor;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:NSSelectorFromString(selectorString) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button];
    return button;
}

@end
