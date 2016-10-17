//
//  ImageViewController.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/21/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageViewController : UIViewController

- (void)addObscurants;
- (UIImageView*)imageView;
- (CGRect)bottomButtonRect;
- (UIButton*)addButtonWithTitle:(NSString*)title backgroundColor:(UIColor*)bgColor frame:(CGRect)frame selectorString:(NSString*)selectorString;

@end
