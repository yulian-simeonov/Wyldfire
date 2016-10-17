//
//  Stats.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/21/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Stats : NSObject

//view counts for the last 5 days.  number of total likes and total been liked.  matches for past 12 days, with indication of which days the showcase photo was changed

//Number of likes
@property (nonatomic) int likesPerformed;
@property (nonatomic) int likesReceived;
@property (nonatomic, strong) NSArray* likeCounts;

//View Count Graph
@property (nonatomic, strong) NSArray* viewCounts;
@property (nonatomic, strong) NSArray* daysViewed;

//Match Bar Graph
@property (nonatomic, strong) NSArray* daysMatched;
@property (nonatomic, strong) NSArray* matches;
@property (nonatomic, strong) NSArray* daysChangedImage;

// Invitation
@property (nonatomic) int sentInvites;
@property (nonatomic) int maxInvites;

- (id)init;
+ (instancetype)statsFromAPICall:(id)json;

@end
