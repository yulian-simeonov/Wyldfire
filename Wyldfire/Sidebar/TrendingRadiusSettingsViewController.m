//
//  TrendingRadiusSettingsViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/13/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "TrendingRadiusSettingsViewController.h"

@implementation TrendingRadiusSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.configDictionary = @{@"LabelName" : @"Radius:",
                              @"ScreenName" : @"Trending Radius",
                              @"minValue" : @(5),
                              @"maxValue" : @(100),
                              @"currentValue" : @([GVUserDefaults standardUserDefaults].settingTrendingRadius)};
}

- (void)onRange:(UISlider*)slider
{
    [GVUserDefaults standardUserDefaults].settingTrendingRadius = (int)slider.value;
    
    self.slider2Label.text = [NSString stringWithFormat:@"%i Miles", (int)slider.value];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [[APIClient sharedClient] updateAccount: @{ @"trending_distance0": @(self.slider.value) } notify:YES success:nil failure:nil];
}

@end
