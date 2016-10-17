//
//  ChatListImageView.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/20/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatListImageView : UIView

@property (nonatomic, strong) UIImage* image;
@property (nonatomic) int number;
@property (nonatomic, strong) UILabel* numberLabel;

+ (id)imageViewWithFrame:(CGRect)rect number:(int)number image:(UIImage*)image;

@end
