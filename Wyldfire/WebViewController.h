//
//  WebViewController.h
//  Wyldfire
//
//  Created by Vlad Seryakov on 12/2/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

typedef void (^WebViewCompletionBlock)(NSURLRequest *req, NSError *err);

@interface WebViewController: UIViewController
@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UIViewController *root;
@property (nonatomic, strong) WebViewCompletionBlock completionHandler;

+ (WebViewController*)initWithDelegate:(id<UIWebViewDelegate>)delegate completionHandler:(WebViewCompletionBlock)completionHandler;
- (void)start:(NSURLRequest*)request completionHandler:(WebViewCompletionBlock)completionHandler;
- (void)show;
- (void)hide;
- (void)finish:(NSURLRequest*)request error:(NSError*)error;
- (void)showActivity;
- (void)hideActivity;
@end
