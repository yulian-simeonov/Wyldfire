//
//  BrowseViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/26/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "BrowseViewController.h"

typedef NS_ENUM(int, AnimationDirection)
{
    AnimationDirectionLeft = 0,
    AnimationDirectionRight
};


@interface BrowseViewController () <UITextViewDelegate>
    @property (strong, nonatomic) BrowseCardView* currentCard;
    @property (strong, nonatomic) BrowseCardView* underneathCurrentCard;
    @property (strong, nonatomic) BrowseCardView* lastCard;
    @property (strong, nonatomic) BrowseCardView* nextCardCached;
    @property (atomic) BOOL currentlySearching;

    //Gesture Recognizer
    @property (nonatomic, assign) BOOL interactionInProgress;

    @property (nonatomic, strong) NSMutableArray* accounts;

    @property (nonatomic) int hintCount;

    @property (nonatomic) BOOL alertShown;

    @property (nonatomic, strong) UITextView* emptyLabel;
    @property (nonatomic, strong) UIImageView* loadingView;
@end

@implementation BrowseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initialize];
    [self addMenubar:@"Browse" disabled:nil];
    [self doSearch];
    [self subscribeToNotifications];
    
    NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithString:@"There are no new users in your area.\nCheck back later or visit Trending to see who's getting noticed around you."];
    [str addAttribute:NSLinkAttributeName value:@"trending" range:[str.string rangeOfString:@"Trending"]];
    [str addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[str.string rangeOfString:@"Trending"]];

    self.emptyLabel = [self addEmptyViewWithText:str];
    self.emptyLabel.alpha = 0.0;
    self.emptyLabel.delegate = self;
    
    UIButton* btnLink = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLink setFrame:CGRectMake(170, 15, 90, 30)];
    btnLink.backgroundColor = [UIColor clearColor];
    [btnLink addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.emptyLabel addSubview:btnLink];
    
    self.hintCount = 0;
    
    [self setupLoadingView];
}

#pragma mark Button Action HyperlinkButton

- (void) onClickBtn:(id) sender {
    
    // [WFCore showAlert:@"Alert" msg:@"HyperLink Clicked" delegate:self confirmHandler:nil];
    [WFCore showViewController:self name:@"Top10" mode:@"push" params:nil];
}
/*
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange
{
    [WFCore showViewController:self name:@"Top10" mode:@"push" params:nil];
    return NO;
}
*/
- (void)setEmptyLabelAlpha:(float)alphaValue
{
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         self.emptyLabel.alpha = alphaValue;
                     } completion:nil];
}

- (void)initialize
{
    self.accounts = [NSMutableArray new];
    self.view.backgroundColor = GRAY_8;
    //self.view.multipleTouchEnabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.currentCard.userInteractionEnabled = YES;
    
    if (self.accounts.count > 0 && self.currentCard == nil) {
        [self animateInFirstCard];
    } else if (self.accounts.count == 0 && !self.currentlySearching) {
        [self doSearch];
    } else if (self.currentCard.window == nil) {
        [self restartCards];
    } else if (! CGRectEqualToRect(self.currentCard.frame, self.cardFrame)) {
        [self restartCards];
    }
    self.interactionInProgress = NO;
    //[self.currentCard cardDidAppear];
}

- (void)restartCards
{
    [self.currentCard removeFromSuperview];
    self.currentCard = nil;
    [self.underneathCurrentCard removeFromSuperview];
    self.underneathCurrentCard = nil;
    [self.accounts removeAllObjects];
    [self doSearch];
}

#pragma mark Loading Cards

- (void)setupLoadingView
{
    UIImageView* imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loading"]];
    self.loadingView = imgView;
    self.loadingView.center = self.view.center;
    self.loadingView.alpha = 0.0;
    [self.view addSubview:imgView];
}

- (void)showLoading
{
    //if (! self.currentCard && self.currentlySearching) {
        [self setLoadingViewAlpha:1.0];
    [self setEmptyLabelAlpha:0.0];
    //}
}

- (void)hideLoading
{
    [self setLoadingViewAlpha:0.0];
}

- (void)setLoadingViewAlpha:(CGFloat)alpha
{
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         self.loadingView.alpha = alpha;
                     } completion:nil];
}

- (void)doSearch
{
    [self showLoading];
    if (!self.currentlySearching && self.accounts.count == 0) {
        self.currentlySearching = YES;
        
        [[APIClient sharedClient] getNearbyAccounts:^(NSArray *accounts) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (accounts.count > 0) {
                    NSLog(@"Search complete count: %i", (int)accounts.count);
                    [self addPendingAccountsToItems:accounts];
                    if ([self.navigationController topViewController] == self) {
                        if (! self.currentCard ) {
                            [self animateInFirstCard];
                        } else if (! self.underneathCurrentCard) {
                            [self addUnderneathCard];
                        }
                    }
                } else {
                    [self hideLoading];
                    [self setEmptyLabelAlpha:1.0];
                    if (!self.alertShown) {
                        self.alertShown = YES;
                    }
                }
                
                self.currentlySearching = NO;
                
            });
        } failure:^{
            [self setEmptyLabelAlpha:1.0];
            if (!self.alertShown) {
                self.alertShown = YES;
            }
            self.currentlySearching = NO;
            [self hideLoading];
        }];
    } else {
        //[self hideLoading];
    }
}

- (void)addPendingAccountsToItems:(NSArray*)accounts
{
    NSArray* accountIDs = [self.accounts valueForKeyPath:@"@unionOfObjects.accountID"];
    
    for (int i = 0; i < accounts.count; i++) {
        Account* account = accounts[i];
        
        if (!([accountIDs containsObject:account.accountID] ||
              [self.currentCard.account.accountID isEqualToString:account.accountID] ||
              [self.underneathCurrentCard.account.accountID isEqualToString:account.accountID] ||
              [self.nextCardCached.account.accountID isEqualToString:account.accountID]))
        {
            [self.accounts addObject:account];
            accountIDs = [self.accounts valueForKeyPath:@"@unionOfObjects.accountID"];
        }
    }
}

#pragma mark Showing Cards

- (BrowseCardView *)cardForAccount:(Account*)account
{
    
    BrowseCardView* card = [BrowseCardView cardForAccount:account inBrowse:YES inTrending:NO inMatches:NO];
    card.delegate = self;
    [card maskTopRightTriangle:32.5];
    return card;
}

- (void)animateInFirstCard
{
    if (self.currentCard != nil) {
        NSLog(@"Current card is not nil");
        return;
    }
    BrowseCardView* card = [self nextCard];
    self.currentCard = card;
    
    if (card == nil) return;
    [self setEmptyLabelAlpha:0.0];
    [self animateInCardFromTop:card];
    self.lastCard = nil;
    self.underneathCurrentCard = nil;
}

- (void)addUnderneathCard
{
    BrowseCardView* card = [self nextCard];
    self.underneathCurrentCard = card;
    if (card == nil) return;
    
    [self addCard:card belowAnimatingCard:self.currentCard];
    [self hideLoading];
}

- (BrowseCardView*)nextCard
{
    BrowseCardView* card = nil;
    
    if (self.accounts.count > 0) {
        Account* firstItem = self.accounts[0];
        [self.accounts removeObjectAtIndex:0];
        
        card = [self cardForAccount:firstItem];
    } else {
        [self doSearch];
    }
    
    return card;
}

#pragma mark Actions

- (void)trendingCardTapped:(BrowseCardView *)card
{
    [WFCore showViewController:self name:@"Top10" mode:nil params:nil];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([alertView.title hasPrefix:@"No matches"]) {
        self.currentlySearching = NO;
        //[WFCore showViewController:self name:@"Profile" mode:nil params:nil];
    }
    self.alertShown = NO;
}

- (void)cardWasPassed:(BrowseCardView*)card
{
    [self cardPassActions:card delayed:NO];
}

- (void)cardWasLiked:(BrowseCardView*)card
{
    [self cardLikeActions:card delayed:NO];
}

- (void)cardLikeActions:(BrowseCardView*)card delayed:(BOOL)delayed
{
    if (![GVUserDefaults standardUserDefaults].firstSwipeRight) {
        [GVUserDefaults standardUserDefaults].firstSwipeRight = TRUE;
        [WFCore showAlert:@"Like" text:@"Swiping right means you like the person you’re viewing. Are you sure you want to do this?" delegate:self cancelButtonText:@"Cancel" otherButtonTitles :@[@"OK"] tag:SWIPE_RIGHT_BROWSE_ALERT];
    } else {
    
        if (self.interactionInProgress) return;
        
        if (card.overlay == nil) //For Hint Overlay
            [card addOverlayWithText:@"LIKE" color:WYLD_RED];
        
        [[APIClient sharedClient] likeUser:card.account success:nil failure:nil];
        
        [self checkForMutualLike:card.account];
        
        [self animateCardToRight:card delayed:delayed];
    }
}

- (void)cardPassActions:(BrowseCardView*)card delayed:(BOOL)delayed
{
    if (![GVUserDefaults standardUserDefaults].firstSwipeLeft) {
        [GVUserDefaults standardUserDefaults].firstSwipeLeft = TRUE;
        [WFCore showAlert:@"Pass" text:@"Swiping left passes on the person you’re viewing. Are you sure you want to do this?" delegate:self cancelButtonText:@"Cancel" otherButtonTitles:@[@"OK"] tag:SWIPE_LEFT_BROWSE_ALERT];
    } else {
        if (self.interactionInProgress) return;
        
        [card addOverlayWithText:@"PASS" color:[UIColor whiteColor]];
        [[APIClient sharedClient] passUser:card.account success:nil failure:nil];
        
        [self animateCardToLeft:card delayed:delayed];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == SWIPE_LEFT_BROWSE_ALERT) {
        if (buttonIndex == 1) {
            [self cardPassActions:self.currentCard delayed:YES];
        } else {
            [self.currentCard resetViewPositionAndTransformations];
        }
    } else if (alertView.tag == SWIPE_RIGHT_BROWSE_ALERT) {
        if (buttonIndex == 1) {
            [self cardLikeActions:self.currentCard delayed:YES];
        } else {
            [self.currentCard resetViewPositionAndTransformations];
        }
    }
}

- (void)cardLikeTapped:(BrowseCardView *)card
{
    [self cardLikeActions:card delayed:YES];
}

- (void)cardPassTapped:(BrowseCardView *)card
{
    [self cardPassActions:card delayed:YES];
}

- (void)checkForMutualLike:(Account*)account
{
    [[APIClient sharedClient] checkIfLikedbyUser:account
                                         success:^(BOOL connectionExists) {
                                             if (connectionExists) {
                                                 
                                                 [[APIClient sharedClient] matchUser:account success:nil failure:^{
                                                     [[APIClient sharedClient] matchUser:account success:nil failure:^{
                                                         [[APIClient sharedClient] matchUser:account success:nil failure:^ {
                                                             //TODO: If send match failed... send later?
                                                         }];
                                                     }];
                                                 }];
                                                 
                                                 DBAccount* dbAccount = [DBAccount createOrUpdateDBAccountWithAccountID:account.accountID
                                                                                                                account:account];
                                                 dbAccount.showInMatches = [NSNumber numberWithBool:YES];
                                  
                                                [dbAccount save];
                                                 
                                                 [MatchPopupNotification showMatchPopup:account
                                                                 inNavigationController:self.navigationController];

                                             }
                                         } failure:^{
                                             //failed to check if liked
                                         }];
}

- (void)cardWasHinted:(BrowseCardView *)card
{
    if (self.interactionInProgress) return;
    
    self.hintCount++;
    if (self.hintCount == 3) {
        if ([WFCore get].accountStructure.isMale)
        {
            [WFCore saveMoment:KIIP_REWARD_MOMENT_HINT_SPAM_MALE
                      onlyOnce:NO
                       topText:@"Mr. Confident"
                    bottomText:@"Used all 3 of your hints in one session" inNavC:self.navigationController];
        } else {
            [WFCore saveMoment:KIIP_REWARD_MOMENT_HINT_SPAM_FEMALE
                      onlyOnce:NO
                       topText:@"Mrs. Confident"
                    bottomText:@"Used all 3 of your hints in one session" inNavC:self.navigationController];
        }
    }
    
    [card addOverlayWithText:@"HINT!" color:WYLD_BLUE];
    [[APIClient sharedClient] hintUser:card.account success:nil failure:nil];
    [[APIClient sharedClient] likeUser:card.account success:nil failure:nil];
    [GVUserDefaults standardUserDefaults].hintsToday += 1;
    [self.underneathCurrentCard updateHintCount];
    
    [self checkForMutualLike:card.account];
    [self animateCardToRight:card delayed:YES];
}

- (void)cardRequestedPrevious
{
    if (self.interactionInProgress) return;
    
    [self rewind];
}

- (void)setCurrentCard:(BrowseCardView *)currentCard
{
    if (currentCard.account != nil)
        [[APIClient sharedClient] viewUser:currentCard.account success:nil failure:nil];
    
    self.lastCard = self.currentCard;
    self.currentCard.userInteractionEnabled = YES;
    
    _currentCard = currentCard;
}

#pragma mark Normal Animations

- (void)animateCardToRight:(BrowseCardView*)card delayed:(BOOL)delayed
{
    [self animateCard:card inDirection:AnimationDirectionRight delayed:delayed];
}

- (void)animateCardToLeft:(BrowseCardView*)card delayed:(BOOL)delayed
{
    [self animateCard:card inDirection:AnimationDirectionLeft delayed:delayed];
}

- (void)animateCard:(BrowseCardView*)card inDirection:(AnimationDirection)direction delayed:(BOOL)delayed
{
    if (!self.interactionInProgress) {
        card.userInteractionEnabled = NO;
        self.interactionInProgress = YES;
        
        if (direction == AnimationDirectionRight) {
                //Can't rewind Liked cards
            self.lastCard = nil;
            self.underneathCurrentCard.rewindButton.alpha = 0.0;
        }
        
        self.currentCard = self.underneathCurrentCard;
        
        [card.layer setShouldRasterize:YES]; //tell the layer to rasterize
        [card.layer setRasterizationScale:[UIScreen mainScreen].scale];
        card.layer.allowsEdgeAntialiasing = YES;
        card.layer.cornerRadius = 1.01;
        card.layer.edgeAntialiasingMask = kCALayerLeftEdge | kCALayerRightEdge | kCALayerBottomEdge | kCALayerTopEdge;
        card.layer.borderColor = nil;
        
        [UIView animateWithDuration:0.3 delay:(delayed ? 0.4 : 0.0) options:0
        animations:^{
            card.frame = CGRectOffset(self.currentCard.frame,
                                                  (direction == AnimationDirectionRight ? 500 : -500), 0.0);
            card.transform = CGAffineTransformMakeRotation(M_PI_4 * (direction == AnimationDirectionRight ? 1 : -1));
        } completion:^(BOOL finished) {
            if (finished) {
                [self completeCardAnimation:card];
            }
        }];
    }
}

- (void)completeCardAnimation:(BrowseCardView*)card
{
    card.transform = CGAffineTransformIdentity;
    [card.layer setShouldRasterize:NO];
    card.layer.borderColor = GRAY_7.CGColor;
    [card removeFromSuperview];
    self.interactionInProgress = NO;
    
    if (self.underneathCurrentCard.window) {
        if (self.underneathCurrentCard.window == nil) {
            [self restartCards];
        } else {
            [self.underneathCurrentCard cardDidAppear];
            [self addUnderneathCard];
        }
    } else if (self.accounts.count > 0 && !self.currentCard) {
        [self animateInFirstCard];
    } else if (self.accounts.count == 0){
        [self doSearch];
    }
}

- (void)rewind
{
    if (!self.interactionInProgress) {
        self.interactionInProgress = YES;
        
        //Rewind state of card queue
        if (self.underneathCurrentCard.account) {
            [self.accounts insertObject:self.underneathCurrentCard.account atIndex:0];
            [self.underneathCurrentCard removeFromSuperview];
            self.underneathCurrentCard = nil;
        }
        
        [self.view addSubview:self.lastCard];
        self.lastCard.rewindButton.alpha = 0.0;
        self.lastCard.layer.borderColor = GRAY_7.CGColor;
        [self.lastCard.overlay removeFromSuperview];
        self.lastCard.overlay = nil;
        
        [UIView animateWithDuration:0.4 delay:0.0 options:0
                         animations:^{
                             self.lastCard.frame = self.cardFrame;
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 self.underneathCurrentCard = self.currentCard;
                                 self.underneathCurrentCard.userInteractionEnabled = NO;
                                 self.currentCard = self.lastCard;
                                 self.currentCard.userInteractionEnabled = YES;
                                 self.currentCard.likeButton.enabled = YES;
                                 [self.view bringSubviewToFront:self.currentCard];
                                 self.interactionInProgress = NO;
                                 self.lastCard = nil;
                             }
                         }];
    }
}

- (void)addCard:(BrowseCardView*)nextCard belowAnimatingCard:(BrowseCardView*)lastCard
{
    if (lastCard == nil) {
        NSLog(@"ADDING BELOW NIL!");
    }
    
    [self.view insertSubview:nextCard belowSubview:lastCard];
}

- (CGRect)cardFrame
{
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGRect cardFrame = CARD_FRAME;
    if (statusBarHeight > 20) {
        cardFrame.size.height -= 20;
    }
    return cardFrame;
}

- (void)animateInCardFromTop:(BrowseCardView*)card
{
    self.interactionInProgress = YES;
    [self.view addSubview:card];
    CGRect originalFrame = self.cardFrame;
    card.frame = CGRectOffset(originalFrame, 0, -CGRectGetHeight(self.view.frame));
    
    [UIView animateWithDuration:0.4 delay:0.0 options:0
                     animations:^{
                         card.frame = originalFrame;
                         //Can't rewind back from initial card
                         card.rewindButton.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [card cardDidAppear];
                             self.interactionInProgress = NO;
                             
                             [self addUnderneathCard];
                             [self hideLoading];
                         }
                     }];
}

#pragma mark Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged)        name:NOTIFICATION_UPDATED_SETTINGS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(locationChanged)        name:NOTIFICATION_UPDATED_LOCATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteredForeground)      name:NOTIFICATION_ENTERED_FOREGROUND object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(internetStatusChanged)  name:NOTIFICATION_INTERNET_STATUS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessage:)            name:NOTIFICATION_NEW_MESSAGES object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMatch:)              name:NOTIFICATION_NEW_MATCHES object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newContact:)            name:NOTIFICATION_NEW_CONTACT object:nil];
}

- (void)newContact:(NSNotification*)notification
{
    NSString* senderID = notification.userInfo[@"senderID"];
    
    DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:senderID];
    Account* account = [DBAccount accountFromDBAccount:dbAccount];
    
    if (account.avatarPhoto != nil && account.alias != nil) {
        [ContactPopupNotification showContactPopup:account inNavigationController:self.navigationController];
    }
}

- (void)newMessage:(NSNotification*)notification
{
    NSString* senderID = notification.userInfo[@"senderID"];
    
    DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:senderID];
    Account* account = [DBAccount accountFromDBAccount:dbAccount];
    
    [ChatPopupNotification showChatPopup:account inNavigationController:self.navigationController];
}

- (void)newMatch:(NSNotification*)notification
{
    NSString* senderID = notification.userInfo[@"senderID"];
    
    DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:senderID];
    Account* account = [DBAccount accountFromDBAccount:dbAccount];
    
    [MatchPopupNotification showMatchPopup:account
                    inNavigationController:self.navigationController];
}

- (void)internetStatusChanged
{
    if (![APIClient sharedClient].online) {
        [NoInternetViewController showNoInternetViewControllerInNavController:self.navigationController];
    }
}

- (void)enteredForeground
{
    if (![self.view locationServicesEnabled]) {
        [self.navigationController pushViewController:[LocationServicesViewController new] animated:YES];
    }
}

- (void)settingsChanged
{
    [self restartCards];
}

- (void)locationChanged
{
    if ([self.navigationController topViewController] == self) {
        [self.accounts removeAllObjects];
        [self doSearch];
    } else {
        [self restartCards];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
