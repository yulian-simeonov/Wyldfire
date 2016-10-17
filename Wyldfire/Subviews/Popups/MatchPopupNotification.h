//
//  MatchPopupNotification.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "AppPopupNotification.h"

@interface MatchPopupNotification : AppPopupNotification

+ (instancetype)showMatchPopup:(Account*)account
    inNavigationController:(UINavigationController*)nav;

@end
