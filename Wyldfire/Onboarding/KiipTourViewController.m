//
//  KiipTourViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 5/9/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "KiipTourViewController.h"

@interface KiipTourViewController () <UIScrollViewDelegate> {
    CGFloat statusHei;
}
    @property (strong, nonatomic) UIScrollView* imageScrollView;
    @property (strong, nonatomic) NSMutableArray* imageViews;
    @property (strong, nonatomic) UIPageControl* pageControl;
    @property (strong, nonatomic) UIButton* goButton;
@end

@implementation KiipTourViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.view.bounds = [UIScreen mainScreen].bounds;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupScrollView];
    
    [self addImages];
    [self setupButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.imageScrollView setContentOffset:CGPointZero];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.imageScrollView setContentOffset:CGPointZero animated:YES];
}

- (void)setupScrollView
{
    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.backgroundColor = GRAY_3;
    
    self.imageScrollView = scrollView;
    [self.view addSubview:scrollView];
    
    //Page Control
    CGRect pageControlFrame = [self pageControlFrame];
    UIPageControl* pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
    pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
    pageControl.currentPageIndicatorTintColor = WYLD_RED;
    
    self.pageControl = pageControl;
    [self.view addSubview:pageControl];
    
    self.imageViews = [NSMutableArray new];
}

- (CGRect)pageControlFrame
{
    return CGRectMake(0,
                      self.view.bottom - 86,
                      320,
                      40);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0)];
}

- (UIImageView*)imageView
{
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imgView.contentMode = UIViewContentModeScaleToFill;
    imgView.clipsToBounds = YES;
    
    return imgView;
}

- (void)addImages
{
    for (int i = 1; i <=2; i++) {
        NSString* imgName = [NSString stringWithFormat:@"Kiip_Tour_%i%@.jpg", i, TALL_SCREEN ? @"" : @"i4"];
        UIImage* image = [UIImage imageNamed:imgName];
        UIImageView* imgView = [self imageView];
        
        [self.imageViews addObject:imgView];
        imgView.image = image;
    }
    
    [self updateScrollview];
}

- (void)updateScrollview
{
    NSInteger numberOfImages = self.imageViews.count;
    
    [self.imageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight([UIScreen mainScreen].bounds);
    [self.imageScrollView setContentSize:CGSizeMake(width * numberOfImages, height)];
    
    for (int i = 0; i < numberOfImages; i++) {
        UIImageView* imgView = self.imageViews[i];
        
        CGRect frame = CGRectMake(i * width,
                                  0,
                                  width,
                                  height);
        imgView.frame = frame;
        [self.imageScrollView addSubview:imgView];
    }
    [self.imageScrollView scrollRectToVisible:self.view.bounds animated:NO];
    
    self.pageControl.numberOfPages = numberOfImages;
    self.pageControl.currentPage = 0;
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat width = CGRectGetWidth(self.view.frame);
    int page = scrollView.contentOffset.x / width;
    self.pageControl.currentPage = page;
}

- (void)setupButton
{
    self.goButton = [self addButtonWithTitle:@"Ok, got it!" backgroundColor:WYLD_RED frame:[self bottomButtonRect] selectorString:@"pressedGo"];
}

- (void)pressedGo
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.poptart show];
}

#pragma mark - Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resize:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
}

- (void)resize:(NSNotification*)notification
{
    CGRect statusBarFrame = [((NSValue*)notification.userInfo[UIApplicationStatusBarFrameUserInfoKey]) CGRectValue];
    statusHei = statusBarFrame.size.height;
    
    [UIView animateWithDuration:0.2 delay:0.0 options:0
                     animations:^{
                         [self repositionElements];
                     } completion:nil];
}

- (void) repositionElements {
    
    if (statusHei > 20) {
        CGRect frame = self.pageControl.frame;
        frame.origin.y -= 20;
        self.pageControl.frame = frame;
        frame = self.goButton.frame;
        frame.origin.y -= 20;
        self.goButton.frame = frame;
        frame = self.imageScrollView.frame;
        frame.origin.y = frame.origin.y == 0 ? 0 : frame.origin.y+20;
        self.imageScrollView.frame = frame;
    } else {
        CGRect frame = self.pageControl.frame;
        frame.origin.y += 20;
        self.pageControl.frame = frame;
        frame = self.goButton.frame;
        frame.origin.y += 20;
        self.goButton.frame = frame;
        frame = self.imageScrollView.frame;
        frame.origin.y = frame.origin.y == 0 ? 0 : frame.origin.y-20;
        self.imageScrollView.frame = frame;
    }
}

@end
