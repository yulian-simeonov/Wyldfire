//
//  Facebook.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/17/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>

@interface Facebook : SocialAccount

- (void)getFriendsOfGender:(BOOL)isMale success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
