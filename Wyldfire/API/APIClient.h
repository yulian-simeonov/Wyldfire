//
//  APIClient.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/12/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Crashlytics/Crashlytics.h>

#import "AFNetworking.h"
#import "CoreData.h"

#import "NSString+util.h"
#import "GVUserDefaults+WF.h"

#import "FacebookUtility.h"

#import "Account.h"
#import "Stats.h"

#import "DBAccount+util.h"
#import "Message+util.h"

#import "UnderReViewController.h"
#import "WebViewViewController.h"

@interface APIClient : AFHTTPClient

@property (nonatomic) BOOL loggedIn;
@property (strong, nonatomic) FBSession *session;
@property (strong, nonatomic) NSString *browseToken;

+ (instancetype)sharedClient;

// Invite
- (void)checkGeofenceWithSuccess:(GenericBlock)success andFailure:(FailureBlock)failure;
- (void)checkInviteCode:(NSString*)code success:(GenericBlock)success failure:(void (^)(NSString* reason))failure;
- (void)getInviteCode:(StringBlock)success failure:(GenericBlock)failure;
- (void)getUnredeemedCode:(StringBlock)success failure:(GenericBlock)failure;

//Management
- (void)refresh;
- (void)checkFacebookStatus:(GenericBlock)success;
- (void)clearQueue;
- (BOOL)connectedViaWifi;
- (BOOL)online;
- (void)getStats:(void (^)(Stats* stats))callback;
- (NSString*)facebookToken;
- (void)facebookLogin:(UIViewController*)viewController successBlock:(GenericBlock)success failureBlock:(GenericBlock)failure;
- (void)getAccount:(void (^)(Account *account))success failure:(GenericBlock)failure;
- (void)deleteAccount:(GenericBlock)success failure:(GenericBlock)failure;
- (void)getUserAccount:(NSString*)wyldfireID obj:(Account*)account success:(void (^)(Account *account, NSDictionary* json))success failure:(GenericBlock)failure;
- (void)updateAccountField:(NSString*)field value:(id)value notify:(BOOL)notify success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)updateAccount:(NSDictionary*)params notify:(BOOL)notify success:(GenericBlock)success failure:(GenericBlock)failure;

//Images
- (void)uploadImage:(UIImage*)image type:(NSInteger)type success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)setImageFromURL:(NSString*)url type:(NSInteger)type success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)downloadImage:(NSString*)url success:(ImageSuccessBlock)success failure:(FailureBlock)failure;
- (void)getAccountImageOfType:(int)type success:(ImageSuccessBlock)success failure:(FailureBlock)failure;
- (void)getAccountImageOfType:(int)type account:(NSString*)account success:(ImageSuccessBlock)success failure:(FailureBlock)failure;
- (void)getImageForPath:(NSString*)path success:(ImageSuccessBlock)success failure:(FailureBlock)failure;
- (void)getImageForPath:(NSString*)path account:(NSString*)account success:(ImageSuccessBlock)success failure:(FailureBlock)failure;

//Sign Up Flow
- (void)nextActionAfterLogin:(UIViewController*)viewController;
- (void)addAccount:(GenericBlock)success failure:(FailureBlock)failure;

//Location
- (void)putLocation:(CLLocation*)location success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)getNearbyAccounts:(void (^)(NSArray* accounts))success failure:(GenericBlock)failure;
- (void)getTrendingForGenderString:(NSString*)genderString success:(void (^)(NSArray* accounts))success failure:(GenericBlock)failure;

//To be used by Social Account
- (void)getJSON:(NSString *)url method:(NSString*)method params:(NSDictionary*)params headers:(NSDictionary*)headers success:(SuccessBlock)success failure:(JSONFailureBlock)failure;

//Connections
- (void)likeUser:(Account*)userAccount
         success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)burnUser:(Account*)userAccount
         success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)passUser:(Account*)userAccount
         success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)hintUser:(Account*)userAccount
         success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)matchUser:(Account*)userAccount
         success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)viewUser:(Account*)userAccount
         success:(GenericBlock)success failure:(GenericBlock)failure;


- (void)checkIfLikedbyUser:(Account*)userAccount
                   success:(void (^)(BOOL connectionExists))success failure:(GenericBlock)failure;

- (void)checkIfHintedbyUser:(Account*)userAccount
                    success:(void (^)(BOOL connectionExists))success failure:(GenericBlock)failure;

//Blackbook
- (void)shareContactInfoWithAccount:(Account*)account success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)getBlackbook:(void (^)(NSArray* accounts))success;
- (void)storeBlackbookContacts:(NSArray*)accounts notify:(BOOL)notify;

//Matches
- (void)storePendingMatches;
- (void)getPendingMatches:(void (^)(NSArray* matches))success;
- (void)storePendingMatches:(NSArray*)matches;
//Retrieval methods in DBAccount+util.h

//Messages
- (void)putMessage:(NSString*)message toID:(NSString*)toID success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)putMessageImage:(UIImage*)image text:(NSString*)text toID:(NSString*)toID success:(GenericBlock)success failure:(GenericBlock)failure;
- (void)downloadNewMessages;
- (void)downloadMessages:(NSString*)path notify:(BOOL)notify finished:(GenericBlock)finished;
//Retrieval methods in Message+util.h


//Hints
- (void)checkHintsUsedInLast24Hours;

//Report User
- (void)reportUser:(Account*)userAccount success:(GenericBlock)success failure:(GenericBlock)failure;

//Cleanup
- (void)checkLocalAccountStatusesWithServer;

@end
