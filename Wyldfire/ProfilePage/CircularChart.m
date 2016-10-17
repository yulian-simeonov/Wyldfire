//
//  CircularChart.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "CircularChart.h"

@interface CircularChart ()
    @property (nonatomic, strong) CircleChart *circleChart;
@end

@implementation CircularChart

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _progress = 0;
        [self drawCircleChart];
    }
    return self;
}

- (void)drawCircleChart
{
    self.circleChart = [[CircleChart alloc] initWithFrame:self.bounds];
    
    self.circleChart.axisColor = [UIColor whiteColor];
    self.circleChart.currentColor = WYLD_RED;
    self.circleChart.totalColor = WYLD_BLUE;
    
    self.circleChart.lineWidth = 3;
    [self addSubview:self.circleChart];
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    self.circleChart.current = MIN(progress * 100, 100);
    [self.circleChart drawChart];
    self.circleChart.completionHandler = ^(UIView *view) {
        GlowAnimation *glow = [[GlowAnimation alloc] init:nil stop:nil];
        [glow configure:view];
    };
}

@end
