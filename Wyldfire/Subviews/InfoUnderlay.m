//
//  InfoUnderlay.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/23/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "InfoUnderlay.h"

@interface InfoUnderlay ()
@property UIImageView* phoneButton;
@property UIImageView* instagramButton;
@property UIImageView* facebookButton;
@end

@implementation InfoUnderlay

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = GRAY_1;
        
        
        NSArray* buttonImages = @[@"phone", @"instagram", @"facebook"];
        
        
        CGRect rect = CGRectMake(0, 0, self.height, 60);
        CGFloat separatorWidth = 1;
        
        NSMutableArray* buttons = [NSMutableArray new];
        for (int i = 0; i < buttonImages.count; i++) {
            CGRect specificRect = CGRectOffset(rect, i * (rect.size.width + separatorWidth), 0);
            [buttons addObject:[self addImageButton:buttonImages[i] rect:specificRect]];
        }
        
        self.phoneButton = buttons[0];
        self.instagramButton = buttons[1];
        self.facebookButton = buttons[2];
        
        [self setDisabledIcons];
    }
    return self;
}

- (UIImageView*)addImageButton:(NSString*)imageName rect:(CGRect)rect
{
    UIButton* button = [[UIButton alloc] initWithFrame:rect];
    
    [button addTarget:self action:NSSelectorFromString(imageName) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    [button.imageView setContentMode:UIViewContentModeCenter];
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    imageView.center = button.center;
    [self addSubview:imageView];
    
    UIView* separator = [[UIView alloc] initWithFrame:CGRectMake(button.right, 15, 1, self.height - 30)];
    separator.backgroundColor = [UIColor colorWithRed:56./255. green:58./255. blue:59./255. alpha:1.0];
    [self addSubview:separator];
    
    return imageView;
}

- (void)setDisabledIcons
{
    self.instagramButton.tintColor = (self.account.instagramUsername ? nil : GRAY_2);
    self.phoneButton.tintColor = (self.account.phone ? nil : GRAY_2);
}

- (void)setAccount:(Account *)account
{
    _account = account;
    [self setDisabledIcons];
}

#pragma mark - Actions

- (void)phone
{
    if (self.account.phone == nil) return;
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", self.account.phone]]];
}

- (void)instagram
{
    NSURL *url = [NSURL URLWithString:@"instagram://app"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        if (self.account.instagramUsername == nil) return;
        
        [self showWebURLString:[NSString stringWithFormat:@"http://www.instagram.com/%@", self.account.instagramUsername]];
    }
}

- (void)facebook
{
    NSURL *url = [NSURL URLWithString:@"fb://profile"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        [self showWebURLString:[NSString stringWithFormat:@"http://www.facebook.com/%lld", self.account.facebookID]];
    }
}

- (void)showWebURLString:(NSString*)urlString
{
    NSLog(@"showURL: %@", urlString);
    WebViewViewController* vc = [WebViewViewController initWithDelegate:nil completionHandler:nil];
    [vc start:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] completionHandler:nil];
    [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:vc animated:YES completion:nil];
}

@end
