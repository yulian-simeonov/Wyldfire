//
//  SideBarProfileView.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "SideBarProfileView.h"

@interface SideBarProfileView ()
@property (nonatomic, strong) UIImageView* ellipseView;
@end

@implementation SideBarProfileView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    [self subscribeToNotifications];
    [self setupImage];
    [self setupName];
}

- (void)setupImage
{
    float totalWidth = CGRectGetWidth(self.frame);
    
    //Ellipse around Image
    CGRect imageEllipseframe = CGRectMake((totalWidth - SIDEBAR_IMAGE_ELLIPSE_DIAMETER - DRAWER_WIDTH) / 2,
                                   SIDEBAR_IMAGE_Y_OFFSET,
                                   SIDEBAR_IMAGE_ELLIPSE_DIAMETER,
                                   SIDEBAR_IMAGE_ELLIPSE_DIAMETER);
    
    UIImageView* ellipseView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sidebar_ellipse"]];
    ellipseView.frame = imageEllipseframe;
    [self addSubview:ellipseView];
    self.ellipseView = ellipseView;
    
    //Image within Ellipse
    float imageInsetAmount =  SIDEBAR_IMAGE_ELLIPSE_DIAMETER - SIDEBAR_IMAGE_DIAMETER;
    CGRect imageFrame = CGRectInset(imageEllipseframe, imageInsetAmount, imageInsetAmount);
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:imageFrame];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.layer.cornerRadius = CGRectGetWidth(imgView.frame) / 2;
    imgView.layer.masksToBounds = YES;
    imgView.image = [WFCore get].accountStructure.avatarPhoto;
    
    [self addSubview:imgView];
    self.profileImage = imgView;
}

- (void)setupName
{
    CGRect nameRect = CGRectMake(0,
                                 SIDEBAR_IMAGE_ELLIPSE_DIAMETER + SIDEBAR_IMAGE_Y_OFFSET + 5,
                                 CGRectGetWidth(self.frame) - DRAWER_WIDTH,
                                 SIDEBAR_PROFILE_NAME_FONTSIZE + 2);
    self.profileName = [self labelWithFontSize:SIDEBAR_PROFILE_NAME_FONTSIZE
                                           color:[UIColor whiteColor]
                                           frame:nameRect];
    self.profileName.font = [UIFont fontWithName:BOLD_FONT size:17];
    
    CGRect likesRect = CGRectMake(0,
                                  CGRectGetMaxY(nameRect) + 2,
                                  CGRectGetWidth(self.frame) - DRAWER_WIDTH,
                                  SIDEBAR_PROFILE_LIKES_FONTSIZE);
    self.profileLikes = [self labelWithFontSize:SIDEBAR_PROFILE_LIKES_FONTSIZE
                                         color:WYLD_RED
                                         frame:likesRect];
}

- (UILabel*)labelWithFontSize:(float)fontSize color:(UIColor*)color frame:(CGRect)frame
{
    UILabel* ret = [[UILabel alloc] initWithFrame:frame];
    
    ret.textColor = color;
    ret.textAlignment = NSTextAlignmentCenter;
    ret.font = [UIFont fontWithName:MAIN_FONT size:fontSize];
    [self addSubview:ret];
    
    return ret;
}

#pragma mark - Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadImage)
                                                 name:NOTIFICATION_UPDATED_ACCOUNT_PHOTOS
                                               object:nil];
}

- (void)reloadImage
{
    self.profileImage.image = [WFCore get].accountStructure.avatarPhoto;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Animation

- (void)animate
{
    //Scale image
    CABasicAnimation* scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [scale setFromValue:@(1)];
    [scale setToValue:@(0.9)];
    [scale setAutoreverses:YES];
    [scale setDuration:SIDEBAR_ANIMATION_TIME / 2];
    [scale setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [self.profileImage.layer addAnimation:scale forKey:@"scaled"];
    
    //Fade border
    CABasicAnimation *fadeAnim=[CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnim.fromValue = @(1.0);
    fadeAnim.toValue =   @(0.0);
    [fadeAnim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [fadeAnim setAutoreverses:YES];
    [fadeAnim setDuration:SIDEBAR_ANIMATION_TIME / 2];
    [self.ellipseView.layer addAnimation:fadeAnim forKey:@"faded"];
    
    scale.toValue = @(1.05);
    [self.ellipseView.layer addAnimation:scale forKey:@"scale"];
}

@end
