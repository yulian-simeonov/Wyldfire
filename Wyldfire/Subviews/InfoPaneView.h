//
//  InfoPaneView.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/17/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

// Profile info panel
@interface InfoPaneView: UIView

@property (strong, nonatomic) UILabel *name;
@property (strong, nonatomic) UIImageView *circle;
@property (strong, nonatomic) UIImageView *icon;
@property (nonatomic) float fontSize;
@property (nonatomic) int iconOffset;
@property (strong, nonatomic) UILabel *info1;
@property (strong, nonatomic) UIImageView *icon1;
@property (strong, nonatomic) UILabel *info2;
@property (strong, nonatomic) UIImageView *icon2;
@property (nonatomic) float fontSize1;
@property (nonatomic) BOOL vertical;

- (void)configure;
- (InfoPaneView *)initWithFrame:(CGRect)frame;

@end
