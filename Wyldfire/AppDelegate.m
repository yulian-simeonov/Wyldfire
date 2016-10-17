//
//  AppDelegate.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/9/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "AppDelegate.h"
#import "CoreData.h"
#import "APIClient.h"



@interface AppDelegate()
    @property (nonatomic, strong) NSTimer* refreshDataTimer;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // for setting version number
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"appVersion"];
    
    [Appsee start:@"1951966005a04312a7d64fd2b53e56c2"];
    [Crashlytics startWithAPIKey:@"ae651a7b2567e89320763499ab6e2f1956cbedfb"];
    
    [[WFCore get] configure];
    [CoreData configure];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound];

    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [WFCore get].deviceToken = [[NSString alloc] initWithData:deviceToken encoding:NSUTF8StringEncoding];
    NSLog(@"device token: %@", deviceToken);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"APN: %@", userInfo);
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[APIClient sharedClient].session];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self stopRefreshing];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self stopRefreshing];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ENTERED_FOREGROUND object:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActiveWithSession:[APIClient sharedClient].session];
    
    [self startRefreshing];
    [[APIClient sharedClient] checkHintsUsedInLast24Hours];
    [[APIClient sharedClient] checkLocalAccountStatusesWithServer];
}

- (void)startRefreshing
{
    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    self.refreshDataTimer = timer;
}

- (void)stopRefreshing
{
    [self.refreshDataTimer invalidate];
}

- (void)refresh
{
    [[APIClient sharedClient] refresh];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self stopRefreshing];
    [[APIClient sharedClient].session close];
}

@end
