//
//  GVUserDefaults+WF.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/14/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "GVUserDefaults+WF.h"

@implementation GVUserDefaults (WF)

@dynamic name;
@dynamic email;
@dynamic facebookID;
@dynamic hasFinishedSetup;
@dynamic settingEnabledNotifications;
@dynamic settingVibrateForChat;
@dynamic settingInterestedInWomen;
@dynamic settingInterestedInMen;
@dynamic settingMatchable;
@dynamic settingSearchRadius;
@dynamic settingTrendingRadius;
@dynamic settingMinAge;
@dynamic settingMaxAge;

//First View
@dynamic firstViewTrending;
@dynamic firstViewProfile;
@dynamic firstEditProfile;
@dynamic firstProfileMatchesByDay;
@dynamic firstSwipeLeft;
@dynamic firstSwipeRight;
@dynamic firstChat;
@dynamic firstViewMatch;
@dynamic hasViewedKiip;
@dynamic hasBurnedMatch;

//Publicly visible
@dynamic displayEmail;
@dynamic phoneNumber;

@dynamic hintsToday;
@dynamic lastMatchMtimeCheck;
@dynamic lastStatsMtimeCheck;
@dynamic lastBlackbookMtimeCheck;

//Blackbook
@dynamic unseenContacts;

//Kiip
@dynamic kiipRewardsRedeemed;

- (NSDictionary *)setupDefaults
{
    return @{
             @"settingEnabledNotifications" :   @(YES),
             @"settingVibrateForChat"       :   @(YES),
             @"settingMatchable"            :   @(YES),
             @"settingSearchRadius"         :   @(50),
             @"settingTrendingRadius"       :   @(75),
             @"settingMinAge"               :   @(18),
             @"settingMaxAge"               :   @(35),
             @"lastMessageMtimeCheck"       :   @(0),
             @"lastMatchMtimeCheck"         :   @(0)
            };
}

- (void)updateSettings:(NSDictionary*)json
{
    NSDictionary* map = @{ @"notifications0"  : @"settingEnabledNotifications",
                           @"vibrations0"     : @"settingVibrateForChat",
                           @"matchable0"      : @"settingMatchable",
                           @"men0"            : @"settingInterestedInMen",
                           @"women0"          : @"settingInterestedInWomen",
                           @"age0"            : @"settingMinAge",
                           @"age1"            : @"settingMaxAge",
                           @"distance0"       : @"settingSearchRadius",
                           @"trending_distance0" : @"settingTrendingRadius"};
    
    for (NSString* key in map.allKeys) {
        if (json[key] != nil) {
            [self setValue:json[key] forKey:map[key]];
        }
    }
}

- (NSString *)transformKey:(NSString *)key {
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[key substringToIndex:1] uppercaseString]];
    return [NSString stringWithFormat:@"NSUserDefault%@", key];
}

- (BOOL)hasConnected
{
    return (self.facebookID > 0) && (self.email.length > 0);
}

//Blackbook
- (void)addNotebookUnseenAccount:(NSString*)accountID
{
    NSArray* unseenContacts = self.unseenContacts;
    if (!unseenContacts) {
        unseenContacts = @[];
    }
    NSMutableArray* revised = [unseenContacts mutableCopy];
    [revised addObject:accountID];
    
    self.unseenContacts = revised;
}

- (void)clearNotebookUnseenAccounts
{
    self.unseenContacts= @[];
}

//Kiip
- (void)addKiipMomentRewarded:(NSString*)rewarded
{
    NSArray* rewards = self.kiipRewardsRedeemed;
    if (!rewards) {
        rewards = @[];
    }
    NSMutableArray* revised = [rewards mutableCopy];
    [revised addObject:rewarded];
    
    self.kiipRewardsRedeemed = revised;
}

- (void)clearKiipMomentsRewarded
{
    self.kiipRewardsRedeemed = @[];
}

- (BOOL)wasKiipMomentAlreadyRewarded:(NSString*)reward
{
    NSArray* rewards = self.kiipRewardsRedeemed;
    if (!rewards) {
        rewards = @[];
    }
    return [rewards containsObject:reward];
}

@end
