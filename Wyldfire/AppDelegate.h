//
//  AppDelegate.h
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/9/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "APIClient.h"
#import <AdSupport/AdSupport.h>
#import <FacebookSDK/FBAppCall.h>
#import <FacebookSDK/FBAppEvents.h>
#import <KiipSDK/KiipSDK.h>
#import <Appsee/Appsee.h>
#import <Crashlytics/Crashlytics.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate, KiipDelegate>
@property (strong, nonatomic) UIWindow *window;

@end
