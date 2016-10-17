//
//  RangeSliderSettingsViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/13/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "RangeSliderSettingsViewController.h"

@interface RangeSliderSettingsViewController ()
@end

@implementation RangeSliderSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addTable];
    [self addToolbar:@"Range Slider"];
    self.items = [@[@"RangeSlider"] mutableCopy];
    self.table.scrollEnabled = NO;
    self.table.backgroundColor = GRAY_8;
    self.table.contentInset = UIEdgeInsetsMake(68 / 2, 0, 0, 0);
    self.table.rowHeight = 100;
}

- (void)setConfigDictionary:(NSDictionary *)configDictionary
{
    _configDictionary = configDictionary;
    if (configDictionary[@"LabelName"] != nil) {
        self.sliderLabel.text = configDictionary[@"LabelName"];
    }
    if (configDictionary[@"ScreenName"] != nil) {
        self.toolbarTitle.text = configDictionary[@"ScreenName"];self.toolbarTitle.text = configDictionary[@"ScreenName"];
    }
    
    if (configDictionary[@"DoubleSlider"] != nil) {
        CGRect sliderRect = self.slider.frame;
        
        RangeSlider *slider = [[RangeSlider alloc] initWithFrame:sliderRect];
        slider.minValue = [configDictionary[@"minValue"] floatValue];
        slider.maxValue = [configDictionary[@"maxValue"] floatValue];
        slider.minRange = 5;
        slider.value0 = [configDictionary[@"lowerValue"] floatValue];
        slider.value1 = [configDictionary[@"upperValue"] floatValue];
        [slider addTarget:self action:@selector(onRange:) forControlEvents:UIControlEventValueChanged];
        
        [self.slider.superview addSubview:slider];
        [self.slider removeFromSuperview];
        self.slider = (UISlider*)slider;
    } else {
        self.slider.minimumValue = [configDictionary[@"minValue"] floatValue];
        self.slider.maximumValue = [configDictionary[@"maxValue"] floatValue];
        self.slider.value = [configDictionary[@"currentValue"] floatValue];
    }
    [self onRange:self.slider];
}

- (void)onTableCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width / 2, cell.frame.size.height/2)];
    label.textColor = [UIColor blackColor];
    label.text = @"Radius:";
    label.font = [UIFont fontWithName:MAIN_FONT size:17];
    label.textAlignment = NSTextAlignmentRight;
    [cell addSubview:label];
    self.sliderLabel = label;
    
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(10 + cell.frame.size.width / 2, 0, cell.frame.size.width / 2 - 10 , cell.frame.size.height/2)];
    label2.textColor = WYLD_RED;
    label2.text = @"Value";
    label2.font = [UIFont fontWithName:MAIN_FONT size:17];
    label2.textAlignment = NSTextAlignmentLeft;
    [cell addSubview:label2];
    self.slider2Label = label2;
    
    CGRect sliderRect = CGRectMake(24, cell.frame.size.height/2, cell.frame.size.width - 48, cell.frame.size.height/2);
    UISlider* slider = [[UISlider alloc] initWithFrame:sliderRect];
    [slider setThumbImage:[UIImage imageNamed:@"range-handle"] forState:UIControlStateNormal];
    slider.tintColor = WYLD_RED;
    [slider addTarget:self action:@selector(onRange:) forControlEvents:UIControlEventValueChanged];
    [cell addSubview:slider];
    self.slider = slider;
    
    [self setConfigDictionary:self.configDictionary];
}

- (void)onRange:(UISlider*)slider
{
    self.slider2Label.text = [NSString stringWithFormat:@"%i", (int)slider.value];
}

@end
