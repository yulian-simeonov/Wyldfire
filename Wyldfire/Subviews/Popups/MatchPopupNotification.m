//
//  MatchPopupNotification.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "MatchPopupNotification.h"

@implementation MatchPopupNotification

+ (instancetype)showMatchPopup:(Account*)account
inNavigationController:(UINavigationController*)nav
{
    NSString* titlePhrase = @"It's Happening!";
    NSString* subtitlePhrase = @"You and %@ are a match!";
    
    NSString* title = [NSString stringWithFormat:titlePhrase, account.alias];
    NSString* subtitle = [NSString stringWithFormat:subtitlePhrase, account.alias];
    
    MatchPopupNotification* popup = [self showPopUpWithTitle:title
                                                     subtitle:subtitle
                                                       action:NOTIFICATION_ACTION_MATCHES
                                                      account:account
                                       inNavigationController:nav];
    return popup;
}

@end
