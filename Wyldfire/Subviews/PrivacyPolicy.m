//
//  PrivacyPolicy.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/5/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "PrivacyPolicy.h"

@interface PrivacyPolicy () <UIWebViewDelegate>

@end

@implementation PrivacyPolicy

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        hud.labelText = @"Loading";
        
        NSURL* url = [NSURL URLWithString:PRIVACY_POLICY_URL];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        
        [self loadRequest:request];
    }
    return self;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [MBProgressHUD hideHUDForView:self animated:YES];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self animated:YES];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PRIVACY_POLICY_URL]];
    
    [self removeFromSuperview];
}

- (void)hide
{
    
}

@end
