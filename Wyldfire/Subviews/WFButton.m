//
//  WFButton.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/31/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "WFButton.h"

@interface WFButton ()
@property (nonatomic) BOOL highlightOn;
@end

@implementation WFButton

- (void)setHighlighted:(BOOL)highlighted
{
    if (self.highlightOn != highlighted) {
        UIColor* temp = self.currentTitleColor;
        [self setTitleColor:self.backgroundColor forState:UIControlStateNormal];
        [self setBackgroundColor:temp];
    }
    
    if (highlighted) {
        [self.hintImageView setImage:[UIImage imageNamed:@"hintHighlighted"]];
    } else {
        [self.hintImageView setImage:[UIImage imageNamed:@"hint"]];
    }
    
    self.highlightOn = highlighted;
}

@end
