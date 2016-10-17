//
//  LocationServicesViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/3/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "LocationServicesViewController.h"

@interface LocationServicesViewController ()

@end

@implementation LocationServicesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupImageView];
    [self subscribeToNotifications];
}

- (void)setupImageView
{
    NSString* imgName = TALL_SCREEN ? @"location.jpg" : @"locationi4.jpg";
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
    if ([self.view locationServicesEnabled]) {
        [[WFCore get] putLocation:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_SETTINGS object:nil];
             [self.navigationController popViewControllerAnimated:YES];
        } failure:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
