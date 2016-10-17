//
//  DayBubbleView.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "DayBubbleView.h"

@interface DayBubbleView ()
    @property (nonatomic, strong) UILabel* titleLabel;
    @property (nonatomic, strong) UILabel* percentLabel;
    @property (nonatomic, strong) UIImageView* imageView;
@end

@implementation DayBubbleView

- (id)initWithFrame:(CGRect)frame title:(NSString*)title
{
    self = [super initWithFrame:frame];
    if (self) {
        _title = title;
        self.clipsToBounds = NO;
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self addImageViewAndLabel];
    [self addPercentLabel];
}

- (void)addImageViewAndLabel
{
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"red_circle"]];
    imgView.frame = CGRectMake(0, 0, 26, 26);
    self.imageView = imgView;
    
    CGRect rect = CGRectMake(0, 0, 20, PROFILE_GRAPHS_LABEL_FONTSIZE);
    UILabel* label = [UILabel labelInRect:rect
                                 withText:self.title
                                    color:[UIColor whiteColor]
                                 fontSize:PROFILE_GRAPHS_LABEL_FONTSIZE];
    [self addSubview:imgView];
    [self addSubview:label];
    label.center = imgView.center;
    self.titleLabel = label;
}

- (void)addPercentLabel
{
    CGRect percentRect = CGRectMake(-5,
                                    CGRectGetMinY(self.imageView.frame) - PROFILE_VIEWS_GRAPH_PERCENT_FONTSIZE - 5,
                                    CGRectGetWidth(self.frame) + 10,
                                    PROFILE_VIEWS_GRAPH_PERCENT_FONTSIZE);
    UILabel* label = [UILabel labelInRect:percentRect
                                 withText:@"" color:GRAY_3 fontSize:PROFILE_VIEWS_GRAPH_PERCENT_FONTSIZE];
    label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:label];
    self.percentLabel = label;
}

#pragma mark Input Data

- (void)setViews:(int)views
{
    _views = views;
    self.percentLabel.text = [NSString stringWithFormat:@"%i", views];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}


@end
