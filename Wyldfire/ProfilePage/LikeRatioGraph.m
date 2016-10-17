//
//  LikeRatioGraph.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "LikeRatioGraph.h"
#import "CircularChart.h"

@interface LikeRatioGraph ()
    @property (nonatomic, strong) UILabel* youveLikedLabelTop;
    @property (nonatomic, strong) UILabel* youveLikedLabelBottom;
    @property (nonatomic, strong) UILabel* likeRationLabelTop;
    @property (nonatomic, strong) UILabel* likeRationLabelBottom;
    @property (nonatomic, strong) UILabel* beenLikedLabelTop;
    @property (nonatomic, strong) UILabel* beenLikedLabelBottom;

    @property (nonatomic, strong) CircularChart* circularChart;

    @property (nonatomic) int numLikesPerformed;
    @property (nonatomic) int numLikesReceived;
@end

@implementation LikeRatioGraph

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
    self.backgroundColor = [UIColor whiteColor];
    
    [self setupCircleChart];
    
    float totalHeight = (CIRCLE_GRAPH_DIAMETER + CIRCLE_GRAPH_PAD * 2);
    float labelsHeight = 40;
    CGRect labelsRect = CGRectMake(0,
                                   (totalHeight - labelsHeight) / 2,
                                   CARD_WIDTH / 3,
                                   labelsHeight);
    NSArray* leftLabels = [self labelPairInRect:labelsRect
                                        topText:@"1504" topFontSize:28
                                     bottomText:@"You've Liked" bottomFontSize:18];
    self.youveLikedLabelTop = leftLabels[0];
    self.youveLikedLabelBottom = leftLabels[1];
    
    labelsRect = CGRectOffset(labelsRect, CARD_WIDTH / 3, 0);
    NSArray* middleLabels = [self labelPairInRect:labelsRect
                                        topText:@"Like Ratio" topFontSize:28
                                     bottomText:@"60%" bottomFontSize:24];
    self.likeRationLabelTop = middleLabels[0];
    self.likeRationLabelBottom = middleLabels[1];
    
    labelsRect = CGRectOffset(labelsRect, CARD_WIDTH / 3, 0);
    NSArray* rightLabels = [self labelPairInRect:labelsRect
                                          topText:@"1504" topFontSize:34
                                       bottomText:@"Been Liked" bottomFontSize:18];
    self.beenLikedLabelTop = rightLabels[0];
    self.beenLikedLabelBottom = rightLabels[1];
}

- (void)setupCircleChart
{
    float totalWidth = CGRectGetWidth(self.frame);
    float totalHeight = CGRectGetHeight(self.frame);
    CGRect circleRect = CGRectMake((totalWidth - CIRCLE_GRAPH_DIAMETER) / 2,
                                   (totalHeight - CIRCLE_GRAPH_DIAMETER) / 2,
                                   CIRCLE_GRAPH_DIAMETER, CIRCLE_GRAPH_DIAMETER);
    self.circularChart = [[CircularChart alloc] initWithFrame:circleRect];

    [self addSubview:self.circularChart];
}

//Return value is an array with two UILabels: @[topLabel, bottomLabel]
- (NSArray*)labelPairInRect:(CGRect)frame
                    topText:(NSString*)topString topFontSize:(float)topFontSize
                 bottomText:(NSString*)bottomString bottomFontSize:(float)bottomFontSize
{
    CGRect topRect = CGRectMake(frame.origin.x,
                                frame.origin.y,
                                frame.size.width,
                                frame.size.height / 3 * 2);
    CGRect bottomRect =  CGRectMake(frame.origin.x,
                                    CGRectGetMaxY(topRect),
                                    frame.size.width,
                                    frame.size.height / 3);
    UILabel* topLabel = [self labelInRect:topRect withText:topString color:[UIColor blackColor] fontSize:topFontSize];
    UILabel* bottomLabel = [self labelInRect:bottomRect withText:bottomString color:GRAY_2 fontSize:bottomFontSize];
    
    return @[topLabel, bottomLabel];
}

- (UILabel*)labelInRect:(CGRect)frame withText:(NSString*)text color:(UIColor*)color fontSize:(float)fontSize
{
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    
    label.text = text;
    label.textColor = color;
    label.font = [UIFont fontWithName:MAIN_FONT size:fontSize / 2]; //Convert from PSD size
    label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:label];
    
    return label;
}

#pragma mark Data Input

- (void)setNumLikes:(int)likes andTimesBeenLiked:(int)liked
{
    float likePercent = (float)liked / (float)likes;
    if (likes == 0) {
        likePercent = 0;
    }
    
    self.youveLikedLabelTop.text = [NSString stringWithFormat:@"%i", likes];
    self.beenLikedLabelTop.text = [NSString stringWithFormat:@"%i", liked];
    self.likeRationLabelBottom.text = [NSString stringWithFormat:@"%.0f%%", likePercent * 100];

    self.circularChart.progress = likePercent;
    
    self.numLikesReceived = liked;
    self.numLikesPerformed = likes;
}

- (void)animate
{
    [self setNumLikes:self.numLikesPerformed andTimesBeenLiked:self.numLikesReceived];
}

@end
