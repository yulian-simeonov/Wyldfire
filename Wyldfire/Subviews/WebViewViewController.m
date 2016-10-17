//
//  WebViewViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/30/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "WebViewViewController.h"

@interface WebViewViewController ()

@end

@implementation WebViewViewController

+ (WebViewViewController*)initWithDelegate:(id<UIWebViewDelegate>)delegate completionHandler:(WebViewCompletionBlock)completionHandler
{
    WebViewViewController *view = [[WebViewViewController alloc] init];
    view.webview.delegate = delegate;
    view.completionHandler = completionHandler;
    return view;
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(id)init
{
    self = [super init];
    self.view = [[UIView alloc] initWithFrame:[[[UIApplication sharedApplication] delegate] window].bounds];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.contentMode = UIViewContentModeRedraw;
    
    self.webview = [[UIWebView alloc] initWithFrame:CGRectInset(self.view.frame, 0, 0)];
    self.webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webview.layer.masksToBounds = YES;
    self.webview.layer.cornerRadius = 0;
    [self.view addSubview:self.webview];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 32, 32);
    [button setImage:[UIImage imageNamed:@"black_close"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:button];
    
    return self;
}

- (void)start:(NSURLRequest*)request completionHandler:(WebViewViewCompletionBlock)completionHandler
{
    self.completionHandler = completionHandler;
    [self.webview loadRequest:request];
    [self showActivity];
}

- (void)finish:(NSURLRequest*)request error:(NSError*)error
{
    if (self.completionHandler) self.completionHandler(request, error);
    self.completionHandler = nil;
    [self hide];
}

- (void)cancel
{
    [self finish:nil error:nil];
}

- (void)show
{
    if (self.presentingViewController) return;
    self.root = [WFCore topMostController];
    [self.root presentViewController:self animated:YES completion:nil];
}

- (void)hide
{
    [self hideActivity];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showActivity
{
    [[WFCore get] showActivity];
}

- (void)hideActivity
{
    [[WFCore get] hideActivity];
}


@end
