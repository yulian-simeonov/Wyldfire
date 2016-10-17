//
//  WebViewViewController.h
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/30/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^WebViewViewCompletionBlock)(NSURLRequest *req, NSError *err);

@interface WebViewViewController : UIViewController

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UIViewController *root;
@property (nonatomic, strong) WebViewCompletionBlock completionHandler;


+ (WebViewViewController*)initWithDelegate:(id<UIWebViewDelegate>)delegate completionHandler:(WebViewViewCompletionBlock)completionHandler;
- (void)start:(NSURLRequest*)request completionHandler:(WebViewViewCompletionBlock)completionHandler;
- (void)show;
- (void)hide;
- (void)finish:(NSURLRequest*)request error:(NSError*)error;
- (void)showActivity;
- (void)hideActivity;

@end

