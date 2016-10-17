//
//  UILabel+util.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "UILabel+util.h"

@implementation UILabel (util)

+ (UILabel*)labelInRect:(CGRect)frame withText:(NSString*)text color:(UIColor*)color fontSize:(float)fontSize
{
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    
    label.text = text;
    label.textColor = color;
    label.font = [UIFont fontWithName:MAIN_FONT size:fontSize];
    label.textAlignment = NSTextAlignmentCenter;
    
    return label;
}

@end
