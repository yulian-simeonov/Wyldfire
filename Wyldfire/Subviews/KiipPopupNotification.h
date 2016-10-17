//
//  KiipPopupNotification.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/8/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopupNotification.h"
#import "KiipTourViewController.h"

@interface KiipPopupNotification : PopupNotification

+(instancetype)showKiipPopUpWithPoptart:(KPPoptart *)poptart title:(NSString*)title subtitle:(NSString*)subtitle inNavigationController:(UINavigationController *)nav;

@end
