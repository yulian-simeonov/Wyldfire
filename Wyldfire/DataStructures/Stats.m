//
//  Stats.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/21/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "Stats.h"

@implementation Stats

- (id)init
{
    self = [super init];
    self.sentInvites = self.maxInvites = 0;
    self.likesPerformed = self.likesReceived = 0;
    return self;
}

+ (instancetype)statsFromAPICall:(id)json
{
    Stats* stats = [self new];
    
    stats.sentInvites = [WFCore toNumber:json[@"counters"] name:@"sentinvites"];
    stats.maxInvites = [WFCore toNumber:json[@"counters"] name:@"maxinvites"];
    
    stats.likesPerformed = [WFCore toNumber:json[@"counters"] name:@"like0"];
    stats.likesReceived = [WFCore toNumber:json[@"counters"] name:@"like1"];
    
    NSSortDescriptor* descriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    NSArray* daysEnumerated = [json[@"weekly"] sortedArrayUsingDescriptors:@[descriptor]];
    
    NSMutableArray* viewCounts = [NSMutableArray new];
    NSMutableArray* likeCounts = [NSMutableArray new];
    NSMutableArray* daysViewed = [NSMutableArray new];
    NSMutableArray* daysMatched = [NSMutableArray new];
    NSMutableArray* matches = [NSMutableArray new];
    NSMutableArray* daysChangedImage = [NSMutableArray new];
    
    for (int i = 0; i < daysEnumerated.count; i++) {
        NSDictionary* day = daysEnumerated[i];
        NSString* dayTitle = day[@"day"];
        if (dayTitle.length > 1) dayTitle = [dayTitle substringToIndex:1];
        
        if (i < 5) {
            [viewCounts addObject:day[@"v"]];
            [likeCounts addObject:day[@"l"]];
            [daysViewed addObject:dayTitle];
        }
    
        [daysMatched addObject:dayTitle];
        [matches addObject:day[@"m"]];
        [daysChangedImage addObject:day[@"mod"]];
    }
    
    stats.viewCounts = [[viewCounts reverseObjectEnumerator] allObjects];
    stats.daysViewed = [[daysViewed reverseObjectEnumerator] allObjects];
    stats.daysMatched = [[daysMatched reverseObjectEnumerator] allObjects];
    stats.matches = [[matches reverseObjectEnumerator] allObjects];
    stats.daysChangedImage = [[daysChangedImage reverseObjectEnumerator] allObjects];
    stats.likeCounts = [[likeCounts reverseObjectEnumerator] allObjects];
    
    NSLog(@"views=%g, matches=%g, invites=%d/%d, likes=%ld/%ld", [WFCore toNumber:json[@"counters"] name:@"view1"], [WFCore toNumber:json[@"counters"] name:@"match1"], stats.sentInvites, stats.maxInvites, (long)stats.likesReceived, (long)stats.likesPerformed);
    
    return stats;
}

@end
