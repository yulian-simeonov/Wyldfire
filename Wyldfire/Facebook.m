//
//  Facebook.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/17/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@implementation Facebook

#pragma mark Facebook SDK

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        //
//    }
//    return self;
//}
//



#pragma mark Old Code

- (id)init:(NSString*)name clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret
{
    self = [super init:name clientId:clientId clientSecret:clientSecret];
    self.apiURL = @"https://graph.facebook.com";
    self.cookiesURL = @"https://facebook.com/";
    self.redirectURL = [NSString stringWithFormat:@"fb%@://authorize", self.clientId];
    self.authURL = [NSString stringWithFormat:@"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&scope=basic_info,email,user_location,user_birthday,user_photos,user_friends,friends_photos&type=user_agent&display=touch",self.clientId,self.redirectURL];
    self.launchURLs = @[ @{ @"url": @"fb://profile/%@", @"name": @"id" },
                        @{ @"url": @"https://www.facebook.com/%@", @"name": @"username" } ];
    return self;
}

- (void)logout
{
    [super logout];
}

- (NSString*)getNextURL:(id)result
{
    return [WFCore toDictionaryString:result name:@"paging" field:@"next"];
}

- (void)getAccount:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getData:@"/me" params:@{ @"fields": @"picture.type(large),id,email,name,username,birthday" } success:^(id user) {
        NSLog(@"getFacebookAccount: %@ %@", user, self.accessToken);
        
        NSMutableDictionary *account = [@{} mutableCopy];
        account[@"id"] = user[@"id"];
        account[@"email"] = user[@"email"];
        account[@"name"] = user[@"name"];
        account[@"username"] = user[@"username"] ?: @"";
        account[@"icon"] = [WFCore toDictionaryString:[WFCore toDictionary:user name:@"picture"] name:@"data" field:@"url"];
        
        int age = 0;
        if (user[@"birthday"] != nil) {
            NSArray *d = [user[@"birthday"] componentsSeparatedByString:@"/"];
            if (d.count > 2) {
                NSDateComponents *cal = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
                age = (int)cal.year - [d[2] intValue];
            }
        }
        // Always include birthday/age even if empty
        account[@"birthday"] = user[@"birthday"] ? user[@"birthday"] : @"";
        account[@"age"] = [NSNumber numberWithInt:age];
        
        // Make sure we have valid gender, take only first letter
        NSString *gender = user[@"gender"];
        account[@"gender"] = gender && gender.length > 0 ? [gender substringToIndex:1] : @"m";
        // Alias is required
        NSArray *alias = [[account[@"name"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@" "];
        account[@"alias"] = alias.count > 0 ? alias[0] : account[@"name"];
        
        self.account = account;
        if (success) success(account);
        
    } failure:failure];
}

- (void)getFriends:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getData:@"/me/friends" params:nil success:^(id result) {
        NSMutableArray *list = [@[] mutableCopy];
        for (NSDictionary *item in result[@"data"]) {
            NSMutableDictionary *rec = [item mutableCopy];
            rec[@"account"] = @"facebook";
            rec[@"icon"] = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=small", rec[@"id"]];
            [list addObject:rec];
        }
        NSLog(@"getFacebookFriends: %d", (int)list.count);
        if (success) success(list);
    } failure:failure];
}

- (void)getFriendsOfGender:(BOOL)searchMale success:(SuccessBlock)success failure:(FailureBlock)failure
{
    
    NSString* genderString = (searchMale ? @"male" : @"female");
    
    [self getData:@"/me/friends?fields=id,name,gender" params:nil success:^(id result) {
        NSMutableArray *list = [@[] mutableCopy];
        for (NSDictionary *item in result[@"data"]) {
            if ([item[@"gender"] isEqualToString:genderString]) {
                NSMutableDictionary *rec = [item mutableCopy];
                rec[@"account"] = @"facebook";
                rec[@"icon"] = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=small", rec[@"id"]];
                [list addObject:rec];
            }
        }
        NSLog(@"getFacebookFriends: %d", (int)list.count);
        if (success) success(list);
    } failure:failure];
}

- (void)getAlbums:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getData:@"/me?fields=albums.fields(name,photos.limit(1).fields(picture),count)" params:nil success:^(id result) {
        NSMutableArray *list = [@[] mutableCopy];
        for (NSDictionary *album in [WFCore toArray:result[@"albums"] name:@"data"]) {
            for (NSDictionary *icon in [WFCore toArray:album[@"photos"] name:@"data"]) {
                [list addObject:@{ @"type": @"facebook",
                                   @"id": [WFCore toString:album name:@"id"],
                                   @"name": [WFCore toString:album name:@"name"],
                                   @"icon": [WFCore toString:icon name:@"picture"],
                                   @"count": [WFCore toString:album name:@"count"] }];
            }
        }
        NSLog(@"getFacebookAlbums: %d", (int)list.count);
        if (success) success(list);
    } failure:failure];
}

- (void)getPhotos:(NSString*)album success:(SuccessBlock)success failure:(FailureBlock)failure;
{
    [self getData:[NSString stringWithFormat:@"/%@/photos",album,nil] params:nil success:^(id result) {
        NSMutableArray *list = [@[] mutableCopy];
        for (NSDictionary *item in result[@"data"]) {
            [list addObject:@{ @"type": @"facebook", @"icon": [WFCore toString:item name:@"picture"], @"image": [WFCore toString:item name:@"source"], @"photo": [WFCore toString:item name:@"source"] }];
        }
        if (success) success(list);
    } failure:failure];
}

-(void)getMutualFriends:(NSString*)name success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getData:[NSString stringWithFormat:@"/me/mutualfriends/%@?fields=name,picture",name,nil] params:nil success:^(id result) {
        NSMutableArray *list = [@[] mutableCopy];
        for (NSMutableDictionary *item in result[@"data"]) {
            item[@"account"] = @"facebook";
            item[@"icon"] = [WFCore toDictionaryString:[WFCore toDictionary:item name:@"picture"] name:@"data" field:@"url"];
            [list addObject:item];
        }
        NSLog(@"getFacebookMutualFriends: %d", (int)list.count);
        if (success) success(list);
    } failure:failure];
}

@end
