//
//  NoStatusBarImagePickerController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/31/14.
//  Copyright (c) 2014 Wyldfire. All rights reserved.
//

#import "NoStatusBarImagePickerController.h"

@implementation NoStatusBarImagePickerController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return nil;
}

@end
