//
//  ContactPopupNotification.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "ContactPopupNotification.h"

@implementation ContactPopupNotification

+ (instancetype)showContactPopup:(Account*)account
        inNavigationController:(UINavigationController*)nav
{
    NSString* titlePhrase = @"Nice! Contact shared";
    NSString* subtitlePhrase = @"%@ just sent you their contact";
    
    NSString* title = [NSString stringWithFormat:titlePhrase, account.alias];
    NSString* subtitle = [NSString stringWithFormat:subtitlePhrase, account.alias];
    
    ContactPopupNotification* popup = [self showPopUpWithTitle:title
                                                    subtitle:subtitle
                                                      action:NOTIFICATION_ACTION_BLACKBOOK
                                                     account:account
                                      inNavigationController:nav];
    return popup;
}

@end
