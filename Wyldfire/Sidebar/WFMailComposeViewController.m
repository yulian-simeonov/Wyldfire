//
//  WFMailComposeViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/18/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "WFMailComposeViewController.h"

@interface WFMailComposeViewController ()

@end

@implementation WFMailComposeViewController

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

-(UIViewController *)childViewControllerForStatusBarStyle
{
    return nil;
}

@end
