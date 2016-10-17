//
//  MessageCountdownView.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/20/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "MessageCountdownView.h"

@interface MessageCountdownView ()
@property (nonatomic, strong) UIImageView* badge;
@property (nonatomic) BOOL sent;
@end

@implementation MessageCountdownView

- (id)initWithFrame:(CGRect)frame sent:(BOOL)sent number:(int)number
{
    self = [super initWithFrame:frame];
    if (self) {
        _sent = sent;
        _number = number;
        [self addBadge];
    }
    return self;
}

- (void)addBadge
{
    NSString* imageName = self.sent ? @"red_circle" : @"gray_circle";
    CGRect rect = CGRectInset(self.bounds,1 , 1);
    
    UIImageView *badge = [WFCore imageWithBadge:rect
                                           icon:imageName
                                          color:[UIColor whiteColor]
                                          value:self.number];
    //badge.center = self.center;
    [self addSubview:badge];
    self.badge = badge;
}

- (void)setNumber:(int)number
{
    _number = number;
    
    [self.badge removeFromSuperview];
    [self addBadge];
}

@end
