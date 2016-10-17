//
//  ChatPopupNotification.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "ChatPopupNotification.h"

@implementation ChatPopupNotification

+ (instancetype)showChatPopup:(Account*)account
        inNavigationController:(UINavigationController*)nav
{
    // Test if already in the chat window with that user
    if ([nav.topViewController isKindOfClass:[MessagesViewController class]]) {
        MessagesViewController* vc = (MessagesViewController*)nav.topViewController;
        if ([vc.account.accountID isEqualToString:account.accountID]) {
            return nil;
        }
    }
    DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:account.accountID];
    if ((!dbAccount) || (![dbAccount.inChat boolValue])){
        return nil;
    }
    
    NSString* titlePhrase = @"Psst! New message";
    NSString* subtitlePhrase = @"%@ wrote you a message!";
    
    NSString* title = [NSString stringWithFormat:titlePhrase, account.alias];
    NSString* subtitle = [NSString stringWithFormat:subtitlePhrase, account.alias];
    
    ChatPopupNotification* popup = [self showPopUpWithTitle:title
                                                    subtitle:subtitle
                                                      action:NOTIFICATION_ACTION_CHAT
                                                     account:account
                                      inNavigationController:nav];
    
    if ([GVUserDefaults standardUserDefaults].settingVibrateForChat) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
    return popup;
}

@end
