//
//  ProfileViewsGraphView.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UILabel+util.h"
#import "DayBubbleView.h"

@interface ProfileViewsGraphView : UIView

@property (nonatomic, strong) NSArray* viewCounts;
@property (nonatomic, strong) NSArray* dayTitles;

- (void)setViewCounts:(NSArray*)viewCounts withDayTitles:(NSArray*)dayTitles;
- (void)animate;

@end
