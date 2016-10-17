//
//  RangeSlider.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/26/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//
// Modified version of https://github.com/buildmobile/iosrangeslider

#import "RangeSlider.h"

@interface RangeSlider ()
@end

@implementation RangeSlider {
    float _distance;
    float _padding;
    BOOL _minOn;
    BOOL _maxOn;
    UIImageView * _min;
    UIImageView * _max;
    UIImageView * _selected;
    UIImageView * _bg;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self.minValue = 0.0;
    self.maxValue = 1.0;
    self.minRange = 0.0;
    self.value0 = 0;
    self.value1 = 1;
    self.exclusiveTouch = YES;

    UIImage* image = [[UIImage imageNamed:@"range-bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
    _bg = [[UIImageView alloc] initWithImage:image];
    _bg.frame = CGRectMake(0, frame.size.height/2 - _bg.frame.size.height/2, frame.size.width, _bg.frame.size.height);
    [self addSubview:_bg];
    
    image = [[UIImage imageNamed:@"range-selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
    _selected = [[UIImageView alloc] initWithImage:image];
    _selected.frame = _bg.frame;
    [self addSubview:_selected];
    
    _min = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"range-handle"]];
    _min.center = CGPointMake(0, _bg.center.y);
    [self addSubview:_min];
    
    _max = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"range-handle"]];
    _max.center = CGPointMake(0, _bg.center.y);
    [self addSubview:_max];
   
    _minOn = NO;
    _maxOn = NO;
    _padding = _min.frame.size.width/4;
    
    return self;
}

- (void)layoutSubviews
{
    if (self.value0 < self.minValue) self.value0 = self.minValue;
    if (self.value1 > self.maxValue) self.value1 = self.maxValue;
    _min.center = CGPointMake([self xForValue:self.value0], _min.center.y);
    _max.center = CGPointMake([self xForValue:self.value1], _max.center.y);
    _selected.frame = CGRectMake(_min.center.x, _selected.frame.origin.y, _max.center.x - _min.center.x, _selected.frame.size.height);
}

- (float)xForValue:(float)value
{
    return (self.frame.size.width - (_padding * 2)) * ((value - self.minValue) / (self.maxValue - self.minValue)) + _padding;
}

- (float)valueForX:(float)x
{
    return self.minValue + (x - _padding) / (self.frame.size.width - (_padding * 2)) * (self.maxValue - self.minValue);
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint point = [touch locationInView:self];
    
    if (CGRectContainsPoint(_max.frame, point)) {
        _maxOn = true;
        _distance = point.x - _max.center.x;
    } else
    if (CGRectContainsPoint(_min.frame, point)) {
        _minOn = true;
        _distance = point.x - _min.center.x;
    }
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!_minOn && !_maxOn) return YES;
    
    CGPoint touchPoint = [touch locationInView:self];
    if (_maxOn) {
        _max.center = CGPointMake(MIN([self xForValue:self.maxValue], MAX(touchPoint.x - _distance, [self xForValue:self.value0 + self.minRange])), _max.center.y);
        self.value1 = [self valueForX:_max.center.x];
    } else
    if (_minOn) {
        _min.center = CGPointMake(MAX([self xForValue:self.minValue], MIN(touchPoint.x - _distance, [self xForValue:self.value1 - self.minRange])), _min.center.y);
        self.value0 = [self valueForX:_min.center.x];
    }
    [self setNeedsLayout];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _minOn = false;
    _maxOn = false;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
