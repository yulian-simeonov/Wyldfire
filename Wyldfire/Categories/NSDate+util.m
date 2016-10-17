//
//  NSDate+util.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 4/9/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "NSDate+util.h"

@implementation NSDate (util)

- (NSDate *) toLocalTime
{
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: self];
    return [NSDate dateWithTimeInterval: seconds sinceDate: self];
}

- (NSDateComponents*)components
{
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorianCalendar components: NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit |NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    return components;
}

@end
