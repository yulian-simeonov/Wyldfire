//
//  UILabel+util.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (util)

+ (UILabel*)labelInRect:(CGRect)frame withText:(NSString*)text color:(UIColor*)color fontSize:(float)fontSize;

@end
