//
//  Charts.h
//  Wyldfire
//
//  Created by Vlad Seryakov 11/7/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//
//  Based on PNChart project: https://github.com/kevinzhow/PNChart
//

@interface BarChart : UIView
@property (strong, nonatomic) NSArray *xLabels;
@property (strong, nonatomic) NSArray *yValues;
@property (nonatomic, strong) UIColor *barColor;
@property (nonatomic, strong) UIColor *axisColor;
@property (nonatomic, strong) NSDictionary *colors;
@property (nonatomic, strong) SuccessBlock completionHandler;
- (void)drawChart;
@end

@interface LineChart : UIView
@property (strong, nonatomic) NSArray *xLabels;
@property (strong, nonatomic) NSArray *yValues;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *axisColor;
@property (nonatomic, strong) SuccessBlock completionHandler;
- (void)drawChart;
@end

@interface CircleChart : UIView
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong) UIColor *totalColor;
@property (nonatomic, strong) UIColor *currentColor;
@property (nonatomic, strong) UIColor *axisColor;
@property (nonatomic) float axisFontSize;
@property (nonatomic) float total;
@property (nonatomic) float current;
@property (nonatomic) float lineWidth;
@property (nonatomic, strong) SuccessBlock completionHandler;
- (void)drawChart;
@end

@interface CountingLabel : UILabel
@property (nonatomic, assign) NSString *method;
@property (nonatomic, strong) NSString *format;
@property (nonatomic, strong) SuccessBlock completionHandler;
-(void)countFrom:(float)from to:(float)to duration:(NSTimeInterval)duration;
@end
