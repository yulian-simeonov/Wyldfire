//
//  UnderReViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/5/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "UnderReViewController.h"

@interface UnderReViewController ()

@end

@implementation UnderReViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupImageView];
    [self subscribeToNotifications];
}

- (void)setupImageView
{
    NSString* imgName = TALL_SCREEN ? @"underReview" : @"underReviewi4.jpg";
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgName]];
    imgView.frame = self.view.bounds;
    [self.view addSubview:imgView];
}

#pragma mark - Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteredForeground)
                                                 name:NOTIFICATION_ENTERED_FOREGROUND
                                               object:nil];
}

- (void)enteredForeground
{
    if (WFCore.account.isOk) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
