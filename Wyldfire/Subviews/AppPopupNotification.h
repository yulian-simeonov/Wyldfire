//
//  AppPopupNotification.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopupNotification.h"

@interface AppPopupNotification : PopupNotification

+ (instancetype)showPopUpWithTitle:(NSString*)title
                  subtitle:(NSString*)subtitle
                    action:(NSString*)action
                   account:(Account*)account
    inNavigationController:(UINavigationController*)nav;

@end
