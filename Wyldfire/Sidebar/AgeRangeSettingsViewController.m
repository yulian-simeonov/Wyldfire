//
//  AgeRangeSettingsViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/13/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "AgeRangeSettingsViewController.h"

@implementation AgeRangeSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.configDictionary = @{@"LabelName" : @"Range:",
                              @"ScreenName" : @"Age Range",
                              @"DoubleSlider" : @"",
                              @"minValue" : @(18),
                              @"maxValue" : @(50),
                              @"lowerValue" : @([GVUserDefaults standardUserDefaults].settingMinAge),
                              @"upperValue" : @([GVUserDefaults standardUserDefaults].settingMaxAge)};
}

- (void)onRange:(RangeSlider*)slider
{
    int topValue = (int)slider.value1;
    NSString* topString;
    if (topValue < 50) {
        topString = [NSString stringWithFormat:@"%i", topValue];
    } else {
        topString = @"50+";
    }
    
    self.slider2Label.text = [NSString stringWithFormat:@"%i - %@",
                              (int)slider.value0,
                              topString];
}

- (void)viewDidDisappear:(BOOL)animated
{
    RangeSlider* slider = (RangeSlider*)self.slider;
    
    [GVUserDefaults standardUserDefaults].settingMinAge = (int)slider.value0;
    [GVUserDefaults standardUserDefaults].settingMaxAge = (int)slider.value1;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_SETTINGS object:self];
    
    int age0 = (int)((RangeSlider*)self.slider).value0;
    int age1 = (int)((RangeSlider*)self.slider).value1;
    
    [[APIClient sharedClient] updateAccount:@{ @"age1": @(age1), @"age0": @(age0) } notify:YES success:nil failure:nil];
}

@end
