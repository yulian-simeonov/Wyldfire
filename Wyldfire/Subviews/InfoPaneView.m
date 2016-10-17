//
//  InfoPaneView.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/17/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "InfoPaneView.h"

@implementation InfoPaneView

- (InfoPaneView *)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    [self setupDefaults];
    [self setupUI];
    
    return self;
}

- (void)setupDefaults
{
    self.backgroundColor = [UIColor whiteColor];
    self.autoresizesSubviews = NO;
    self.autoresizingMask = UIViewAutoresizingNone;
}

- (void)setupUI
{
    [self leftTriangle];
    
    self.circle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_eclipse2"]];
    self.circle.contentMode = UIViewContentModeScaleAspectFill;
    
    self.name = [self defaultLabel];
    self.name.textColor = [UIColor blackColor];
    
    self.info1 = [self defaultLabel];
    self.info2 = [self defaultLabel];
}

- (void)leftTriangle
{
    CGFloat height = CGRectGetHeight(self.frame);
    UIView* tri = [[UIView alloc] initWithFrame:CGRectMake(5, 0, height, height)];
    tri.transform = CGAffineTransformMakeRotation(M_PI_4);
    tri.backgroundColor = [UIColor whiteColor];
    [self addSubview:tri];
}

- (UILabel*)defaultLabel
{
    UILabel* ret = [[UILabel alloc] initWithFrame:CGRectZero];
    ret.textColor = [UIColor grayColor];
    ret.baselineAdjustment = UIBaselineAdjustmentNone;
    return ret;
}

- (void)configure
{
    [self setupProfileIconCircle];
    
    float xOffset = 10 + CGRectGetMinX(self.circle.frame) + CGRectGetWidth(self.circle.frame);
    float yOffset = 12 ;
    
    [self setupProfileNameWithXOffset:xOffset yOffset:yOffset];
    
    [self setupFirstInfoElementForXOffset:xOffset];
    [self setupSecondInfoElementForXOffset:xOffset + 10];
}

- (void)setupProfileIconCircle
{
    float totalHeight = CGRectGetHeight(self.frame);

    self.circle.frame = CGRectMake(13,
                                   (totalHeight - 42) / 2,
                                   44,
                                   44);
    [self addSubview:self.circle];
    //self.circle.transform = CGAffineTransformMakeRotation(M_PI);
    
    float circleWidth = 40;//CGRectGetWidth(self.circle.frame);
    float circleHeight = 40;//CGRectGetHeight(self.circle.frame);
    
    UIImageView* icon = [[UIImageView alloc] initWithFrame:CGRectMake(5,
                                                                      5,
                                                                      circleWidth,
                                                                      circleHeight)];
    icon.center = self.circle.center;
    icon.contentMode = UIViewContentModeScaleAspectFill;
    icon.layer.cornerRadius = CGRectGetWidth(icon.frame) / 2;
    icon.layer.masksToBounds = YES;
    
    [self addSubview:icon];
    self.icon = icon;
}

- (void)setupProfileNameWithXOffset:(float)xOffset yOffset:(float)yOffset
{
    self.name.frame = CGRectMake(xOffset,
                                 yOffset,
                                 self.frame.size.width - xOffset,
                                 21);
    self.name.font = [UIFont fontWithName:MAIN_FONT size:17];
    [self addSubview:self.name];
}

- (void)setupFirstInfoElementForXOffset:(float)xOffset
{
    // Text
    float fontSize = 12;
    CGRect frame = CGRectMake(xOffset,
                              CGRectGetMaxY(self.name.frame) + 5,
                              CGRectGetWidth(self.frame) - xOffset,
                              fontSize + 2);
    
    [self setupInfoLabel:self.info1 frame:frame icon:self.icon1 fontSize:fontSize];
}

- (void)setupSecondInfoElementForXOffset:(float)xOffset
{
    float fontSize = 12;
    float totalWidth = CGRectGetWidth(self.frame);
    CGPoint info1Origin = self.info1.frame.origin;
    
    CGRect frame = CGRectMake(xOffset + (totalWidth - info1Origin.x) / 2 - 5,
                              info1Origin.y,
                              totalWidth - xOffset,
                              fontSize + 2);
    
    [self setupInfoLabel:self.info2 frame:frame icon:self.icon2 fontSize:fontSize];
}

- (void)setupInfoLabel:(UILabel*)label frame:(CGRect)frame icon:(UIView*)icon fontSize:(float)fontSize
{
    label.frame = frame;
    label.font = [UIFont fontWithName:MAIN_FONT size:fontSize];
    
    [self addSubview:label];
    
    // Place icon in front of the text
    if (icon) {
        icon.frame = (CGRect) { label.frame.origin,
                                icon.frame.size };
        float pad = 5;
        float iconWidth = CGRectGetWidth(icon.frame);
        label.frame = CGRectMake(CGRectGetMaxX(icon.frame) + pad,
                                      CGRectGetMinY(label.frame),
                                      CGRectGetWidth(label.frame) - pad - iconWidth,
                                      CGRectGetHeight(label.frame));
        [self addSubview:icon];
    }
}

@end
