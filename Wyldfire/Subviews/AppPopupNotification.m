//
//  AppPopupNotification.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "AppPopupNotification.h"

@interface AppPopupNotification ()
    // Actions
    @property (nonatomic, strong) NSString* action;
    @property (nonatomic, strong) Account* account;
@end

@implementation AppPopupNotification

- (void)performAction
{
    NSString* name;
    if ([self.action isEqualToString:NOTIFICATION_ACTION_MATCHES]) {
        name = @"Match";
    } else if ([self.action isEqualToString:NOTIFICATION_ACTION_CHAT]) {
        name = @"Messages";
    } else if ([self.action isEqualToString:NOTIFICATION_ACTION_BLACKBOOK]) {
        name = @"BlackBook";
    }

    [WFCore showViewController:self.navController.topViewController
                          name:name
                          mode:@"push"
                        params:@{@"account" : self.account}];
    
    [super performAction];
}

- (void)addImages
{
    Account* me = [WFCore get].accountStructure;
    Account* you = self.account;
    
    CGFloat totalWidth = 45;
    CGRect rect = CGRectMake(218,
                             (self.height - totalWidth) / 2,
                             totalWidth,
                             totalWidth);
    
    [self addImage:me.avatarPhoto  inRect:rect];
    [self addImage:you.avatarPhoto inRect:CGRectOffset(rect, 37, 0)];
}

- (void)addImage:(UIImage*)image inRect:(CGRect)rect
{
    //Image White Outline
    UIImageView *outline = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar_eclipse"]];
    outline.frame = rect;
    [self addSubview:outline];
    
    //Image
    UIImageView* avatar = [[UIImageView alloc] initWithImage:image];
    
    avatar.frame = CGRectInset(outline.frame, 2, 2);
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.layer.cornerRadius = avatar.frame.size.width/2;
    avatar.layer.masksToBounds = YES;
    [self addSubview:avatar];
}

+ (instancetype)showPopUpWithTitle:(NSString*)title
                  subtitle:(NSString*)subtitle
                    action:(NSString*)action
                   account:(Account*)account
    inNavigationController:(UINavigationController*)nav
{
    AppPopupNotification* popup = [self showPopUpWithTitle:title
                                                  subtitle:subtitle
                                    inNavigationController:nav];
    popup.action = action;
    popup.account = account;
    [popup addImages];
    
    return popup;
}

@end
