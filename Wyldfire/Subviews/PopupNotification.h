//
//  PopupNotification.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/7/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TITLE_INDENT 30
#define TITLE_FONTSIZE 18
#define SUBTITLE_FONTSIZE 12

@interface PopupNotification : UIView

@property (nonatomic, strong) UILabel* label;
@property (nonatomic, strong) UILabel* subLabel;

+ (instancetype)showPopUpWithTitle:(NSString*)title
                  subtitle:(NSString*)subtitle
    inNavigationController:(UINavigationController*)nav;

- (void)style;
- (void)performAction;
- (UINavigationController*)navController;

@end
