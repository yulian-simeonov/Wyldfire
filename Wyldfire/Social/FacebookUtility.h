//
//  FacebookUtility.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/19/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FACEBOOK_EMAIL_NONEXISTENT @"kFACEBOOK_EMAIL_NONEXISTENT"
#define ALBUM_ID_PHOTOS_OF_YOU @"kALBUM_ID_PHOTOS_OF_YOU"

@interface FacebookUtility : NSObject

//Login
+ (void)handleAuthError:(NSError *)error;

//Account
+ (void)getAccount:(SuccessBlock)success failure:(FailureBlock)failure;


//Pictures
+ (void)getAlbums:(SuccessBlock)success failure:(FailureBlock)failure;
+ (void)getPhotos:(NSString*)album page:(int)page success:(void (^)(NSString* next, NSArray* list))success failure:(FailureBlock)failure;


//Friends
+ (void)getFriends:(SuccessBlock)success failure:(FailureBlock)failure;
+ (void)getFriendsOfGender:(BOOL)searchMale success:(SuccessBlock)success failure:(FailureBlock)failure;
+ (void)getMutualFriends:(long long)facebookID success:(SuccessBlock)success failure:(FailureBlock)failure;

//User Info
+ (void)getUserInfo:(long long)facebookID success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
