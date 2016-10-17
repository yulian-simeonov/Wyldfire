//
//  AppTourViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/21/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "AppTourViewController.h"

@interface AppTourViewController () {
    
    CGFloat statusHei;
}
    @property (strong, nonatomic) UIScrollView* imageScrollView;
    @property (strong, nonatomic) NSMutableArray* imageViews;
    @property (strong, nonatomic) UIPageControl* pageControl;
    @property (strong, nonatomic) UIButton* facebookButton;

    @property (strong, nonatomic) UIImageView* animationImageView;
    @property (strong, nonatomic) MPMoviePlayerController* moviePlayer;

    @property (nonatomic) BOOL viewAppeared;
    @property (nonatomic) BOOL startedMovie;
    @property (nonatomic) BOOL finishedMovie;
    @property (nonatomic) BOOL secondMovie;

    @property (nonatomic, strong) UIImageView* backdrop;

    //Login may complete during Fade Out Animation
    @property BOOL startedLogin;
    @property (nonatomic) BOOL completedLogin;

    @property (nonatomic, strong) UIButton* privacyPolicyButton;

@end

@implementation AppTourViewController

#pragma mark Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupScrollView];
    
    [self addImages];
    [self setupFacebookButton];
    [self setupMovie:@"Main"];
    [self addBackdrop];
    [self subscribeToNotifications];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.viewAppeared = YES;
    
    [self checkMovieStatus:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.startedLogin && !self.completedLogin) {   //When coming back from the web view login method
        self.facebookButton.alpha = 0.0;
        self.pageControl.alpha = 0.0;
        self.privacyPolicyButton.alpha = 0.0;
        return;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.moviePlayer.view removeFromSuperview];
    self.moviePlayer = nil;
    self.pageControl.alpha = 1.0;
    self.facebookButton.alpha = 1.0;
    [self removeBackdrop];
}

#pragma mark UI setup

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)addBackdrop
{
    NSString* filename = TALL_SCREEN ? @"start" : @"starti4";
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:filename]];
    
    [self.view addSubview:imgView];
    self.backdrop = imgView;
}

- (void)removeBackdrop
{
    [self.backdrop removeFromSuperview];
    self.backdrop = nil;
}

- (void)setupFacebookButton
{
    self.facebookButton = [self addButtonWithTitle:@"Connect with Facebook"
                                   backgroundColor:FB_BLUE
                                             frame:[self bottomButtonRect]
                                    selectorString:@"facebookPressed"];
    self.facebookButton.alpha = 0.0;
}

- (void)setupScrollView
{
    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.backgroundColor = [UIColor whiteColor];
    
    self.imageScrollView = scrollView;
    [self.view addSubview:scrollView];
    
    //[self addObscurants];
    
    //Page Control
    CGRect pageControlFrame = [self pageControlFrame];
    UIPageControl* pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
    pageControl.alpha = 0;
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

- (void)addImages
{
    BOOL firstImage = YES;
    for (int i = 0; i <=5; i++) {
        UIImage* image = [UIImage imageNamed:[NSString stringWithFormat:@"WF_Tour%i%@.jpg", i, (TALL_SCREEN ? @"" : @"i4")]];
        UIImageView* imgView = [self imageView];
        
        imgView.frame = [[UIScreen mainScreen] bounds];
        
        [self.imageViews addObject:imgView];
        imgView.image = image;
        
        if (firstImage) {
            firstImage = NO;
            UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 60)];
            button.alpha = 0.0;
            [button addTarget:self action:@selector(showPrivacyPolicy) forControlEvents:UIControlEventTouchUpInside];
            [imgView addSubview:button];
            imgView.userInteractionEnabled = YES;
            self.privacyPolicyButton = button;
        }
    }
    
    [self updateScrollview];
}

- (void)showPrivacyPolicy
{
    WebViewViewController* vc = [WebViewViewController initWithDelegate:nil completionHandler:nil];
    [vc start:[NSURLRequest requestWithURL:[NSURL URLWithString:PRIVACY_POLICY_URL]] completionHandler:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)updateScrollview
{
    NSInteger numberOfImages = self.imageViews.count;
    
    [self.imageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    CGFloat width = CGRectGetWidth(self.imageScrollView.frame);
    CGFloat height = CGRectGetHeight(self.imageScrollView.frame);
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
    
    self.pageControl.numberOfPages = numberOfImages;
    self.pageControl.currentPage = 0;
    self.pageControl.alpha = 0.0;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat width = CGRectGetWidth(self.view.frame);
    int page = scrollView.contentOffset.x / width;
    self.pageControl.currentPage = page;
}

#pragma mark Movies

- (void)setupMovie:(NSString*)filename
{
    //To keep track of state
    self.startedMovie = NO;
    self.finishedMovie = NO;
    
    // URL to the Movie
    if (!TALL_SCREEN) filename = [filename stringByAppendingString:@"i4"];
    NSURL* movieURL =[[NSBundle mainBundle] URLForResource:filename withExtension:@"mov"];
    
    // Setup Movie Player
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
    self.moviePlayer.movieSourceType                = MPMovieSourceTypeFile;
    self.moviePlayer.backgroundView.backgroundColor = [UIColor clearColor];
    self.moviePlayer.backgroundView.opaque          = NO;
    self.moviePlayer.view.opaque                    = NO;
    self.moviePlayer.view.frame                     = self.view.bounds;
    self.moviePlayer.controlStyle                   = MPMovieControlStyleNone;

    // Movie related Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkMovieStatus:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];

    [self.moviePlayer prepareToPlay];
}

- (void)checkMovieStatus:(NSNotification*)notification
{
    // If the movie is ready to play, add it to the screen (this avoids a black flash)
    if(self.moviePlayer.loadState & (MPMovieLoadStatePlayable | MPMovieLoadStatePlaythroughOK))
    {
        if (self.viewAppeared && !self.startedMovie) {
            self.startedMovie = YES;
            [self.view addSubview:self.moviePlayer.view];
            [self.moviePlayer play];
            [self removeBackdrop];
        }
    }
}

- (void)playbackFinished:(NSNotification*)notification
{
    //Added by Yurii on 06/16/14
    NSError *error;
    [[AVAudioSession sharedInstance] setActive:NO withFlags:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (!self.secondMovie) {
        [self begin];
    } else {
        self.finishedMovie = YES;
        [self addBackdrop];
        [self takeNextActionIfReady];
    }
}

#pragma mark After First Movie

- (void)begin
{
    if ([[GVUserDefaults standardUserDefaults] hasConnected] && [self.view locationServicesEnabled]) {
        UIImageView* imgView = [[UIImageView alloc] initWithImage:[self snapshotOfView]];
        [self.moviePlayer.view removeFromSuperview];
        self.moviePlayer = nil;
        [self removeBackdrop];
        imgView.frame = self.view.bounds;
        [self.view addSubview:imgView];
        self.backdrop = imgView;
        [self loginWithFailureBlock:^{
            [self fadeOutMovieIntoPage];
        }];
    } else {
        [self fadeOutMovieIntoPage];
    }
}

- (void)fadeOutMovieIntoPage
{
    // Fade out the movie, into the initial page
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         self.moviePlayer.view.alpha = 0.0;
                         self.backdrop.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [self.moviePlayer.view removeFromSuperview];
                         self.moviePlayer = nil;
                         [self removeBackdrop];
                         
                         [self slideInFacebookButtonAndPageControl];
                     }];
    
    if (![self.view locationServicesEnabled]) {
        [self.navigationController pushViewController:[LocationServicesViewController new] animated:YES];
    }
}

- (void)slideInFacebookButtonAndPageControl
{
    if (self.startedLogin && !self.completedLogin) {   //When coming back from the web view login method
        self.facebookButton.alpha = 0.0;
        self.pageControl.alpha = 0.0;
        self.privacyPolicyButton.alpha = 0.0;
        return;
    }
    
    if (self.privacyPolicyButton.alpha == 0.0) {
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.privacyPolicyButton.alpha = 1.0;
                         } completion:nil];
    }
    
    //Check if the buttons are already onscreen
    if (self.pageControl.alpha == 1.0 && self.facebookButton.alpha == 1.0 &&
        CGRectEqualToRect(self.pageControl.frame, [self pageControlFrame]) &&
        CGRectEqualToRect(self.facebookButton.frame, [self bottomButtonRect])) {
        return;
    }
    
    self.pageControl.alpha = 1.0;
    self.facebookButton.alpha = 1.0;
    
    CGRect rect1 = [self pageControlFrame];
    CGRect rect2 = [self bottomButtonRect];
    
    self.pageControl.frame = CGRectOffset(rect1, 0, 300);
    self.facebookButton.frame  = CGRectOffset(rect2, 0, 300);
    
    [UIView animateWithDuration:1.0 delay:0.0 options:0
                     animations:^{
                         self.pageControl.frame = rect1;
                         self.facebookButton.frame  = rect2;
                     } completion:nil];
}

- (void)loginWithFailureBlock:(GenericBlock)failure
{
    //If already connected and location services are enabled, then start to login and use the fade out movie
    self.secondMovie = YES;
    [self setupMovie:@"FadeOut"];
    
    self.startedLogin = YES;
    [[APIClient sharedClient] facebookLogin:self successBlock:^{
        Account* account = [WFCore get].accountStructure;
        [Crashlytics setObjectValue:account.alias ?: @"None" forKey:@"alias"];
        [Crashlytics setObjectValue:account.accountID ?: @"None" forKey:@"accountID"];
        self.completedLogin = YES;
        [self takeNextActionIfReady];
        self.startedLogin = NO;
    } failureBlock:^{
        [GVUserDefaults standardUserDefaults].email = nil;
        [[APIClient sharedClient].session closeAndClearTokenInformation];
        [[APIClient sharedClient] checkFacebookStatus:nil];
        self.startedLogin = NO;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self fadeOutMovieIntoPage];
    }];
}

#pragma mark Actions

- (void)takeNextActionIfReady
{
    if (self.finishedMovie && self.completedLogin) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [[APIClient sharedClient] nextActionAfterLogin:self];
    } else
    if (self.finishedMovie && ! self.completedLogin) {
        MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Connecting";
    } else
    if (self.completedLogin && (!self.finishedMovie) && (self.moviePlayer == nil)) {   //When coming back from the web view login method
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve
                         animations:^{
                             self.facebookButton.alpha = 0.0;
                             self.pageControl.alpha = 0.0;
                             self.privacyPolicyButton.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 [self setupMovie:@"FadeOut"];
                             }
                         }];
    }
}

- (void)facebookPressed
{
    if (![self.view locationServicesEnabled]) {
        [self.navigationController pushViewController:[LocationServicesViewController new] animated:YES];
    } else
    if (![APIClient sharedClient].online) {
        [NoInternetViewController showNoInternetViewControllerInNavController:self.navigationController];
    } else {
        if (self.pageControl.currentPage == 0) {
            [self scrollViewDidEndScrollingAnimation:self.imageScrollView];
        } else {
            [self.imageScrollView scrollRectToVisible:self.view.bounds animated:YES];
            // This will then call the delegate below
        }
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         self.facebookButton.alpha = 0.0;
                         self.pageControl.alpha = 0.0;
                         self.privacyPolicyButton.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [self loginWithFailureBlock:^{
                                 [self fadeOutMovieIntoPage];
                             }];
                         }
                     }];
}

#pragma mark - Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteredForeground)
                                                 name:NOTIFICATION_ENTERED_FOREGROUND
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetStatusChanged) name:NOTIFICATION_INTERNET_STATUS_CHANGED object:nil];
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
        frame = self.facebookButton.frame;
        frame.origin.y -= 20;
        self.facebookButton.frame = frame;
        frame = self.imageScrollView.frame;
        frame.origin.y = frame.origin.y == 0 ? 0 : frame.origin.y+20;
        self.imageScrollView.frame = frame;
    } else {
        CGRect frame = self.pageControl.frame;
        frame.origin.y += 20;
        self.pageControl.frame = frame;
        frame = self.facebookButton.frame;
        frame.origin.y += 20;
        self.facebookButton.frame = frame;
        frame = self.imageScrollView.frame;
        frame.origin.y = frame.origin.y == 0 ? 0 : frame.origin.y-20;
        self.imageScrollView.frame = frame;
    }
}
#pragma mark -

- (void)internetStatusChanged
{
    if (![APIClient sharedClient].online) {
        [NoInternetViewController showNoInternetViewControllerInNavController:self.navigationController];
    }
}

- (void)enteredForeground
{
    [self internetStatusChanged];
    
    if (self.moviePlayer != nil)
        [self begin];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Screenshot

- (UIImage*)snapshotOfView
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    //There's a new arcane way to do this using 3 frameworks
    return [self.moviePlayer thumbnailImageAtTime:[self.moviePlayer duration] timeOption:MPMovieTimeOptionNearestKeyFrame];
#pragma clang diagnostic pop
}

@end
