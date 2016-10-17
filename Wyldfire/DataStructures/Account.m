//
//  Account.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/14/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "Account.h"

@implementation Account

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.age = 0;
        self.icons = @[];
        self.isOk = YES;
        self.profilePhotos = [@{} mutableCopy];
    }
    return self;
}

- (NSDictionary*)dictionaryRepresentation
{
    return @{@"facebook_id"     :   @(self.facebookID),
             @"facebook_email"  :   self.email ?: @"",
             @"name"            :   self.name ?: @"",
             @"alias"           :   self.alias ?: @"",
             @"birthday"        :   self.birthday ?: @"",
             @"gender"          :   [self genderString],
             @"email"           :   self.email ?: @""};
}

- (NSString*)genderString
{
    return self.isMale ? @"m" : @"f";
}

+ (instancetype)accountFromAPICall:(id)user
{
    Account* account = [self new];
    return [self accountFromAPICall:user usingObject:account];
}

+ (instancetype)accountFromAPICall:(id)user usingObject:(Account*)account
{
    account.isOk        = [[WFCore toString:user name:@"status"] isEqualToString:@"ok"];
    account.age         = [WFCore toNumber:user name:@"age"];
    account.alias       = [WFCore toString:user name:@"alias"];
    account.email       = [WFCore toString:user name:@"facebook_email"];
    account.facebookEmail = [WFCore toString:user name:@"facebook_email"];
    account.facebookID  = [WFCore toNumber:user name:@"facebook_id"];
    account.accountID   = [WFCore toString:user name:@"id"];
    account.name        = [WFCore toString:user name:@"name"];
    account.distance    = [WFCore toNumber:user name:@"distance"] * 0.621371;
    account.phone       = [WFCore toString:user name:@"phone"];
    account.deviceID    = [WFCore toString:user name:@"device_id"];
    account.gender      = [WFCore toString:user name:@"gender"];
    account.isMale      = [account.gender isEqualToString:@"m"];
    account.instagramID = [WFCore toString:user name:@"instagram_id"];
    account.instagramUsername = [WFCore toString:user name:@"instagram_username"];
    account.hasFeather  = YES;
    account.icons       = [WFCore toArray:user name:@"icons"];

    return account;
}

+ (instancetype)accountFromFBUser:(id)user
{
    Account* account = [WFCore get].accountStructure;
    
    if (!account) account = [self new];
    account.facebookID      = [WFCore toNumber:user name:@"id"];
    account.facebookEmail   = [WFCore toString:user name:@"email"];
    account.email           = [WFCore toString:user name:@"email"];
    account.name            = [WFCore toString:user name:@"name"];
    account.alias           = [WFCore toString:user name:@"alias"];
    account.birthday        = [WFCore toString:user name:@"birthday"];
    account.facebookIcon    = [WFCore toDictionaryString:[WFCore toDictionary:user name:@"picture"] name:@"data" field:@"url"];
    account.gender          = [WFCore toString:user name:@"gender"];
    account.isMale          = ![account.gender isEqualToString:@"female"];
    account.hasFeather      = NO;

    // Alias is required
    NSArray *alias = [[account.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@" "];
    account.alias = alias.count > 0 ? alias[0] : account.name;
    
    if (![account.birthday isEqualToString:@""]) {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/dd/yyyy"];
        account.birthDate = [dateFormat dateFromString:account.birthday];
        NSDate* now = [NSDate date];
        NSDateComponents* ageComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:account.birthDate toDate:now options:0];
        account.age = (int)[ageComponents year];
        account.birthday = [dateFormat stringFromDate:account.birthDate];
    }
    
    if ([account.facebookIcon isEqualToString:@""]) {
        account.facebookIcon = nil;
        NSLog(@"no FB icon: %@", user);
    }
    
    if ([GVUserDefaults standardUserDefaults].displayEmail.length == 0) {
        [GVUserDefaults standardUserDefaults].displayEmail = account.email;
    }
    return account;
}

- (NSString*)keyForType:(NSInteger)type
{
    return [NSString stringWithFormat:@"%i", (int)type];
}

- (void)setImage:(UIImage*)image forType:(NSInteger)type
{
    if(type == 1) {
        self.avatarPhoto = image;
    } else if (type == 0) {
        self.showcasePhoto = image;
    } else {
        [self.profilePhotos setValue:image forKey:[self keyForType:type]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_ACCOUNT_PHOTOS object:self userInfo:@{@"account" : self}];
}

- (UIImage*)profileImageForType:(NSInteger)type
{
    return self.profilePhotos[[self keyForType:type]];
}

- (NSArray*)allProfileImages
{
    NSArray * sortedKeys = [[self.profilePhotos allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    
    return [self.profilePhotos objectsForKeys:sortedKeys notFoundMarker:[NSNull null]];
}


@end
