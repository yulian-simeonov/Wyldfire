//
//  SocialAccount.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 12/1/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

@interface SocialAccount () <UIWebViewDelegate>
@property (nonatomic, strong) NSString* jsonDataName;
@property (nonatomic, strong) NSString* jsonTokenName;
@property (nonatomic, strong) WebViewController *loginView;

@property (nonatomic, strong) NSString *oauthRealm;
@property (nonatomic, strong) NSString *oauthSignature;
@property (nonatomic, strong) NSMutableDictionary *oauthToken;
@end

@implementation SocialAccount {
    AFHTTPClient *_http;
}

- (void)getAccount:(SuccessBlock)success failure:(FailureBlock)failure { if (failure) failure(-1); };
- (void)getFriends:(SuccessBlock)success failure:(FailureBlock)failure { if (failure) failure(-1); };
- (void)getAlbums:(SuccessBlock)success failure:(FailureBlock)failure { if (failure) failure(-1); };
- (void)getPhotos:(NSString*)album success:(SuccessBlock)success failure:(FailureBlock)failure { if (failure) failure(-1); };
- (void)getMutualFriends:(NSString*)name success:(SuccessBlock)success failure:(FailureBlock)failure { if (failure) failure(-1); };
- (NSString*)getNextURL:(id)result { return nil; }

- (id)init:(NSString*)name clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret
{
    self = [super init];
    self.name = name;
    self.clientId = clientId;
    self.clientSecret = clientSecret;
    self.accessToken = [SSKeychain passwordForService:self.clientId account:self.name];
    self.jsonTokenName = @"access_token";
    self.jsonDataName = @"data";
    self.oauthSignature = @"HMAC-SHA1";
    self.account = @{};
    return self;
}

- (BOOL)isOpen
{
    return self.accessToken != nil;
}

// List of objects with "url" and "name" properties
- (BOOL)launch
{
    for (NSDictionary *item in self.launchURLs) {
        if ([WFCore isEmpty:self.account name:item[@"name"]]) return NO;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:item[@"url"],self.account[item[@"name"]]]];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            return [[UIApplication sharedApplication] openURL:url];
        }
    }
    return NO;
}

// By default save id and username for each social account, some API requests work by id some only by username
- (void)saveAccount
{
    WFCore *core = [WFCore get];
    NSString *aid = [NSString stringWithFormat:@"%@_id",self.name];
    NSString *aname = [NSString stringWithFormat:@"%@_username",self.name];
    
    core.account[aid] = [WFCore toString:self.account[@"id"]];
    core.account[aname] = [WFCore toString:self.account[@"username"]];
//    [core saveAccount:@[aid,aname]];
}

- (NSString*)getURL:(NSString*)path
{
    return [NSString stringWithFormat:@"%@%@%@&access_token=%@", self.apiURL, path, [path rangeOfString:@"?"].location == NSNotFound ? @"?" : @"", self.accessToken];
}

// Parse access token from the url or the data,
// OAuth 2.0 uses the url fragment in the redirect url: fb12345://authorize#access_token=...&...
- (BOOL)parseAccessToken:(NSURLRequest*)request
{
    NSMutableDictionary *query = [WFCore parseQueryString:[[request URL] fragment]];
    self.accessToken = [query[self.jsonTokenName] copy];
    if (![WFCore isEmpty:self.accessToken]) {
        [SSKeychain setPassword:self.accessToken forService:self.clientId account:self.name];
    } else {
        self.accessToken = nil;
    }
    [self.loginView finish:request error:nil];
    return NO;
}

- (void)getData:(NSString*)path params:(NSDictionary*)params success:(SuccessBlock)success failure:(FailureBlock)failure
{
    GenericBlock relogin = ^() {
        [self login:^(NSURLRequest *request, NSError *error) {
            if (![self isOpen]) {
                if(failure) failure(error ? error.code : -1);
            } else {
                [self getJSON:path method:nil params:params headers:nil success:success
                      failure:^(NSInteger code, NSError *error, id json) {
                          if(failure) failure(code);
                      }];
            }
        }];
    };
    
    if (![self isOpen]) {
        relogin();
        return;
    }
    
    [self getJSON:path method:nil params:params headers:nil success:success
          failure:^(NSInteger code, NSError *error, id json) {
              // Token expired, try to login and send again
              relogin();
          }];
}

- (void)getJSON:(NSString*)path method:(NSString*)method params:(NSDictionary*)params headers:(NSDictionary*)headers success:(SuccessBlock)success failure:(JSONFailureBlock)failure
{
    NSLog(@"getJSON: %@: %@: %@", self.name, path, params);
    
    NSMutableArray *items = [@[] mutableCopy];
    [[APIClient sharedClient] getJSON:[self getURL:path] method:nil params:params headers:nil
                  success:^(id result) {
                      [self processResult:result items:items success:success failure:^(NSInteger code) { if (failure) failure(code, nil, nil); }];
                  }
                  failure:^(NSInteger code, NSError *error, id json) {
                      if(failure) failure(code, error, json);
                  }];
}

- (void)processResult:(id)result items:(NSMutableArray*)items success:(SuccessBlock)success failure:(FailureBlock)failure
{
    // Result is not a list, return as is
    if (![result isKindOfClass:[NSDictionary class]] || ![result[self.jsonDataName] isKindOfClass:[NSArray class]]) {
        if (success) success(result);
        return;
    }
    // Result is a list, check for more items
    for (id item in [WFCore toArray:result name:self.jsonDataName]) [items addObject:item];
    NSString *url = [self getNextURL:result];
    if (url && url.length) {
        [self nextResult:url items:items success:success failure:failure];
        return;
    }
    if (success) success(@{ self.jsonDataName: items });
}

- (void)nextResult:(NSString*)path items:(NSMutableArray*)items success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [[APIClient sharedClient] getJSON:path method:nil params:nil headers:nil
                  success:^(id result) {
                      [self processResult:result items:items success:success failure:failure];
                  }
                  failure:^(NSInteger code, NSError *error, id json) {
                      if(failure) failure(code);
                  }];
}

- (void)login:(WebViewCompletionBlock)completionHandler
{
    NSLog(@"login: %@: %@", self.name, self.authURL);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.authURL]];
    [self showWebView:request completionHandler:completionHandler];
}

- (void)logout
{
    self.account = @{};
    self.accessToken = nil;
    [SSKeychain deletePasswordForService:self.clientId account:self.name];
    [self clearCookies];
}

- (void)clearCookies
{
    if (!self.cookiesURL) return;
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:self.cookiesURL]];
    for (NSHTTPCookie *cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

- (void)showWebView:(NSURLRequest*)request completionHandler:(WebViewCompletionBlock)completionHandler
{
    self.accessToken = nil;
    if (!self.loginView) self.loginView = [WebViewController initWithDelegate:self completionHandler:nil];
    [self.loginView start:request completionHandler:completionHandler];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"webview shouldStart: %@", [request URL]);
    
    if ([[[request URL] absoluteString] hasPrefix:self.redirectURL]) {
        return [self parseAccessToken:request];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webview started: %@", [webView.request URL]);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webview finished: %@", [webView.request URL]);
    [self.loginView show];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSString* url = error.userInfo[@"NSURLErrorFailingURLErrorKey"];
    if (![url hasPrefix:self.redirectURL]) {
        NSLog(@"webview failed: %@: %@", [webView.request URL], error);
        [self.loginView finish:webView.request error:error];
    }
}

- (NSMutableDictionary *)oauthParameters
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"oauth_version"] = @"1.0";
    params[@"oauth_signature_method"] = self.oauthSignature;
    params[@"oauth_consumer_key"] = self.clientId;
    params[@"oauth_timestamp"] = [@(floor([[NSDate date] timeIntervalSince1970])) stringValue];
    params[@"oauth_nonce"] = [WFCore createUUID];
    if (self.oauthRealm) params[@"realm"] = self.oauthRealm;
    return params;
}

- (void)authorize:(NSString *)scope success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    if (!_http) _http = [[AFHTTPClient alloc] initWithBaseURL:[[NSURL alloc] initWithString:@""]];
    
    [self getRequestToken:scope success:^(NSMutableDictionary *requestToken) {
        NSDictionary *params = @{ @"oauth_token": [WFCore toString:requestToken name:@"oauth_token"] };
        NSMutableURLRequest *request = [_http requestWithMethod:@"POST" path:self.authURL parameters:params];
        [request setHTTPShouldHandleCookies:NO];
        NSLog(@"getRequestToken: %@", requestToken);
        
        [self showWebView:request completionHandler:^(NSURLRequest *request, NSError *error) {
            NSURL *url = [request URL];
            NSDictionary *query = [WFCore parseQueryString:[url query]];
            if (query[@"oauth_verifier"]) requestToken[@"oauth_verifier"] = query[@"oauth_verifier"];
            
            [self getAccessToken:requestToken success:^(NSMutableDictionary *accessToken) {
                if (accessToken) {
                    self.oauthToken = accessToken;
                    if (success) success(accessToken);
                } else {
                    if (failure) failure(nil);
                }
            } failure:^(NSError *error) {
                if (failure) failure(error);
            }];
        }];
        
    } failure:^(NSError *error) {
        if (failure) failure(error);
    }];
}

- (void)getRequestToken:(NSString *)scope success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    NSMutableDictionary *params = [self oauthParameters];
    params[@"oauth_callback"] = self.redirectURL;
    if (scope && !self.accessToken) params[@"scope"] = scope;
    
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:self.requestTokenURL parameters:params];
    [request setHTTPBody:nil];
    AFHTTPRequestOperation *operation = [_http HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSMutableDictionary *requestToken = [WFCore parseQueryString:operation.responseString];
            success(requestToken);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"getRequestToken: %@: error: %@", request.URL, error);
        if (failure) failure(error);
    }];
    [_http enqueueHTTPRequestOperation:operation];
}

- (void)getAccessToken:(NSMutableDictionary *)requestToken success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    if (requestToken && requestToken[@"oauth_token"] && requestToken[@"oauth_verifier"]) {
        self.oauthToken = requestToken;
        
        NSMutableDictionary *params = [self oauthParameters];
        params[@"oauth_token"] = requestToken[@"oauth_token"];
        params[@"oauth_verifier"] = requestToken[@"oauth_verifier"];
        NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:self.accessTokenURL parameters:params];
        AFHTTPRequestOperation *operation = [_http HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (success) {
                NSMutableDictionary *accessToken = [WFCore parseQueryString:operation.responseString];
                success(accessToken);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"getAccessToken: %@: error: %@", request.URL, error);
            if (failure) failure(error);
        }];
        [_http enqueueHTTPRequestOperation:operation];
    } else {
        NSError *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadServerResponse userInfo:@{ NSLocalizedFailureReasonErrorKey: @"Bad OAuth response received from the server" }];
        if (failure) failure(error);
    }
}

#pragma mark - AFHTTPClient

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    NSMutableDictionary *params = parameters ? [parameters mutableCopy] : [NSMutableDictionary dictionary];
    NSMutableDictionary *aparams = [NSMutableDictionary dictionary];
    NSString *token = self.oauthToken ? self.oauthToken[@"oauth_token"] : nil;
    NSString *secret = [WFCore toString:self.oauthToken name:@"oauth_token_secret"];
    
    if (token) {
        [aparams addEntriesFromDictionary:[self oauthParameters]];
        aparams[@"oauth_token"] = token;
    }
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] && [key hasPrefix:@"oauth_"]) aparams[key] = obj;
    }];
    [params addEntriesFromDictionary:aparams];
    
    if ([self.oauthSignature isEqualToString:@"PLAINTEXT"]) {
        aparams[@"oauth_signature"] = [NSString stringWithFormat:@"%@&%@", self.clientSecret, secret];
    }
    
    if ([self.oauthSignature isEqualToString:@"HMAC-SHA1"]) {
        NSMutableURLRequest *request = [_http requestWithMethod:method path:path parameters:params];
        NSString *secretString = [NSString stringWithFormat:@"%@&%@", [WFCore escape:self.clientSecret], [WFCore escape:secret]];
        NSData *secretData = [secretString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *queryString = [WFCore escape:[[[[[request URL] query] componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"&"]];
        NSString *requestString = [NSString stringWithFormat:@"%@&%@&%@", [request HTTPMethod], [WFCore escape:[[[request URL] absoluteString] componentsSeparatedByString:@"?"][0]], queryString];
        NSData *requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding];
        
        uint8_t digest[CC_SHA1_DIGEST_LENGTH];
        CCHmacContext cx;
        CCHmacInit(&cx, kCCHmacAlgSHA1, secretData.bytes, secretData.length);
        CCHmacUpdate(&cx, requestData.bytes, requestData.length);
        CCHmacFinal(&cx, digest);
        aparams[@"oauth_signature"] = [WFCore base64Encode:[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH]];
    }
    
    NSArray *components = [[AFQueryStringFromParametersWithEncoding(aparams, NSUTF8StringEncoding) componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *items = [NSMutableArray array];
    for (NSString *component in components) {
        NSArray *parts = [component componentsSeparatedByString:@"="];
        if (parts.count != 2) continue;
        [items addObject:[NSString stringWithFormat:@"%@=\"%@\"", parts[0], parts[1]]];
    }
    NSString *authHeader = [NSString stringWithFormat:@"OAuth %@", [items componentsJoinedByString:@", "]];
    
    params = [parameters mutableCopy];
    for (NSString *key in parameters) {
        if ([key hasPrefix:@"oauth_"]) [params removeObjectForKey:key];
    }
    NSLog(@"request: %@: %@: %@", path, authHeader, params);

    NSMutableURLRequest *request = [_http requestWithMethod:method path:path parameters:params];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    [request setHTTPShouldHandleCookies:NO];
    return request;
}

@end;
