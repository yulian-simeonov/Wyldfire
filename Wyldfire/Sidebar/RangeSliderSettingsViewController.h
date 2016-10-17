//
//  RangeSliderSettingsViewController.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/13/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CERangeSlider.h"
#import "GVUserDefaults+WF.h"

@interface RangeSliderSettingsViewController : ViewController

@property (nonatomic, strong) UILabel* sliderLabel;
@property (nonatomic, strong) UILabel* slider2Label;
@property (nonatomic, strong) UISlider* slider;

@property (nonatomic, strong) NSDictionary* configDictionary;

@end
