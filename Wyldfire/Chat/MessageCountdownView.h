//
//  MessageCountdownView.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/20/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageCountdownView : UIView

@property (nonatomic) int number;

- (id)initWithFrame:(CGRect)frame sent:(BOOL)sent number:(int)number;

@end
