//
//  SideBarProfileView.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BorderedLabel.h"

@interface SideBarProfileView : UIView

@property (nonatomic, strong) UIImageView* profileImage;
@property (nonatomic, strong) UILabel* profileName;
@property (nonatomic, strong) UILabel* profileLikes;

- (void)animate;

@end
