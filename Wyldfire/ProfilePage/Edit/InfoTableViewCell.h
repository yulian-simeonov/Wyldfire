//
//  InfoTableViewCell.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "ECPhoneNumberFormatter.h"
#import "NSString+util.h"

@interface InfoTableViewCell : UITableViewCell

@property (nonatomic, strong) NSString* defaultsKey;
@property (nonatomic, strong) UIImageView* infoImageView;
@property (nonatomic, strong) UITextField* textField;

@end
