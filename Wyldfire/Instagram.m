//
//  Instagram.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/17/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@implementation Instagram

- (id)init:(NSString*)name clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret
{
    self = [super init:name clientId:clientId clientSecret:clientSecret];
    self.cookiesURL = @"https://instagram.com/";
    self.apiURL = @"https://api.instagram.com/v1";
    self.redirectURL = [NSString stringWithFormat:@"wydlfire://instagramauth"];
    self.authURL = [NSString stringWithFormat:@"https://api.instagram.com/oauth/authorize/?client_id=%@&redirect_uri=%@&response_type=token&display=touch&scope=likes+comments+relationships",self.clientId, self.redirectURL];
    self.launchURLs = @[ @{ @"url": @"instagram://user?username=%@", @"name": @"username" },
                        @{ @"url": @"http://www.instagram.com/%@", @"name": @"username" } ];
    return self;
}

- (NSString*)getNextURL:(id)result
{
    return [WFCore toDictionaryString:result name:@"pagination" field:@"next_url"];
}

- (void)getAccount:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getData:@"/users/self" params:nil success:^(id result) {
        NSMutableDictionary *user = [result[@"data"] mutableCopy];
        user[@"icon"] = user[@"profile_picture"];
        user[@"name"] = user[@"full_name"];
        
        self.account = user;
        if (success) success(user);
    } failure:failure];
}

- (void)getAlbums:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getPhotos:@""
            success:^(NSArray *photos) {
                NSArray *list = @[ @{ @"id": @"instagram", @"name": @"Instagram Photos", @"type": @"instagram", @"icon": photos.count ? photos[0][@"icon"] : @"", @"photos": photos } ];
                if (success) success(list);
            } failure:failure];
}

- (void)getPhotos:(NSString*)album success:(SuccessBlock)success failure:(FailureBlock)failure;
{
    [self getData:@"/users/self/feed" params:nil success:^(id result) {
        NSMutableArray *list = [@[] mutableCopy];
        for (NSDictionary *item in result[@"data"]) {
            [list addObject:@{ @"type": @"instagram",
                               @"icon": item[@"images"][@"thumbnail"][@"url"],
                               @"image": item[@"images"][@"low_resolution"][@"url"],
                               @"photo": item[@"images"][@"standard_resolution"][@"url"] }];
        }
        if (success) success(list);
    } failure:failure];
}

@end
