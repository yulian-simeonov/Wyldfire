//
//  AvatarEditViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 3/22/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "AvatarEditViewController.h"

@interface AvatarEditViewController ()

@property (nonatomic, strong) WFZoomView* zoomView;

@end

@implementation AvatarEditViewController

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)setupUI
{
    [self addZoomView];
    [self addHalo];
    [self addButtons];
}

- (void)addZoomView
{
    UIImage* image = self.params[@"fullImage"];
    
    WFZoomView* scrollView = [[WFZoomView alloc] initWithImage:image andFrame:self.view.bounds];
    scrollView.frame = self.view.bounds;
    
    [self.view addSubview:scrollView];
    self.zoomView = scrollView;
}

- (CGRect)haloRect
{
    CGFloat haloDiameter = 290.0f;
    
    return CGRectMake((self.view.width - haloDiameter) / 2,
                      (self.view.height - haloDiameter) / 2,
                      haloDiameter,
                      haloDiameter);
}

- (void)addHalo
{
    CGRect haloRect = [self haloRect];
    CGFloat haloDiameter = haloRect.size.width;
    
    CAShapeLayer *blurFilterMask = [CAShapeLayer layer];
    // Disable implicit animations for the blur filter mask's path property.
    blurFilterMask.actions = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"path", nil];
    blurFilterMask.fillColor = [UIColor blackColor].CGColor;
    blurFilterMask.fillRule = kCAFillRuleEvenOdd;
    blurFilterMask.frame = self.view.bounds;
    blurFilterMask.opacity = 0.5f;
    [self.view.layer addSublayer:blurFilterMask];
    
    CGMutablePathRef blurRegionPath = CGPathCreateMutable();
    CGPathAddRect(blurRegionPath, NULL, self.view.bounds);
    CGPathAddEllipseInRect(blurRegionPath,
                           NULL,
                           CGRectMake(haloRect.origin.x,
                                      haloRect.origin.y,
                                      haloDiameter,
                                      haloDiameter));
    
    blurFilterMask.path = blurRegionPath;
    
    CGPathRelease(blurRegionPath);
    
    [self addLabel:[self haloRect]];
}


- (void)addLabel:(CGRect)rect
{
    CGRect labelRect = CGRectMake(0,
                                  rect.origin.y - 23 - 50,
                                  self.view.width,
                                  23);
    UILabel* label = [UILabel labelInRect:labelRect
                                 withText:@"Move and Scale"
                                    color:[UIColor whiteColor]
                                 fontSize:21];
    [self.view addSubview:label];
}

- (void)addButtons
{
    CGRect rect = CGRectMake(0,
                             self.view.bottom - 60,
                             100,
                             40);
    UIButton* button = [[UIButton alloc] initWithFrame:rect];
    [button setTitle:@"Cancel" forState:UIControlStateNormal];
    [button setTitleColor:WYLD_RED forState:UIControlStateNormal];
    [button.titleLabel setFont:FONT_MAIN(21)];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    
    
    rect = CGRectMake(self.view.width - 100,
                      self.view.bottom - 60,
                      100,
                      40);
    button = [[UIButton alloc] initWithFrame:rect];
    [button setTitle:@"Choose" forState:UIControlStateNormal];
    [button setTitleColor:WYLD_RED forState:UIControlStateNormal];
    [button.titleLabel setFont:FONT_MAIN(21)];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(choose) forControlEvents:UIControlEventTouchUpInside];
}

- (void)cancel
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)choose
{
    // Crop scaled version with crop rectangle
    CGRect cropRect = self.haloRect;
    
    //UIScrollView *contentScrollView = self.zoomView;
    
    UIGraphicsBeginImageContextWithOptions(cropRect.size,
                                           YES,
                                           [UIScreen mainScreen].scale);
    CGPoint offset=cropRect.origin;
    //CGPoint contentOffset = contentScrollView.contentOffset;
    
    //CGFloat xOffset = offset.x + contentOffset.x;
    //CGFloat yOffset = offset.y + contentOffset.y;
    
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), -offset.x, -offset.y);
    
    [self.zoomView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *visibleScrollViewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    MBProgressHUD* hud = [self showBlockingActivity];
    hud.labelText = @"Uploading...";
    [[APIClient sharedClient] uploadImage:visibleScrollViewImage
                                     type:1 success:^{
                                         [self hideBlockingActivity];
                                         [self.navigationController popToViewController:self.params[@"_edit"] animated:YES];
                                     } failure:^{
                                         [self hideBlockingActivity];
                                         [WFCore showAlert:@"Your image upload failed." msg:@"Please check your Internet connection or try again later." delegate:nil confirmHandler:nil];
                                     }];

}

#pragma mark - Draw Mask


@end
