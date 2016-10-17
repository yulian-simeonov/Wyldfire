//
//  UIActionSheet+util.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/21/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "UIActionSheet+util.h"

@implementation UIActionSheet (util)

- (void) styleWithTintColor:(UIColor*)tintColor {
    NSArray *actionSheetButtons = self.subviews;
    for (int i = 0; i < [actionSheetButtons count]; i++) {
        UIView *view = (UIView*)[actionSheetButtons objectAtIndex:i];
        if([view isKindOfClass:[UIButton class]]){
            UIButton *btn = (UIButton*)view;
            [btn setTitleColor:tintColor forState:UIControlStateNormal];
            
            if ( i == [actionSheetButtons count] - 1) {
                //Cancel Button
                [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            }
        }
    }
}

@end
