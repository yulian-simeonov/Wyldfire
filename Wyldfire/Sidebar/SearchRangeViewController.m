//
//  SearchRangeViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/13/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "SearchRangeViewController.h"

@implementation SearchRangeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.configDictionary = @{@"LabelName" : @"Radius:",
                              @"ScreenName" : @"Search Radius",
                              @"minValue" : @(5),
                              @"maxValue" : @(100),
                              @"currentValue" : @([GVUserDefaults standardUserDefaults].settingSearchRadius)};
}

- (void)onRange:(UISlider*)slider
{
    self.slider2Label.text = [NSString stringWithFormat:@"%i  Miles", (int)slider.value];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [GVUserDefaults standardUserDefaults].settingSearchRadius = (int)self.slider.value;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_SETTINGS object:self];
    
    [[APIClient sharedClient] updateAccount:@{ @"distance0": @(self.slider.value) } notify:YES success:nil failure:nil];
}

@end
