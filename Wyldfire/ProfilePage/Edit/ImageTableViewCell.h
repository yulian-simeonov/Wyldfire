//
//  ImageTableViewCell.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UILabel+util.h"

@interface ImageTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic) BOOL isAvatar;

@end
