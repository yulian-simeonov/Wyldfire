//
//  ShiftedTextField.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "ShiftedTextField.h"

@implementation ShiftedTextField

- (CGRect) rightViewRectForBounds:(CGRect)bounds {
    
    CGRect textRect = [super rightViewRectForBounds:bounds];
    textRect.origin.x -= 10;
    return textRect;
}

@end
