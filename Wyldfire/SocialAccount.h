//
//  SocialAccount.h
//  Wyldfire
//
//  Created by Vlad Seryakov on 12/1/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

// Social account for third parties
@interface SocialAccount: NSObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* clientId;
@property (nonatomic, strong) NSString* clientSecret;
@property (nonatomic, strong) NSString* apiURL;
@property (nonatomic, strong) NSString* authURL;
@property (nonatomic, strong) NSString* accessTokenURL;
@property (nonatomic, strong) NSString* requestTokenURL;
@property (nonatomic, strong) NSString* redirectURL;
@property (nonatomic, strong) NSString* cookiesURL;
@property (nonatomic, strong) NSArray* launchURLs;
@property (nonatomic, strong) NSString* accessToken;
@property (nonatomic, strong) NSDictionary* account;

- (id)init:(NSString*)name clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret;

- (BOOL)isOpen;
- (void)logout;
- (void)login:(WebViewCompletionBlock)completionHandler;
- (BOOL)launch;
- (void)saveAccount;

- (NSString*)getURL:(NSString*)path;
- (void)getData:(NSString*)path params:(NSDictionary*)params success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)getJSON:(NSString*)path method:(NSString*)method params:(NSDictionary*)params headers:(NSDictionary*)headers success:(SuccessBlock)success failure:(JSONFailureBlock)failure;

- (void)processResult:(id)result items:(NSMutableArray*)items success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)nextResult:(NSString*)path items:(NSMutableArray*)items success:(SuccessBlock)success failure:(FailureBlock)failure;
- (NSString*)getNextURL:(id)result;

// OAUTH 1.x authentication
- (void)authorize:(NSString *)scope success:(SuccessBlock)success failure:(ErrorBlock)failure;

// All network functions should cache results about account in self.account
- (void)getAccount:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)getFriends:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)getMutualFriends:(NSString*)name success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)getAlbums:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)getPhotos:(NSString*)album success:(SuccessBlock)success failure:(FailureBlock)failure;
@end;
