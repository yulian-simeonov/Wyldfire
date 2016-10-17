//
//  APIClient.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/12/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "APIClient.h"

@interface APIClient () <UIAlertViewDelegate>
@property (strong) NSOperationQueue* networkQueue;

@property (nonatomic) BOOL alertShown;
@end

@implementation APIClient

+ (instancetype)sharedClient {
    static APIClient *_client = nil;
    static dispatch_once_t _sharedAPIClientOnceToken;
    dispatch_once(&_sharedAPIClientOnceToken, ^{
        _client = [[self alloc] initWithBaseURL:[[NSURL alloc] initWithString:@""]];
        _client.parameterEncoding = AFJSONParameterEncoding;
        _client.browseToken = @"";
        _client.networkQueue = [[NSOperationQueue alloc] init];
        _client.networkQueue.maxConcurrentOperationCount = 20;
        _client.loggedIn = NO;
        
        [_client setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_INTERNET_STATUS_CHANGED object:self];
            });
        }];
        
        [_client checkFacebookStatus:nil];
        [[NSNotificationCenter defaultCenter] addObserver:_client selector:@selector(relogin:) name:NOTIFICATION_RELOGIN_NEEDED object:nil];
    });
    
    return _client;
}

#pragma mark Reachability

- (BOOL)connectedViaWifi
{
    return self.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi;
}

- (BOOL)online
{
    return self.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.alertShown = NO;
}

#pragma mark Management

- (void)checkFacebookStatus:(GenericBlock)success
{
    [FBSession setActiveSession:self.session];
    if (!self.session.isOpen) {
        self.session = [[FBSession alloc] init];
        [FBSession setActiveSession:self.session];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (self.session.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            [self.session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                if (error) NSLog(@"FB: %@", error);
                self.session = session;
                [FBSession setActiveSession:self.session];
                if (success) success();
            }];
            return;
        }
        if (success) success();
        return;
    }
    if (success) success();
}

- (void)clearQueue
{
    [self.networkQueue cancelAllOperations];
}

- (Account*)account
{
    return [WFCore get].accountStructure;
}

#pragma mark Authentication

- (NSString*)secret
{
    return [SSKeychain passwordForService:@"WYLDFIRE_SECRET_SERVICE" account:@"WYLDFIRE_ACCOUNT"];
}

- (void)setSecret:(NSString*)secret
{
    [SSKeychain setPassword:secret forService:@"WYLDFIRE_SECRET_SERVICE" account:@"WYLDFIRE_ACCOUNT"];
}

- (NSString*)login
{
    return [SSKeychain passwordForService:@"WYLDFIRE_LOGIN_SERVICE" account:@"WYLDFIRE_ACCOUNT"];
}

- (void)setLogin:(NSString*)login
{
    [SSKeychain setPassword:login forService:@"WYLDFIRE_LOGIN_SERVICE" account:@"WYLDFIRE_ACCOUNT"];
}

- (NSArray*)accountsForDictionaryList:(NSArray *)accountList
{
    NSMutableArray* ret = [NSMutableArray new];
    
    for (NSDictionary* accountDic in accountList) {
        Account* userAccount = [Account accountFromAPICall:accountDic];
        [ret addObject:userAccount];
    }
    return ret;
}

#pragma mark Helper Functions

#define XSTR(n) #n
#define STR(n) XSTR(n)

// Build full URL and check if it needs to be over SSL
- (NSString*)getURL:(NSString*)path
{
    bool ssl = [WFCore matchString:@"(^/wf/login$|^/wf/add$|^/account/get$|^/message/)" string:path];
    
    if (![path hasPrefix:@"http"]) {
        if ([WFCore matchString:@"(^/account/(get|select|put|del)/icon)" string:path]) {
            path = [NSString stringWithFormat:@"http://img%s%@", STR(WF_DOMAIN), path];
        } else {
            path = [NSString stringWithFormat:@"http://api%s%@", STR(WF_DOMAIN), path];
        }
    }
    if ([path hasPrefix:@"http://localhost"]) {
        return path;
    }
    if (ssl) {
        path = [path stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    }
    return path;
}

- (void)getData:(NSString *)path method:(NSString*)method params:(NSDictionary*)params contentType:(NSString*)contentType success:(SuccessBlock)success failure:(JSONFailureBlock)failure
{
    path = [self getURL:path];
    NSDictionary *headers = [self sign:path method:method params:params contentType:contentType expires:0 checksum:nil];
    [self getJSON:path method:method params:params headers:headers success:success failure:failure];
}

- (void)getJSON:(NSString *)path method:(NSString*)method params:(NSDictionary*)params headers:(NSDictionary*)headers success:(SuccessBlock)success failure:(JSONFailureBlock)failure
{
    if (!method) method = @"GET";
    NSMutableURLRequest *request = [self requestWithMethod:method path:[self getURL:path] parameters:params];
    request.timeoutInterval = 30;
    for (NSString* header in [headers allKeys]) {
        if (header) {
            [request setValue:[headers valueForKey:header] forHTTPHeaderField:header];
        }
    }
    NSLog(@"url=%@", request.URL);
    //NSLog(@"getJSON: %@ %@ \nheaders: %@\nbody: %@\n", method, url, request.allHTTPHeaderFields, params);
    
    AFJSONRequestOperation *op =
        [AFJSONRequestOperation
         JSONRequestOperationWithRequest:request
         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
             if (success) success(json);
         }
         failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json) {
             Error(@"%@: error: %ld: %@: data: %@", request.URL, (long)response.statusCode, error, json);
             if (response.statusCode == 412) {
                 [self clearQueue];
                 [self checkFacebookStatus:^() {
                     if (!self.session.isOpen) {
                         [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_RELOGIN_NEEDED object:nil];
                         return;
                     }
                     [self wfLogin:^(Account *account) {
                         [self getData:path method:method params:params contentType:headers[@"Content-Type"] success:success failure:failure];
                     } failure:^() {
                         [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_RELOGIN_NEEDED object:nil];
                     }];
                 }];
                 return;
             }
             if (failure) failure(response.statusCode, error, json);
         }];
    [self.networkQueue addOperation:op];
}

- (void)relogin:(NSNotification *)notification
{
    NSLog(@"relogin");
    [GVUserDefaults standardUserDefaults].email = nil;
    [self.session closeAndClearTokenInformation];
    [WFCore showViewController:nil name:@"AppTourViewController" mode:nil params:nil];
}

- (void)getAccountImageOfType:(int)type success:(ImageSuccessBlock)success failure:(FailureBlock)failure
{
    [self getImageForPath:[NSString stringWithFormat:@"/account/get/icon?type=%i", type] account:nil success:success failure:failure];
}

- (void)getAccountImageOfType:(int)type account:(NSString*)account success:(ImageSuccessBlock)success failure:(FailureBlock)failure
{
    [self getImageForPath:[NSString stringWithFormat:@"/account/get/icon?type=%i", type] account:account success:success failure:failure];
}

- (void)getImageForPath:(NSString*)path success:(ImageSuccessBlock)success failure:(FailureBlock)failure
{
    [self getImageForPath:path account:nil success:success failure:failure];
}

- (void)getImageForPath:(NSString*)path account:(NSString*)account success:(ImageSuccessBlock)success failure:(FailureBlock)failure
{
    path = [self getURL:path];
    if (account != nil) path = [path stringByAppendingFormat:@"&id=%@", account];
    NSString* method = @"GET";
    NSString* contentType = @"application/x-www-form-urlencoded";
    NSDictionary *headers = [self sign:path method:method params:nil contentType:contentType expires:0 checksum:nil];
    
    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:nil];
    request.timeoutInterval = 30;
    for (NSString* header in [headers allKeys]) {
        if (header ) {
            [request setValue:[headers valueForKey:header] forHTTPHeaderField:header];
        }
    }
   
    AFImageRequestOperation *op =
      [AFImageRequestOperation
       imageRequestOperationWithRequest:request
       imageProcessingBlock:^UIImage *(UIImage *image) {
           return image;
       }
       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
           if (success) success(image, path);
       }
       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
           Error(@"%@: error: %ld: %@", request.URL, (long)response.statusCode, error);
           if (failure) failure(response.statusCode);
       }];
    [self.networkQueue addOperation:op];
}

#pragma mark - Signing Requests

- (NSDictionary*)sign:(NSString*)path method:(NSString*)method params:(NSDictionary*)params contentType:(NSString*)contentType expires:(NSTimeInterval)expires checksum:(NSString*)checksum
{
    NSMutableDictionary *rc = [@{} mutableCopy];
    if (!checksum) checksum = @"";
    if (!contentType) contentType = @"";
    if (!method) method = @"GET";
    
    //Setup headers
    if (expires == 0) expires = 30000;
    NSNumber *expire = [NSNumber numberWithLongLong:([WFCore now] + expires) * 1000];
    
    // Default content-type for query parameters
    if ([method isEqualToString:@"POST"] && [contentType isEqualToString:@""]) {
        contentType = @"application/x-www-form-urlencoded";
    }
    
    // Non empty content type must be in the signature and the headers
    if (![contentType isEqualToString:@""]) rc[@"Content-Type"] = contentType;
    
    NSURL *url = [NSURL URLWithString:path];
    
    //Setup query, not for JSON
    NSString *query = @"";
    if (params && ![contentType isEqualToString:@"application/json"]) {
        NSMutableArray *list = [@[] mutableCopy];
        for (NSString *key in params.allKeys) {
            NSString* stringValue;
            if ([params[key] isKindOfClass:[NSString class]]) {
                stringValue = params[key];
            } else {
                stringValue = [WFCore escape:[params[key] stringValue]];
            }
            [list addObject:[NSString stringWithFormat:@"%@=%@", key, [stringValue stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]]];
        }
        query = [[list sortedArrayUsingComparator:^(id n1, id n2) { return [[n1 stringValue] compare:[n2 stringValue]]; }] componentsJoinedByString:@"&"];
    }
    
    //Sign
    NSString *str = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n",method,url.host,url.path,query,expire,contentType,checksum];
    NSString *sig = [WFCore hmacSHA1:[str dataUsingEncoding:NSUTF8StringEncoding] secret:[self secret]];
    rc[@"bk-signature"] = [NSString stringWithFormat:@"1||%@|%@|%@|%@|", [self login], sig, [expire stringValue], checksum];
    return rc;
}

- (NSString*)hmacSHA1:(NSData*)data secret:(NSString*)secret
{
    unsigned char hmac[20];
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [data bytes], [data length], hmac);
    return [self base64Encode:[NSData dataWithBytes:hmac length:sizeof(hmac)]];
}

- (NSString*)base64Encode:(NSData*)data
{
    return [data base64EncodedStringWithOptions:0];
}

- (NSData*)base64Decode:(NSString*) string
{
    return [[NSData alloc] initWithBase64EncodedString:string options:0];
}

#pragma mark API Calls

#pragma mark - Overly Complicated Sign In APIs

- (void)checkGeofenceWithSuccess:(GenericBlock)success andFailure:(FailureBlock)failure
{
    CLLocation* loc = [[WFCore get] getLocation];
    
    [self getData:@"/wf/geofence"
           method:@"POST"
           params:@{@"latitude"     : @(loc.coordinate.latitude),
                    @"longitude"    : @(loc.coordinate.longitude)}
      contentType:@"application/json"
          success:^(id obj) {
              if (success) success();
          } failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure(code);
          }];
}

- (void)checkInviteCode:(NSString*)code success:(GenericBlock)success failure:(StringBlock)failure
{
    if (code == nil) {
        failure(@"Invalid code");
        return;
    }
    [self getData:@"/invitation/redeem"
           method:@"POST"
           params:@{ @"code": code,
                     @"access_token": [self facebookToken] }
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              if (success) success();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure([WFCore toString:json name:@"message"]);
          }];
}

- (void)getUnredeemedCode:(StringBlock)success failure:(GenericBlock)failure
{
    [self getData:@"/invitation/get"
           method:@"GET"
           params:nil
      contentType:@"application/x-www-form-urlencoded"
          success:^(NSDictionary *json) {
              for (NSDictionary *dict in (NSArray*)json) {
                  id c = dict[@"id"];
                  id n = dict[@"isredeemed"];
                  if (c != nil && n != nil && [n intValue] == 0) {
                      if (success) success(c);
                      return;
                  }
              }
              if (failure) failure();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if(failure) failure();
          }];
}

- (void)getInviteCode:(StringBlock)success failure:(GenericBlock)failure
{
    [self getData:@"/invitation/new"
           method:@"GET"
           params:nil
      contentType:@"application/x-www-form-urlencoded"
          success:^(NSDictionary *json) {
              if (success) success([WFCore toString:json name:@"code"]);
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

#pragma mark - Account Management

- (NSString*)facebookToken
{
    if (self.session && self.session.accessTokenData && self.session.accessTokenData.accessToken) {
        return self.session.accessTokenData.accessToken;
    }
    return @"";
}

- (void)processAccountResponse:(NSDictionary*)json success:(AccountBlock)success failure:(GenericBlock)failure
{
    Account* account = [Account accountFromAPICall:json];
    [WFCore get].accountStructure = account;
    
    [GVUserDefaults standardUserDefaults].hasFinishedSetup = account.icons.count >= 3;
    [Kiip sharedInstance].email = account.email;
    [Kiip sharedInstance].gender = account.isMale ? @"Male" : @"Female";
    
    NSLog(@"account: id=%@, gender=%@, icons=%lu", account.accountID, account.gender, (unsigned long)account.icons.count);

    [[GVUserDefaults standardUserDefaults] updateSettings:json];
    for (NSDictionary* icon in account.icons) {
        int type = [WFCore toNumber:icon name:@"type"];
        [self getAccountImageOfType:type success:^(UIImage *image, NSString *url) {
            [[self account] setImage:image forType:type];
        } failure:nil];
    }

    [self getStats:^(Stats *stats) {
        [self checkHintsUsedInLast24Hours];
        if (success) success(account);
    }];
}

- (void)wfLogin:(AccountBlock)success failure:(GenericBlock)failure
{
    NSString* fbToken = [self facebookToken];
    if (!fbToken) {
        NSLog(@"FB no token");
        if (failure) failure();
        return;
    }
    
    BOOL noLogin = [self login] == nil;
        
    [self getJSON:@"/wf/login"
           method:@"POST"
           params:@{ @"access_token": fbToken }
          headers:@{}
          success:^(NSDictionary* json) {
              [self setLogin:json[@"login"]];
              [self setSecret:json[@"secret"]];
              self.loggedIn = YES;
              
              [self processAccountResponse:json success:^(Account *account){
                  // If we logged in into our account but the app was deleted we need to download all stuff
                  if (noLogin) {
                      [self restoreAccount:^{
                          if (success) success(account);
                      }];
                      return;
                  } else
                  if ([WFCore get].deviceToken && ![[WFCore get].deviceToken isEqualToString:account.deviceID]) {
                      [self updateAccountField:@"device_id" value:[WFCore get].deviceToken notify:NO success:nil failure:nil];
                  }
                  if (success) success(account);
                  
              } failure:failure];
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)getAccount:(AccountBlock)success failure:(GenericBlock)failure
{
    if (!self.loggedIn) {
        if (failure) failure();
        return;
    }
    
    [self getData:@"/account/get"
           method:@"GET"
           params:nil
      contentType:nil
          success:^(NSDictionary *json) {
              [self processAccountResponse:json success:success failure:failure];
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)restoreAccount:(GenericBlock)success
{
    NSLog(@"restoring account...");
    [self downloadMessages:@"/archive" notify:NO finished:^{
        [self downloadMessages:@"/sent" notify:NO finished:^{
            [self getPendingMatches:^(NSArray *matches) {
                [self storePendingMatches:matches];
                [self getBlackbook:^(NSArray* accounts) {
                    [self storeBlackbookContacts:accounts notify:NO];
                    if (success) success();
                }];
            }];
        }];
    }];
}

- (void)getUserAccount:(NSString*)wyldfireID obj:(Account*)account success:(void (^)(Account *account, NSDictionary* json))success failure:(GenericBlock)failure
{
    if (account == nil) account = [Account new];
    
    [self getData:@"/account/get"
           method:@"POST"
           params:@{ @"id" : wyldfireID }
      contentType:@"application/json"
          success:^(NSArray *accountsJsonArray) {
              if (accountsJsonArray.count == 0) {
                  if (failure) failure();
                  return;
              }
              NSDictionary* json = accountsJsonArray[0];
              [Account accountFromAPICall:json usingObject:account];
              if(success) success(account, json);
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)addAccount:(GenericBlock)success failure:(FailureBlock)failure
{
    CLLocation* loc = [[WFCore get] getLocation];
    
    NSDictionary* params = @{@"access_token"  : [self facebookToken],
                             @"latitude"      : @(loc.coordinate.latitude),
                             @"longitude"     : @(loc.coordinate.longitude)};
    
    [self getJSON:@"/wf/add"
           method:@"POST"
           params:params
          headers:@{}
          success:^(NSDictionary *json) {
              //Start fresh
              [CoreData deleteAll];
              [self setLogin:json[@"login"]];
              [self setSecret:json[@"secret"]];
              self.loggedIn = YES;
              
              //retrieve extra fields that weren't sent
              [self account].age = [json[@"age"] intValue];
              [self account].accountID = json[@"id"];
              
              //Account gender interest defaults
              [GVUserDefaults standardUserDefaults].settingInterestedInMen = ![self account].isMale;
              [GVUserDefaults standardUserDefaults].settingInterestedInWomen = [self account].isMale;
              [[GVUserDefaults standardUserDefaults] updateSettings:json];
              
              if ([self account].facebookIcon) {
                  [self setImageFromURL:[self account].facebookIcon type:1 success:success failure:success];
              } else {
                  if (success) success();
              }
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure(code);
          }];
}

- (void)resetLocalAccount
{
    [GVUserDefaults standardUserDefaults].hasFinishedSetup = NO;
    [GVUserDefaults standardUserDefaults].email = nil;
    [GVUserDefaults standardUserDefaults].facebookID = 0;
    [GVUserDefaults standardUserDefaults].displayEmail = nil;
    [GVUserDefaults standardUserDefaults].lastMatchMtimeCheck = 0;
    [WFCore get].accountStructure = nil;
    [CoreData deleteAll];
}

- (void)deleteAccount:(GenericBlock)success failure:(GenericBlock)failure
{
    [self getData:@"/account/del"
           method:@"GET"
           params:nil
      contentType:nil
          success:^(NSDictionary *json) {
              self.loggedIn = NO;
              [self resetLocalAccount];
              [self.session closeAndClearTokenInformation];
              [self checkFacebookStatus:success];
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)updateAccountField:(NSString*)field value:(id)value notify:(BOOL)notify success:(GenericBlock)success failure:(GenericBlock)failure
{
    NSLog(@"upateAccount: %@=%@", field, value);
    if (field == nil || value == nil) {
        if (failure) failure();
    }
    [self updateAccount:@{ field : value } notify:notify success:success failure:failure];
}

- (void)updateAccount:(NSDictionary*)params notify:(BOOL)notify success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self getData:@"/account/update"
           method:@"POST"
           params:params
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              if (notify) [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_SETTINGS object:self];
              if (success) success();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

#pragma mark Account Information

- (void)getAccountIcons:(void (^)(NSInteger iconCount))success failure:(GenericBlock)failure
{
    [self getData:@"/account/select/icon"
           method:@"GET"
           params:nil
      contentType:nil
          success:^(NSArray *json) {
              if ([json isKindOfClass:[NSArray class]]) {
                  for (NSDictionary* dic in json) {
                      int type = [dic[@"type"] intValue];
                      [self getAccountImageOfType:type success:^(UIImage *image, NSString *url) {
                          [[self account] setImage:image forType:type];
                      } failure:nil];
                  }
              }
              
              //Asychronously download the images, send back the count after finding their URLs
              if (success) success(json.count);
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)getStats:(void (^)(Stats* stats))callback
{
    if (![self loggedIn]) {
        if (callback) callback(nil);
        return;
    }
    
    [self getData:@"/wf/stats"
           method:@"GET"
           params:nil
      contentType:nil
          success:^(NSDictionary *json) {
              Stats* stats = [Stats statsFromAPICall:json];
              [WFCore get].accountStructure.stats = stats;
              [GVUserDefaults standardUserDefaults].lastStatsMtimeCheck = [self now];
              [self analyzeStatsForKiip:stats];
              
              [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_STATS object:stats];
              
              if (callback) callback(stats);
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (callback) callback(nil);
          }];
}

- (void)refreshStats
{
    // Update stats not very often otherwise they refreshed only in settings/profile
    if ([self now] - [GVUserDefaults standardUserDefaults].lastStatsMtimeCheck < 300000) return;
    [self getStats:nil];
}

- (UINavigationController*)navC
{
    return (UINavigationController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
}

- (void)analyzeStatsForKiip:(Stats*)stats
{
    UINavigationController* navC = [self navC];
    
    if (stats.likesReceived > 25) {
        [WFCore saveMoment:KIIP_REWARD_MOMENT_25_LIKES
                  onlyOnce:YES
                   topText:@"Gettin Warmed Up"
                bottomText:@"You have received 25 likes!"
                    inNavC:navC];
    }
    if (stats.likesReceived > 150) {
        [WFCore saveMoment:KIIP_REWARD_MOMENT_150_LIKES
                  onlyOnce:YES
                   topText:@"Goin' Wild"
                bottomText:@"You have received 150 likes!"
                    inNavC:navC];
    }
    
    if (stats.likesPerformed > 0) {
        if ((float)stats.likesReceived / (float)stats.likesPerformed > 0.98) {
            [WFCore saveMoment:KIIP_REWARD_MOMENT_LIKE_RATIO98
                      onlyOnce:YES
                       topText:@"Congratulations"
                    bottomText:@"Reached 98% like ratio"
                        inNavC:navC];
        }
    }
    
    int separateDaysThatChangedImage = 0;
    for (int i = 0; i < stats.daysChangedImage.count; i++) {
        if ([((NSNumber*)stats.daysChangedImage[i]) intValue] > 0) separateDaysThatChangedImage++;
    }
    
    if (separateDaysThatChangedImage > 3) {
        [WFCore saveMoment:KIIP_REWARD_MOMENT_UPDATED_3_TIMES
                  onlyOnce:YES
                   topText:@"Lookin' Good!"
                bottomText:@"You've updated your pictures thrice this week.  Good work!"
                    inNavC:navC];
    }
    
    if ([WFCore get].accountStructure.isMale) {
        for (int i = 0; i < stats.likeCounts.count; i++) {
            if ([((NSNumber*)stats.likeCounts[i]) intValue] > 25) {
                [WFCore saveMoment:KIIP_REWARD_MOMENT_25_LIKES_DAY
                          onlyOnce:YES
                           topText:@"Mr. Popular"
                        bottomText:@"25 likes in one day! You sir, are popular."
                            inNavC:navC];
            }
        }
    }
}

#pragma mark - Connections

- (void)performAction:(NSString*)action onUser:(Account*)userAccount
              success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self getData:@"/connection/add"
           method:@"POST"
           params:@{ @"id" : userAccount.accountID,
                     @"type" : action}
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              if (success) success();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)viewUser:(Account*)userAccount success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self getData:@"/wf/view"
           method:@"POST"
           params:@{ @"id" : userAccount.accountID}
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              if (success) success();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)likeUser:(Account*)userAccount success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self performAction:@"like" onUser:userAccount success:success failure:failure];
}

- (void)passUser:(Account*)userAccount success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self performAction:@"pass" onUser:userAccount success:success failure:failure];
}

- (void)hintUser:(Account*)userAccount success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self performAction:@"hint" onUser:userAccount success:success failure:failure];
}

- (void)matchUser:(Account*)userAccount success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self performAction:@"match" onUser:userAccount success:success failure:failure];
}

- (void)burnUser:(Account*)userAccount success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self performAction:@"burn" onUser:userAccount success:success failure:failure];
}

- (void)checkIfLikedbyUser:(Account*)userAccount success:(void (^)(BOOL connectionExists))success failure:(GenericBlock)failure
{
    [self checkForReferenceType:@"like" byUser:userAccount success:success failure:failure];
}

- (void)checkIfHintedbyUser:(Account*)userAccount success:(void (^)(BOOL connectionExists))success failure:(GenericBlock)failure
{
    [self checkForReferenceType:@"hint" byUser:userAccount success:success failure:failure];
}

- (void)checkForReferenceType:(NSString*)type byUser:(Account*)userAccount
                      success:(void (^)(BOOL connectionExists))success failure:(GenericBlock)failure
{
    NSMutableDictionary* params = [@{@"type" : type} mutableCopy];
    if (userAccount) {
        params[@"id"] = userAccount.accountID;
    }
    
    [self getData:@"/reference/get"
           method:@"POST"
           params:params
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              BOOL foundReference = ((NSArray*)json[@"data"]).count > 0;
              
              if (success) success(foundReference);
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)findReferencesOfType:(NSString*)type success:(void (^)(NSArray* accounts))success failure:(GenericBlock)failure
{
    [self findReferencesOfType:type mtime:@(0) success:success failure:failure];
}

- (void)findReferencesOfType:(NSString*)type mtime:(NSNumber*)mtime
                     success:(void (^)(NSArray* accounts))success failure:(GenericBlock)failure
{
    [self getData:@"/reference/get"
           method:@"POST"
           params:@{ @"type" : type,
                     @"mtime" : mtime,
                     @"_keys" : @"id,type,mtime",
                     @"_ops"  : @"mtime,ge"}
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              NSMutableArray* ret = [NSMutableArray new];
              NSArray* accountList = json[@"data"];
              
              for (NSDictionary* accountDic in accountList) {
                  Account* userAccount = [Account accountFromAPICall:accountDic];
                  [ret addObject:userAccount];
              }
              
              if (success) success(ret);
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

#pragma mark - Messages

- (void)putMessage:(NSString*)message toID:(NSString*)toID
           success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self getData:@"/message/add"
           method:@"POST"
           params:@{@"id" : toID,
                    @"msg" : message}
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              if (success) success();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)putMessageImage:(UIImage*)image text:(NSString*)text toID:(NSString*)toID
                success:(GenericBlock)success failure:(GenericBlock)failure
{
    
    NSMutableDictionary* params = [@{@"id" : toID} mutableCopy];
    if (text) params[@"msg"] = text;
    if (image) {
        float quality = 0.5;
        
        NSData* data;
        do {
            data = UIImageJPEGRepresentation(image, quality);
            quality -= 0.1;
        } while (data.length > 4000000);    //Limit image size to 4 MB
        NSLog(@"Sending Photo with Quality: %f", quality + 0.1);
        
        params[@"icon"] = [WFCore base64Encode:data];
        params[@"acl_allow"] = @"auth";
    }
    
    [self getData:@"/message/add"
           method:@"POST"
           params:params
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              if (success) success();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}


#pragma mark - Location

- (void)putLocation:(CLLocation*)location success:(GenericBlock)success failure:(GenericBlock)failure
{
    if (!self.loggedIn || ![GVUserDefaults standardUserDefaults].hasFinishedSetup) {
        if (failure) failure();
        return;
    }
    NSLog(@"putLocation: %g %g", location.coordinate.latitude, location.coordinate.longitude);

    [self getData:@"/location/put"
           method:@"POST"
           params:@{@"latitude" : @(location.coordinate.latitude),
                    @"longitude" : @(location.coordinate.longitude)}
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              // start browse from the beginning if we have moved far enough
              self.browseToken = @"";
              [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_LOCATION object:location];
              if (success) success();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (NSNumber*)maxAge
{
    int maxAge = [GVUserDefaults standardUserDefaults].settingMaxAge;
    if (maxAge == 50) maxAge = 99;
    return @(maxAge);
}

- (void)getNearbyAccounts:(void (^)(NSArray* accounts))success failure:(GenericBlock)failure
{
    if ((![GVUserDefaults standardUserDefaults].settingInterestedInMen) &&
        (![GVUserDefaults standardUserDefaults].settingInterestedInWomen)) {
        failure();
        return;
    }
    
    CLLocation* loc = [[WFCore get] getLocation];
    NSMutableString* genderString = [@"" mutableCopy];
    if ([GVUserDefaults standardUserDefaults].settingInterestedInMen) {
        [genderString appendString:@"m"];
    }
    if ([GVUserDefaults standardUserDefaults].settingInterestedInWomen) {
        if (genderString.length > 0) [genderString appendString:@","];
        [genderString appendString:@"f"];
    }
    
    [self getData:@"/wf/browse"
           method:@"POST"
           params:@{@"distance" : @([GVUserDefaults standardUserDefaults].settingSearchRadius * 1.60934),   //Miles to KM
                    @"latitude" : @(loc.coordinate.latitude),
                    @"longitude": @(loc.coordinate.longitude),
                    @"gender"   : genderString,
                    @"age"      : @[@([GVUserDefaults standardUserDefaults].settingMinAge), [self maxAge]],
                    @"_token"   : self.browseToken
                    }
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              self.browseToken = [WFCore toString:json name:@"next_token"];
              NSMutableArray* ret = [NSMutableArray new];
              NSArray* accountList = json[@"data"];
              for (NSDictionary* accountDic in accountList) {
                  Account* userAccount = [Account accountFromAPICall:accountDic];
                  [ret addObject:userAccount];
              }
              NSLog(@"browse: found %d, next token: %@", (int)ret.count, self.browseToken);
              if (success) success(ret);
          }
          failure:^(NSInteger code, NSError *error, id json) {
              NSLog(@"/wf/browse: %@", loc);
              if (failure) failure();
          }];
}

- (void)getTrendingForGenderString:(NSString*)genderString success:(void (^)(NSArray* accounts))success failure:(GenericBlock)failure
{
    CLLocation* loc = [[WFCore get] getLocation];
    
    [self getData:@"/wf/top"
           method:@"POST"
           params:@{@"distance"     : @([GVUserDefaults standardUserDefaults].settingTrendingRadius * 1.60934),   //Miles to KM
                    @"latitude"     : @(loc.coordinate.latitude),
                    @"longitude"    : @(loc.coordinate.longitude),
                    @"gender"       : genderString,
                    @"age"          : @[@([GVUserDefaults standardUserDefaults].settingMinAge),
                                        [self maxAge]]}
      contentType:@"application/json"
          success:^(NSArray *accountList) {
              NSMutableArray* ret = [NSMutableArray new];
              for (NSDictionary* accountDic in accountList) {
                  Account* userAccount = [Account accountFromAPICall:accountDic];
                  [ret addObject:userAccount];
              }
              if (success) success(ret);
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

#pragma mark Images

// Sending nil image will delete the icon for the given type
- (void)uploadImage:(UIImage*)image type:(NSInteger)type success:(GenericBlock)success failure:(GenericBlock)failure
{
    NSMutableDictionary *params = [@{ @"type": [NSNumber numberWithInteger:type],
                                      @"acl_allow" : @"auth"} mutableCopy];
    
    if (image && [image isKindOfClass:[UIImage class]]) {
        NSData *jpeg = UIImageJPEGRepresentation(image, 1.0);
        if (!jpeg) {
            Error(@"cannot convert to JPEG: %@", image);
            if (failure) failure();
            return;
        }
        params[@"icon"] = [WFCore base64Encode:jpeg];
        params[@"_quality"] = @80;
        NSLog(@"uploadImage: type=%d, %gx%g", (int)type, image.size.width, image.size.height);
    }
    
    [self getData:[NSString stringWithFormat:@"/account/%@/icon", image ? @"put" : @"del"]
           method:@"POST"
           params:params
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              [[self account] setImage:image forType:type];
              if (success) success();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

- (void)setImageFromURL:(NSString*)url type:(NSInteger)type success:(GenericBlock)success failure:(GenericBlock)failure
{
    NSLog(@"setImage: type=%d, %@", (int)type, url);
    
    [self downloadImage:url success:^(UIImage *image, NSString *url) {
        // Set image locally even there is no account yet, for registration process to show FB icon
        [[self account] setImage:image forType:type];
        if (![self loggedIn]) {
            if (success) success();
        } else {
            [self uploadImage:image type:type success:success failure:failure];
        }
    } failure:failure];
}

- (void)downloadImage:(NSString*)url success:(ImageSuccessBlock)success failure:(FailureBlock)failure
{
    if (url == nil) {
        if (failure) failure(0);
        return;
    }
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:url parameters:nil];
    AFImageRequestOperation *op =
    [AFImageRequestOperation
     imageRequestOperationWithRequest:request
     imageProcessingBlock:^UIImage *(UIImage *image) {
         return image;
     }
     success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
         if (success) success(image, url);
     }
     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
         Error(@"%@: error: %ld: %@", request.URL, (long)response.statusCode, error);
         if (failure) failure(response.statusCode);
     }];
    [self.networkQueue addOperation:op];
}

#pragma mark - Blackbook

- (void)shareContactInfoWithAccount:(Account*)account success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self performAction:@"blackbook" onUser:account success:success failure:failure];
}

- (void)getBlackbook:(void (^)(NSArray* accounts))success
{
    [self getData:@"/wf/contact"
           method:@"GET"
           params:nil
      contentType:@"application/x-www-form-urlencoded"
          success:^(NSArray *json) {
              [GVUserDefaults standardUserDefaults].lastBlackbookMtimeCheck = [self now];
              NSArray* list = [self accountsForDictionaryList:json];
              if (success) success(list);
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (success) success(nil);
          }];
}

// get blackbook and look through the acounts returned,
// match up with DBAccounts that dont have blackbook set
// set blackbook flag for these accounts, and notify user, add to recently added userdefault
- (void)storeBlackbookContacts:(NSArray*)accounts notify:(BOOL)notify
{
    if (accounts == nil) return;
    for (Account* account in accounts) {
        DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:account.accountID];
        if (dbAccount) {
            BOOL newInBlackbook = ![dbAccount.inBlackbook boolValue];
            dbAccount.inBlackbook = [NSNumber numberWithBool:YES];
            if (account.phone) {
                dbAccount.phone = account.phone;
            }
            if (account.email) {
                dbAccount.email = account.email;
            }
            [dbAccount save];
                
            if ((![dbAccount.burned boolValue]) && newInBlackbook && dbAccount.avatarPhoto) {
                [[GVUserDefaults standardUserDefaults] addNotebookUnseenAccount:account.accountID];
                if (notify) {
                    [self checkKiipContactRelatedRewardsForAccountID:account.accountID];
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NEW_CONTACT object:self userInfo:@{@"senderID" : account.accountID}];
                }
            }
        }
    }
}

- (void)checkBlackbookForNewContacts
{
    if ([self now] - [GVUserDefaults standardUserDefaults].lastBlackbookMtimeCheck < 300000) return;
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:NO];
    [self getBlackbook:^(NSArray* accounts) {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        [self storeBlackbookContacts:accounts notify:YES];
    }];
}

- (void)checkKiipContactRelatedRewardsForAccountID:(NSString*)accountID
{
    if ([Message messagesForAccountID:accountID].count < 20) {
        [WFCore saveMoment:KIIP_REWARD_MOMENT_RECEIVED_CON_EARLY
                  onlyOnce:YES
                   topText:@"Prince Charming"
                bottomText:@"You've received a contact before your messages ran out!"
                    inNavC:[self navC]];
        
    } else {
        [WFCore saveMoment:KIIP_REWARD_MOMENT_RECEIVED_CONTACT
                  onlyOnce:YES
                   topText:@"Gettin' Digits!"
                bottomText:@"Someone just shared their contact with you."
                    inNavC:[self navC]];
    }
    
    if (![WFCore get].accountStructure.isMale) {
        if ([DBAccount retrieveAccountsInBlackbook].count > 9) {
            [WFCore saveMoment:KIIP_REWARD_MOMENT_10_IN_NOTEBOOK
                      onlyOnce:YES
                       topText:@"Congratulations!" bottomText:@"You deserve a reward for allowing 10 gentlemen in your Notebook!" inNavC:[self navC]];
        } else if ([DBAccount retrieveAccountsInBlackbook].count > 3) {
            [WFCore saveMoment:KIIP_REWARD_MOMENT_3_IN_NOTEBOOK
                      onlyOnce:YES
                       topText:@"Congratulations!" bottomText:@"You deserve a reward for allowing 3 gentlemen in your Notebook!" inNavC:[self navC]];
        }
    }
}

#pragma mark - Facebook Login

- (void)facebookLogin:(UIViewController*)viewController successBlock:(GenericBlock)success failureBlock:(GenericBlock)failure
{
    [self facebookLogin:viewController secondTry:NO successBlock:success failureBlock:failure];
}

- (void)facebookLogin:(UIViewController*)viewController secondTry:(BOOL)secondTry successBlock:(GenericBlock)success failureBlock:(GenericBlock)failure
{
    if (!self.session.isOpen) {
        [self performFacebookLoginInViewController:viewController successBlock:^{
            [self facebookLogin:viewController secondTry:secondTry successBlock:success failureBlock:failure];
        } failureBlock:failure];
    } else {
        [self wfLogin:success failure:^() {
            if (!secondTry) {
                [self performFacebookLoginInViewController:viewController successBlock:success failureBlock:failure];
            } else {
                if (failure) failure();
            }
        }];
    }
}

- (void)nextActionAfterFacebookLogin:(UIViewController*)viewController successBlock:(GenericBlock)success failureBlock:(GenericBlock)failure
{
    [self wfLogin:success failure:^{
        [self checkGeofenceWithSuccess:^{
            if (WFCore.account.isMale) {
                // If male, create account later
                if (success) success();
            } else {
                // If female, create account now
                [self addAccount:success failure:^(NSInteger code) {
                    [WFCore showAlert:@"Connection Error" msg:@"Unable to retrieve your account from Wyldfire.  Please try again later." delegate:nil confirmHandler:nil];
                    if (failure) failure();
                }];
            }
        } andFailure:^(NSInteger code) {
            NSString* subdomain = code == 404 ? @"area" : @"spots";
            NSString* urlString = [NSString stringWithFormat:@"http://%@.wyldfireapp.com", subdomain];
            
            WebViewViewController* vc = [WebViewViewController initWithDelegate:nil completionHandler:nil];
            [vc start:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] completionHandler:nil];
            [viewController presentViewController:vc animated:YES completion:nil];
            if (failure) failure();
        }];
    }];
}

- (void)performFacebookLoginInViewController:(UIViewController*)viewController successBlock:(GenericBlock)success failureBlock:(GenericBlock)failure
{
    if (self.session.isOpen) {
        [self performActionsWhenLoggedIntoFacebook:viewController successBlock:success failureBlock:failure];
    } else {
        [FBSettings enablePlatformCompatibility:YES];
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile",@"email",@"user_birthday",@"user_photos",@"user_friends"]
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                          if (session.isOpen) {
                                              self.session = session;
                                          }
                                          if (self.session.isOpen) {
                                              [FBSession setActiveSession:self.session];
                                              [self performActionsWhenLoggedIntoFacebook:viewController successBlock:success failureBlock:failure];
                                          } else {
                                              [FacebookUtility handleAuthError:error];
                                              if (failure) failure();
                                              
                                              [self.session closeAndClearTokenInformation];
                                          }
                                      }];
    }
}

- (void)performActionsWhenLoggedIntoFacebook:(UIViewController*)viewController  successBlock:(GenericBlock)success failureBlock:(GenericBlock)failure
{
    [FacebookUtility getAccount:^(NSDictionary* user) {
        Account* account = [Account accountFromFBUser:user];
        
        if (![account.gender isEqualToString:@"male"] && ![account.gender isEqualToString:@"female"]) {
            [WFCore showAlert:nil text:@"We can’t find your gender on Facebook." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:0];
            if (failure) failure();
            return;
        }
        
        if ([account.email isEqualToString:@""]) {
            [WFCore showAlert:nil text:@"Your email address has not been verified by Facebook." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:0];
            if (failure) failure();
            return;
        }
        
        if (account.age < 18) {
            [WFCore showAlert:nil text:@"You must be at least 18 years old to use Wyldfire." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:0];
            if (failure) failure();
            return;
        }
        
        //If new user has logged in
        if (account.facebookID != [GVUserDefaults standardUserDefaults].facebookID) {
            [self resetLocalAccount];
        }
        
        if (![self loggedIn] && [self account].facebookIcon) {
            [self setImageFromURL:[self account].facebookIcon type:1 success:success failure:success];
        }
        [self saveAccount:account];
            
        if (account.birthDate) {
           [Kiip sharedInstance].birthday = account.birthDate;
        }
        
        [self nextActionAfterFacebookLogin:viewController successBlock:success failureBlock:failure];

    } failure:^(NSInteger code) {
        [WFCore showAlert:@"Cannot connect to Facebook" msg:@"We are unable to retrieve your account from Facebook. Please check your device settings or try again later." delegate:nil confirmHandler:nil];
        [self.session closeAndClearTokenInformation];
        if (failure) failure();
    }];
}

- (void)nextActionAfterLogin:(UIViewController*)viewController
{
    if (!WFCore.account.isOk) {
        [viewController.navigationController pushViewController:[UnderReViewController new] animated:YES];
        return;
    }

    // Male + Female sign up flows have different orders
    [self getStats:^(Stats *stats) {

        // Male Sign Up Flow:
        if (WFCore.account.isMale) {
            if (!WFCore.account.hasFeather) {                                                              //Waiting
                [WFCore showViewController:viewController name:@"Waiting" mode:nil params:nil];
            } else
            if (![GVUserDefaults standardUserDefaults].hasFinishedSetup) {                          //Setup Photos
                [self setupAlbums:viewController main:YES];
            } else {
                [[WFCore get] putLocation:nil failure:nil];
                [WFCore showViewController:viewController name:@"Browse" mode:nil params:nil];      //Browse
            }
        } else {
            // Female Sign Up Flow:
            if (![GVUserDefaults standardUserDefaults].hasFinishedSetup) {                          //Showcase Photo
                [self setupAlbums:viewController main:YES];
            } else
            if (WFCore.account.stats.sentInvites == 0) {
                [WFCore showViewController:viewController name:@"Waiting" mode:nil params:nil];     //Waiting
            } else {
                [[WFCore get] putLocation:nil failure:nil];
                [WFCore showViewController:viewController name:@"Browse" mode:nil params:nil];      //Browse
            }
        }
    }];
}

- (void)setupAlbums:(UIViewController*)viewController main:(BOOL)mainMode
{
    id params = mainMode ? @{ @"_main": @1 } : @{ @"_multiple": @1 };
    [WFCore showViewController:viewController name:@"Album" mode:nil params:params];
}

- (void)saveAccount:(Account*)account
{
    [WFCore get].accountStructure = account;
    [GVUserDefaults standardUserDefaults].name = account.name;
    [GVUserDefaults standardUserDefaults].email = account.facebookEmail;
    [GVUserDefaults standardUserDefaults].facebookID = account.facebookID;
}

#pragma mark - Matches

- (long long)now
{
    return ([[NSDate date] timeIntervalSince1970] - 10) * 1000;
}

- (void)refresh
{
    if (!self.loggedIn) return;
    
    [self refreshStats];
    [self storePendingMatches];
    [self downloadNewMessages];
    [self checkBlackbookForNewContacts];
}

- (void)getPendingMatches:(void (^)(NSArray* matches))success
{
    [self findReferencesOfType:@"match"
                         mtime:@([GVUserDefaults standardUserDefaults].lastMatchMtimeCheck)
                       success:^(NSArray *accounts) {
                           [GVUserDefaults standardUserDefaults].lastMatchMtimeCheck = [self now];
                           if (success) success(accounts);
                       } failure:^{
                           if (success) success(nil);
                       }];
}

- (void)storePendingMatches
{
    if (!self.loggedIn) return;
    if ([self now] - [GVUserDefaults standardUserDefaults].lastMatchMtimeCheck < 310000) return;
        
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:NO];
    [self getPendingMatches:^(NSArray *matches) {
        [self storePendingMatches:matches];
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    }];
}

- (void)storePendingMatches:(NSArray*)matches
{
    if (matches == nil) return;
    
    for (Account* account in matches) {
        DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:account.accountID];
        BOOL accountExists = (dbAccount != nil);
        if (!accountExists) dbAccount = [DBAccount createOrUpdateDBAccountWithAccountID:account.accountID account:nil];
        
        //Check if already have this account completely loaded
        if (!dbAccount.alias) {
            [self getUserAccount:account.accountID obj:nil success:^(Account *filledAccount, NSDictionary *json) {
                DBAccount* dbAccount = [DBAccount createOrUpdateDBAccountWithAccountID:account.accountID account:filledAccount];
                dbAccount.showInMatches = [NSNumber numberWithBool:YES];
                [dbAccount save];
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_PENDING_MATCHES object:self];
                if (dbAccount.avatarPhoto != nil) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NEW_MATCHES object:self userInfo:@{@"senderID" : account.accountID}];
                }
                
                if ([dbAccount.inBlackbook boolValue] && dbAccount.avatarPhoto) {
                    //cant tell if this is new in the blackbook here
                    //Wont have sent if the dbAccount wasn't filled in with alias and avatar photo
                    //[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NEW_CONTACT object:self];
                    //[[GVUserDefaults standardUserDefaults] addNotebookUnseenAccount:account.accountID];
                    //[self checkKiipContactRelatedRewardsForAccountID:dbAccount.accountID];
                }
                
                [self checkForReferenceType:@"blackbook" byUser:account success:^(BOOL connectionExists) {
                    if (connectionExists) {
                        dbAccount.sentShareTo = [NSNumber numberWithBool:YES];
                    }
                } failure:nil];
                
            } failure:nil];
        }
        
        //Check if images are loaded
        for (int i = 0 ; i < 2; i++) {
            if ((dbAccount.avatarPhoto == nil && i == 1) ||
                (dbAccount.showcasePhoto == nil && i == 0) ||
                (dbAccount.profilePhoto1 == nil && i == 2)) {
                [self getAccountImageOfType:i account:account.accountID success:^(UIImage *image, NSString *url) {
                    [account setImage:image forType:i];
                    [DBAccount createOrUpdateDBAccountWithAccountID:account.accountID account:account];
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATED_PENDING_MATCHES object:self];
                                        
                    if (i == 1) {
                        if ([dbAccount.inBlackbook boolValue]) {
                            //Wont have sent if the avatar wasn't loaded
                            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NEW_CONTACT object:self];
                            [[GVUserDefaults standardUserDefaults] addNotebookUnseenAccount:account.accountID];
                            [self checkKiipContactRelatedRewardsForAccountID:dbAccount.accountID];
                        }
                        //Wont have sent if the avatar wasn't loaded
                        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NEW_MATCHES object:self userInfo:@{@"senderID" : account.accountID}];
                    }
                } failure:nil];
            }
        }
    }
}

#pragma mark - Messages

- (void)downloadNewMessages
{
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:NO];
    [self downloadMessages:nil notify:YES finished:^{
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    }];
}

- (void)downloadMessages:(NSString*)path notify:(BOOL)notify finished:(GenericBlock)finished
{
    if (!self.loggedIn) {
        if (finished) finished();
        return;
    }
    
    [self getData:[NSString stringWithFormat:@"/message/get%@", path ?: @""]
           method:@"POST"
           params:@{ @"_archive" : @1 }
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              NSArray* list = [WFCore toArray:json name:@"data"];
              for (NSDictionary* msg in list) {
                  if ([msg[@"icon"] isKindOfClass:[NSString class]]) {
                      [self getImageForPath:msg[@"icon"] success:^(UIImage *image, NSString *url) {
                          [Message createMessageWithSenderAccountID:msg[@"sender"] ?: self.account.accountID
                                                              mtime:[WFCore toNumber:msg name:@"mtime"]
                                                               text:[WFCore toString:msg name:@"msg"]
                                                              image:image
                                                               sent:NO
                                                             notify:notify];
                      } failure:nil];
                  } else {
                      [Message createMessageWithSenderAccountID:msg[@"sender"] ?: self.account.accountID
                                                          mtime:[WFCore toNumber:msg name:@"mtime"]
                                                           text:[WFCore toString:msg name:@"msg"]
                                                          image:nil
                                                           sent:NO
                                                         notify:notify];
                  }
              }
              if (finished) finished();
          }
          failure:^(NSInteger code, NSError *error, id json) {
              if (finished) finished();
          }];
}

- (void)checkHintsUsedInLast24Hours
{
    if (!self.loggedIn) return;
    
    [self getData:@"/connection/get"
           method:@"POST"
           params:@{@"type" : @"hint",
                    @"mtime" : @([self now] - 86400000),
                    @"_ops"  : @"mtime,ge"}
      contentType:@"application/json"
          success:^(NSDictionary* json) {
              [GVUserDefaults standardUserDefaults].hintsToday = [WFCore toNumber:json name:@"count"];
          } failure:^(NSInteger code, NSError *error, id json) {
              [GVUserDefaults standardUserDefaults].hintsToday = 3;
          }];
}

#pragma mark Report User

- (void)reportUser:(Account*)userAccount
           success:(GenericBlock)success failure:(GenericBlock)failure
{
    [self getData:@"/wf/complaint"
           method:@"POST"
           params:@{@"id"   : userAccount.accountID,
                    @"descr" : @"text"}
      contentType:@"application/json"
          success:^(id obj) {
              if (success) success();
          } failure:^(NSInteger code, NSError *error, id json) {
              if (failure) failure();
          }];
}

#pragma mark Check for new burns

- (void)checkLocalAccountStatusesWithServer
{
    if (!self.loggedIn) return;

    NSArray* localValidAccounts = [DBAccount retrieveAccountIDsNotBurned];
    if (localValidAccounts.count == 0) return;
    
    [self getData:@"/reference/get"
           method:@"POST"
           params:@{ @"type": @"burn" }
      contentType:@"application/json"
          success:^(NSDictionary *json) {
              NSArray* accountList = json[@"data"];
              
              for (NSDictionary* accountDic in accountList) {
                  NSString* accountID = accountDic[@"id"];
                  if ([localValidAccounts containsObject:accountID]) {
                      DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:accountID];
                      dbAccount.burned = [NSNumber numberWithBool:YES];
                      [dbAccount save];
                  }
              }
          }
          failure:nil];
    
    [self getData:@"/account/get"
           method:@"POST"
           params:@ { @"id": [localValidAccounts componentsJoinedByString:@","] }
      contentType:@"application/json"
          success:^(NSArray* accountList) {
              NSMutableArray* returnedAccountIDs = [NSMutableArray new];
              
              for (NSDictionary* accountDic in accountList) {
                  NSString* accountID = accountDic[@"id"];
                  [returnedAccountIDs addObject:accountID];
              }
              
              for (NSString* accountID in localValidAccounts) {
                  if (![returnedAccountIDs containsObject:accountID]) {
                      DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:accountID];
                      dbAccount.burned = [NSNumber numberWithBool:YES];
                      [dbAccount save];
                  }
              }
          }
          failure:nil];
}

@end
