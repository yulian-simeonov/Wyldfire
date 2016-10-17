//
//  GVUserDefaults+WF.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/14/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "GVUserDefaults.h"
#import "NSDate+util.h"

@interface GVUserDefaults (WF)

@property (nonatomic, weak) NSString* name;
@property (nonatomic, weak) NSString* email;
@property (nonatomic) long long facebookID;

@property (nonatomic) BOOL hasFinishedSetup;
@property (nonatomic) int hintsToday;

@property (nonatomic) long long lastMatchMtimeCheck;
@property (nonatomic) long long lastStatsMtimeCheck;
@property (nonatomic) long long lastBlackbookMtimeCheck;

//First View
@property (nonatomic) BOOL firstViewTrending;
@property (nonatomic) BOOL firstViewProfile;
@property (nonatomic) BOOL firstEditProfile;
@property (nonatomic) BOOL firstProfileMatchesByDay;
@property (nonatomic) BOOL firstSwipeLeft;
@property (nonatomic) BOOL firstSwipeRight;
@property (nonatomic) BOOL firstChat;
@property (nonatomic) BOOL firstViewMatch;
@property (nonatomic) BOOL hasViewedKiip;
@property (nonatomic) BOOL hasBurnedMatch;

//Settings
@property (nonatomic) BOOL settingEnabledNotifications;
@property (nonatomic) BOOL settingVibrateForChat;
@property (nonatomic) BOOL settingInterestedInWomen;
@property (nonatomic) BOOL settingInterestedInMen;
@property (nonatomic) BOOL settingMatchable;
@property (nonatomic)  int settingSearchRadius;
@property (nonatomic)  int settingTrendingRadius;
@property (nonatomic)  int settingMinAge;
@property (nonatomic)  int settingMaxAge;

@property (nonatomic, weak) NSString* displayEmail;
@property (nonatomic, weak) NSString* phoneNumber;

//Kiip
@property (nonatomic) NSArray* kiipRewardsRedeemed;
- (void)addKiipMomentRewarded:(NSString*)rewarded;
- (void)clearKiipMomentsRewarded;
- (BOOL)wasKiipMomentAlreadyRewarded:(NSString*)reward;

//Blackbook
@property (nonatomic) NSArray* unseenContacts;
- (void)addNotebookUnseenAccount:(NSString*)accountID;
- (void)clearNotebookUnseenAccounts;

//Util
- (BOOL)hasConnected;
- (void)updateSettings:(NSDictionary*)json;
@end
