//
//  DayBubbleView.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UILabel+util.h"

@interface DayBubbleView : UIView


@property (nonatomic, strong) NSString* title;
@property (nonatomic) int views;


- (id)initWithFrame:(CGRect)frame title:(NSString*)title;

@end
