//
//  ContactPopupNotification.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "AppPopupNotification.h"

@interface ContactPopupNotification : AppPopupNotification

+ (instancetype)showContactPopup:(Account*)account
        inNavigationController:(UINavigationController*)nav;

@end
