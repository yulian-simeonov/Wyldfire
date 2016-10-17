//
//  NoInternetViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "NoInternetViewController.h"

@interface NoInternetViewController ()
    @property (nonatomic, strong) NSTimer* checkTimer;
@end

static int noInternetPopupCount = 0;

@implementation NoInternetViewController

+ (void)showNoInternetViewControllerInNavController:(UINavigationController*)navigationController
{
    if (noInternetPopupCount == 0) {
        [navigationController pushViewController:[NoInternetViewController new] animated:YES];
    }
}

- (void)viewDidLoad
{
    noInternetPopupCount++;
    [super viewDidLoad];
    
    [self setupImageView];
    [self subscribeToNotifications];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.checkTimer invalidate];
    self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(enteredForeground) userInfo:nil repeats:YES];
}

- (void)setupImageView
{
    NSString* imgName = TALL_SCREEN ? @"noInternet" : @"noInterneti4";
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteredForeground)
                                                 name:NOTIFICATION_INTERNET_STATUS_CHANGED
                                               object:nil];
}

- (void)enteredForeground
{
    if ([APIClient sharedClient].online) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    noInternetPopupCount --;
}

@end
