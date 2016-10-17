//
//  WaitingRoomViewController.m
//  Wyldfire
//
//  Created by Yulian Simeonov on 2/21/14.
//  Copyright (c) 2014 YulianMobile. All rights reserved.
//

#import "WaitingRoomViewController.h"

@interface WaitingRoomViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIImageView* successImageView;
@property (nonatomic, strong) UILabel* successTopLabel;
@property (nonatomic, strong) UILabel* successBottomLabel;

@property (nonatomic, strong) SideBarProfileView* profileView;
@property (nonatomic, strong) UILabel* topLabel;
@property (nonatomic, strong) UIButton* getInviteButton;

@property (nonatomic, strong) UITextField* textField;
@property (nonatomic, strong) UIButton* redeemButton;
@property (nonatomic, strong) UIButton* dismissalButton;

@property (atomic, strong) UIActivityIndicatorView* activity;
@property (nonatomic, strong) MPMoviePlayerController* moviePlayer;

@end

@implementation WaitingRoomViewController {
    int _errors;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_errors = 0;
    self.view.backgroundColor = GRAY_1;
    
    [self addObscurants];
    [self setupProfileView];
    [self addGetInvite];
    [self addButtons];
    [self addLabel];
    [self subscribeToNotifications];
    [self loadActivityView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    Account* account = [WFCore get].accountStructure;
    if (account.hasFeather && account.isMale) {
        [self showWelcome];
    } else if (account.stats.sentInvites > 0 && !account.isMale) {
        [self showWelcome];
    }
}

- (CGRect)topButtonRect
{
    CGRect bottomRect = [self bottomButtonRect];
//    return CGRectOffset(bottomRect, 0, - (CGRectGetHeight(bottomRect) + 8));
    //Added by Yurii on 06/16/14
    return CGRectOffset(bottomRect, 0, - (CGRectGetHeight(bottomRect)));
}

- (void)addButtons
{
    CGRect bottomRect = [self bottomButtonRect];
    CGRect topRect = [self topButtonRect];
    
    BOOL isMale = [WFCore get].accountStructure.isMale;
    NSString* redeemTarget = isMale ? @"redeemFeatherCode" : @"showFriendsPicker";
    NSString* redeemTitle = isMale ? @"Redeem Feather" : @"Send an Invite";
    NSString* trendingTitle = isMale ? @"Take Me to Trending" : @"Show Me Who's Trending";

    self.redeemButton = [self addButtonWithTitle:redeemTitle
                                 backgroundColor:WYLD_RED
                                           frame:topRect
                                  selectorString:redeemTarget];

    [self addButtonWithTitle:trendingTitle
             backgroundColor:GRAY_4
                       frame:bottomRect
              selectorString:@"showTrending"];
}

- (void)addTextFieldToButton
{
    if (!self.textField) {
        CGRect frame = self.redeemButton.bounds;
        UITextField* textField = [[ShiftedTextField alloc] initWithFrame:frame];
        textField.textAlignment = NSTextAlignmentCenter;
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyDone;
        textField.keyboardType = UIKeyboardTypeDefault;
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(10, 0, 310, 45)];
        //toolbar.backgroundColor = [UIColor whiteColor];
        
        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *toolbarDone = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
        
        toolbar.items = [NSArray arrayWithObjects:spacer, toolbarDone, nil];
        
        [textField setInputAccessoryView:toolbar];
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        [self.redeemButton addSubview:textField];
        
        self.textField = textField;
    }
}

- (void)done
{
    [self checkCode:self.textField.text];
}

- (void)setupProfileView
{
    SideBarProfileView* profileView = [[SideBarProfileView alloc] initWithFrame:CGRectMake(DRAWER_WIDTH / 2, 55,
                                                                                           self.view.width,
                                                                                           SIDEBAR_PROFILE_VIEW_HEIGHT)];
    profileView.centerX = self.view.centerX + DRAWER_WIDTH / 2;
    
    Account* account = [WFCore get].accountStructure;
    if (account.age > 0) {
        profileView.profileName.text = [NSString stringWithFormat:@"%@, %i", account.name, account.age];
    } else {
        profileView.profileName.text = [NSString stringWithFormat:@"%@", account.name];
    }
    profileView.profileImage.image = [WFCore get].accountStructure.avatarPhoto;

    [self.view addSubview:profileView];
    self.profileView = profileView;
}

- (CGRect)labelRect
{
    return CGRectMake(0,
                      self.profileView.bottom,
                      self.view.width,
                      50);
}

- (CGRect)femaleLabelRect
{
    return CGRectMake(0,
                      self.profileView.profileLikes.y + 15,
                      self.view.width,
                      self.redeemButton.y - self.profileView.profileName.bottom);
}

- (void)addLabel
{
    BOOL isMale = [WFCore get].accountStructure.isMale;
    CGRect labelRect = isMale ? [self labelRect] : [self femaleLabelRect];
    
    NSString* labelText = isMale ? @"If you’ve been invited, redeem your feather below, or" : @"Women screen which men can join Wyldfire.\n\nPlease send at least one feather to enter the network.\n\nYour fellow ladies are counting on you!";
    
    UILabel* firstLabel = [UILabel labelInRect:labelRect
                                      withText:labelText
                                         color:[UIColor whiteColor]
                                      fontSize:15];
    firstLabel.textAlignment = NSTextAlignmentCenter;
    firstLabel.numberOfLines = 0;
    [self.view addSubview:firstLabel];
    self.topLabel = firstLabel;
}

- (void)addGetInvite
{
    BOOL isMale = [WFCore get].accountStructure.isMale;
    if (!isMale) return;
    
    CGRect rect = CGRectMake(0, self.profileView.bottom + 50, self.view.width, 50);
    UIButton* button = [[UIButton alloc] initWithFrame:rect];
    [button setTitle:@"Get Invite." forState:UIControlStateNormal];
    [button setTitleColor:WYLD_RED forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showFriendsPicker) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button];
    self.getInviteButton = button;
}

#pragma mark - Loading Animation

- (void)loadActivityView
{
    _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activity.hidesWhenStopped = YES;
    _activity.hidden = YES;
    _activity.layer.backgroundColor = [[UIColor colorWithWhite:0.0f alpha:0.4f] CGColor];
    _activity.frame = CGRectMake(0, 0, 64, 64);
    _activity.layer.masksToBounds = YES;
    _activity.layer.cornerRadius = 8;
}

- (void)showActivityInView:(UIView*)view
{
    if (_activity.superview) return;
    [view addSubview:_activity];
    _activity.center = view.center;
    _activity.hidden = NO;
    [_activity startAnimating];
}

- (void)hideActivity
{
    [_activity stopAnimating];
    [_activity removeFromSuperview];
}

#pragma mark - Actions

- (void)redeemFeatherCode
{
    [self addTextFieldToButton];
    [self.textField becomeFirstResponder];
    [WFCore showAlert:nil text:@"Please enter the code from\nyour text message invitation." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:1];
}

- (void)showTrending
{
    [WFCore showViewController:self name:@"Top10" mode:@"push" params:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self checkCode:textField.text];
    
    return NO;
}

- (void)showFriendsPicker
{
    [WFCore showViewController:self name:@"WaitingRoomFriends" mode:@"push" params:nil];
}

#pragma mark - Redeem Code

- (void)checkCode:(NSString*)code
{
    [self showActivityInView:self.view];
    
    [[APIClient sharedClient] checkInviteCode:code success:^{
        [self codeVerified:code];
    } failure:^(NSString *reason) {
        [self codeDenied:reason];
    }];
}

- (void)codeVerified:(NSString*)code
{
    [self hideActivity];
    self.textField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"white_check"]];
    self.textField.rightViewMode = UITextFieldViewModeAlways;
    [WFCore get].accountStructure.hasFeather = YES;
   
    [self performSelector:@selector(showWelcome) withObject:nil afterDelay:1.0];
}

- (void)codeDenied:(NSString*)reason
{
    [self hideActivity];
    self.textField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error_x"]];
    
    [WFCore showAlert:[reason capitalizedString] text:nil delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:FEATHER_INVALID_CODE_ALERT];
}

#pragma mark - Keyboard Animation

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    [UIView animateWithDuration:[self keyboardAnimationDurationForNotification:notification]
                          delay:0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect keyboardRect = [self keyboardFrame:notification];
                         CGRect rect = CGRectMake(self.redeemButton.x, keyboardRect.origin.y - self.redeemButton.height - 8, self.redeemButton.width, self.redeemButton.height);
                         
                         self.redeemButton.frame = rect;
                         self.redeemButton.titleLabel.alpha = 0.0;
                         self.getInviteButton.alpha = 0.0;
                         self.topLabel.alpha = 0.0;
                         self.textField.alpha = 1.0;
                         
                         CGRect dismissalRect = CGRectMake(0, 0, self.view.width, rect.origin.y);
                         UIButton* dismissalButton = [[UIButton alloc] initWithFrame:dismissalRect];
                         [dismissalButton addTarget:self.textField action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
                         
                         [self.view addSubview:dismissalButton];
                         self.dismissalButton = dismissalButton;
                     } completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
        [UIView animateWithDuration:[self keyboardAnimationDurationForNotification:notification]
                         animations:^{
                             self.redeemButton.frame = [self topButtonRect];
                             self.redeemButton.titleLabel.alpha = 1.0;
                             self.getInviteButton.alpha = 1.0;
                             self.topLabel.alpha = 1.0;
                             self.textField.alpha = 0.0;
                             
                             [self.dismissalButton removeFromSuperview];
                             self.dismissalButton = nil;
                         }];
}

- (CGRect)keyboardFrame:(NSNotification*)notification
{
    NSValue* value = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect rect = CGRectZero;
    [value getValue:&rect];
    return rect;
}

- (NSTimeInterval)keyboardAnimationDurationForNotification:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    NSValue* value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration = 0;
    [value getValue:&duration];
    return duration;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Welcome

- (void)showWelcome
{
    [self.textField resignFirstResponder];
    
    BOOL isMale = [WFCore get].accountStructure.isMale;
    
    if (isMale) {
        [self setupMovie];
    } else {
        UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_big"]];
        imgView.alpha = 0.0;
        
        [self.view addSubview:imgView];
        imgView.center = self.view.center;
        imgView.centerY -= 50;
        self.successImageView = imgView;
        
        
        CGRect topRect = CGRectMake(0, imgView.bottom + 8, self.view.width, 60);
        CGRect bottomRect = CGRectMake(0, topRect.size.height + topRect.origin.y,
                                       self.view.width, 18);
        
        NSString* topText = (isMale ? @"Congratulations Sir,\nYou received a feather!" : @"Welcome to Wyldfire.");
        NSString* bottomText = (isMale ? @"Someone must think very highly of you." : @"Thanks for joining the network!");
        
        UILabel* successTopLabel = [UILabel labelInRect:topRect
                                               withText:topText
                                                  color:[UIColor whiteColor]
                                               fontSize:17];
        successTopLabel.numberOfLines = 0;
        UILabel* successBottomLabel = [UILabel labelInRect:bottomRect
                                                  withText:bottomText
                                                     color:WYLD_RED
                                                  fontSize:14];
        
        successTopLabel.alpha = successBottomLabel.alpha = 0.0;
        [self.view addSubview:successTopLabel];
        [self.view addSubview:successBottomLabel];
        
        self.successBottomLabel = successBottomLabel;
        self.successTopLabel = successTopLabel;
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             for (UIView* view in self.view.subviews) {
                                 view.alpha = 0.0;
                             }
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionTransitionNone
                                                  animations:^{
                                                      successTopLabel.alpha = successBottomLabel.alpha = imgView.alpha = 1.0;
                                                  } completion:^(BOOL finished) {
                                                      [self performSelector:@selector(nextScreen) withObject:nil afterDelay:3.0];
                                                  }];
                             }
                         }];
    }
}

- (void)setupMovie
{
    NSString* filename = (TALL_SCREEN ? @"LaserCut" : @"LaserCuti4");
    
    NSURL* movieURL =[[NSBundle mainBundle] URLForResource:filename withExtension:@"mov"];
    
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
    [self.moviePlayer.view setFrame:self.view.bounds];
    self.moviePlayer.backgroundView.backgroundColor = UIColor.whiteColor;
    self.moviePlayer.controlStyle = MPMovieControlStyleNone;
    [self.moviePlayer prepareToPlay];
    
    [self.view addSubview:self.moviePlayer.view];
    
    self.moviePlayer.view.frame = CGRectOffset(self.view.bounds, -320, 0);
    
    [UIView animateWithDuration:0.4 delay:0.0 options:0
                     animations:^{
                         self.moviePlayer.view.frame = self.view.bounds;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [self.moviePlayer play];
                         }
                     }];
    
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
}

- (void)playbackFinished:(NSNotification*)notification
{
    [self nextScreen];
}

- (void)nextScreen
{
    if ([WFCore get].accountStructure.isMale) {
        [[APIClient sharedClient] addAccount:^{
                [[APIClient sharedClient] nextActionAfterLogin:self];
        } failure:^(NSInteger code) {
            [WFCore showAlert:@"Unable to create your Wyldfire account" msg:@"Please check your Internet connection or try again later." delegate:nil confirmHandler:^(UIAlertView *view, NSString *button) {
                if (++_errors > 2) exit(0);
                [self showWelcome];
            }];
        }];
    } else {
        [[WFCore get] putLocation:^{
            [[APIClient sharedClient] nextActionAfterLogin:self];
        } failure:^{
            [[APIClient sharedClient] nextActionAfterLogin:self];
        }];
    }
}

@end
