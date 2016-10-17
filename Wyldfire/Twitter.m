//
//  Twitter.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/17/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@implementation Twitter

- (id)init:(NSString*)name clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret
{
    self = [super init:name clientId:clientId clientSecret:clientSecret];
    self.apiURL = @"https://api.twitter.com/1.1/";
    self.authURL = @"https://api.twitter.com/oauth/authorize";
    self.accessTokenURL = @"https://api.twitter.com/oauth/access_token";
    self.requestTokenURL = @"https://api.twitter.com/oauth/request_token";
    self.redirectURL = [NSString stringWithFormat:@"tw%@://authorize", self.clientId];
    self.launchURLs = @[ @{ @"url": @"twitter://user?id=%@", @"name": @"id" },
                        @{ @"url": @"http://www.twitter.com/%@", @"name": @"username" } ];
    return self;
}

- (void)getAccount:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self authorize:nil success:success failure:^(NSError *error) { failure(-1); }];
}

@end
