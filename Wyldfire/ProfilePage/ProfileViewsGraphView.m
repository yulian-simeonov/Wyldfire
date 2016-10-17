//
//  ProfileViewsGraphView.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "ProfileViewsGraphView.h"

@interface ProfileViewsGraphView ()
    @property (nonatomic, strong) NSArray* dayBubbles;
    @property (nonatomic, strong) UILabel* topLabel;

    @property (nonatomic, strong) NSArray* connectingLines;
@end

@implementation ProfileViewsGraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
        [self setupLabel];
        [self setupGraph];
    }
    return self;
}

- (void)initialize
{
    _viewCounts = @[@(0), @(0), @(0), @(0), @(0)];
    _dayTitles = @[@"M", @"T", @"W", @"T", @"F"];
    
    self.backgroundColor = [UIColor whiteColor];
}

- (void)setupLabel
{
    CGRect topLabelRect = CGRectMake(0,
                                     30,
                                     self.frame.size.width,
                                     PROFILE_GRAPHS_LABEL_FONTSIZE);
    UILabel* label = [UILabel labelInRect:topLabelRect
                                 withText:@"Profile Views"
                                    color:[UIColor blackColor]
                                 fontSize:PROFILE_GRAPHS_LABEL_FONTSIZE];
    [self addSubview:label];
    self.topLabel = label;
}

- (void) setupGraph
{
    [self addDayBubbles];
    [self addLines];
}

- (void)addDayBubbles
{
    NSArray* dayBubbleTitles = self.dayTitles;
    
    NSInteger numDays = dayBubbleTitles.count;
    
    CGFloat sidePad = 16;
    
    CGRect graphArea = [self graphArea];
    
    NSMutableArray* dayBubbles = [NSMutableArray new];
    
    CGRect bubbleRect = CGRectMake(sidePad, graphArea.origin.y, 30, 30);
    for (int i = 0; i < 5; i++) {
        CGRect specificRect = CGRectOffset(bubbleRect,
                                           i * (graphArea.size.width / numDays),
                                           [self initialOffset]);
        
        DayBubbleView* bubble = [[DayBubbleView alloc] initWithFrame:specificRect title:dayBubbleTitles[i]];
        [self addSubview:bubble];
        [dayBubbles addObject:bubble];
    }
    
    self.dayBubbles = dayBubbles;
}

- (void)addLines
{
    NSMutableArray* linesArray = [NSMutableArray new];
    
    for (int i = 0; i < self.dayTitles.count - 1; i++) {
        DayBubbleView* bubble = self.dayBubbles[i];
        DayBubbleView* nextBubble = self.dayBubbles[i + 1];
        
        CAShapeLayer *lineShape = nil;
        CGMutablePathRef linePath = nil;
        linePath = CGPathCreateMutable();
        lineShape = [CAShapeLayer layer];
        
        lineShape.lineWidth = 1.0f;
        lineShape.lineCap = kCALineJoinMiter;
        lineShape.strokeColor = [WYLD_RED CGColor];
        
        CGPathMoveToPoint(linePath, NULL, bubble.center.x, bubble.center.y);
        CGPathAddLineToPoint(linePath, NULL, nextBubble.center.x, nextBubble.center.y);
        
        lineShape.path = linePath;
        CGPathRelease(linePath);
        
        [linesArray addObject:lineShape];
        //[self.layer addSublayer:lineShape];
        [self.layer insertSublayer:lineShape atIndex:0];
    }
    
    self.connectingLines = linesArray;
}

#pragma mark - Positioning

- (void)positionBubbles
{
    NSArray* dayBubbleTitles = self.dayTitles;
    NSInteger numDays = dayBubbleTitles.count;

    CGFloat sidePad = 16;
    CGRect graphArea = [self graphArea];
    
    CGRect bubbleRect = CGRectMake(sidePad, graphArea.origin.y, 30, 30);
    for (int i = 0; i < 5; i++) {
        CGRect specificRect = CGRectOffset(bubbleRect,
                                           i * (graphArea.size.width / numDays),
                                           [self offsetForIndex:i]);
        
        DayBubbleView* bubble = self.dayBubbles[i];
        bubble.frame = specificRect;
        bubble.title = self.dayTitles[i];
        bubble.views = [self.viewCounts[i] intValue];
    }
}

- (void)positionLines
{
    for (int i = 0; i < self.dayTitles.count - 1; i++) {
        DayBubbleView* bubble = self.dayBubbles[i];
        DayBubbleView* nextBubble = self.dayBubbles[i + 1];
        CAShapeLayer *lineShape = self.connectingLines[i];
        
        CGMutablePathRef linePath = nil;
        linePath = CGPathCreateMutable();
        
        CGPathMoveToPoint(linePath, NULL, bubble.center.x, bubble.center.y);
        CGPathAddLineToPoint(linePath, NULL, nextBubble.center.x, nextBubble.center.y);
        
        [CATransaction lock];
        [CATransaction begin];
        [CATransaction setAnimationDuration:PROFILE_VIEWS_ANIMATION_DURATION];
        CABasicAnimation *ba = [CABasicAnimation animationWithKeyPath:@"path"];
        ba.fillMode = kCAFillModeForwards;
        ba.fromValue = (id)lineShape.path;
        ba.toValue = (__bridge id)linePath;
        [lineShape addAnimation:ba forKey:@"animatePath"];
        [CATransaction commit];
        [CATransaction unlock];
        lineShape.path = linePath;
        
        CGPathRelease(linePath);
    }
}

- (CGFloat)graphMinOffset
{
    return PROFILE_VIEWS_BUBBLE_VIEW_SIZE;
}

- (CGFloat)graphMaxOffset
{
    return [self graphArea].size.height;
}

- (CGFloat)initialOffset
{
    return ([self graphMinOffset] + [self graphMaxOffset]) / 2;
}

- (CGFloat)offsetForIndex:(int)i
{
    CGFloat graphRange = [self graphMaxOffset] - [self graphMinOffset];
    CGFloat valueRange = [self maxViewCount] - [self minViewCount];
    
    CGFloat percentOfValueRange;
    if (valueRange == 0) {
        percentOfValueRange = .5;
    } else {
        percentOfValueRange = ([self viewsForIndex:i] - [self minViewCount]) / valueRange;
    }

    return graphRange - percentOfValueRange * graphRange;
}

- (CGRect)graphArea
{
    CGFloat startY = CGRectGetMaxY(self.topLabel.frame) + 20;
    return CGRectMake(0,
                      startY,
                      CARD_WIDTH,
                      PROFILE_VIEWS_GRAPH_TOTALHEIGHT - startY - 30);
}

#pragma mark - Data 

- (float)averageViewCount
{
    NSNumber* ave = [self.viewCounts valueForKeyPath:@"@avg.floatValue"];
    return [ave floatValue];
}

- (float)minViewCount
{
    NSNumber* min = [self.viewCounts valueForKeyPath:@"@min.floatValue"];
    return [min floatValue];
}

- (float)maxViewCount
{
    NSNumber* max = [self.viewCounts valueForKeyPath:@"@max.floatValue"];
    return [max floatValue];
}

- (int)viewsForIndex:(int)index
{
    NSNumber* dayCount = (NSNumber*)self.viewCounts[index];
    return [dayCount intValue];
}

- (float)percentIncreaseOfIndex:(int)index
{
    if (index == 0) return 0;
    
    int dayBefore = [self viewsForIndex:index - 1];
    int dayOf = [self viewsForIndex:index];
    
    if (dayBefore == 0) return 0;
    
    return (float)dayOf / (float)dayBefore;
}

#pragma mark Input

- (void)setViewCounts:(NSArray *)viewCounts withDayTitles:(NSArray *)dayTitles
{
    if (viewCounts == nil || dayTitles == nil) return;
    
    _viewCounts = @[@(0), @(0), @(0), @(0), @(0)];
    [self positionBubbles];
    [self positionLines];
    
    _viewCounts = viewCounts;
    _dayTitles = dayTitles;
    
    NSLog(@"%@", viewCounts);
    
    [UIView animateWithDuration:PROFILE_VIEWS_ANIMATION_DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self positionBubbles];
                         [self positionLines];
                     } completion:^(BOOL finished) {
                         //
                     }];
}

- (void)animate
{
    [self setViewCounts:self.viewCounts withDayTitles:self.dayTitles];
}

@end
